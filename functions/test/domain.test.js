'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  snapshot,
  vcard,
  connectionId,
  requestOutcome,
  respondOutcome,
  preview,
} = require('../domain');
const render = require('../render');
const c = {
  label: 'Work',
  identity: { displayName: 'Alex', jobTitle: 'Engineer', company: 'Private Inc' },
  contact: { email: 'private@example.com', phone: '555', website: 'javascript:alert(1)' },
  theme: { primaryHex: '#C8102E' },
  photoPath: 'users/secret/photo',
  professional: { skills: 'Private skill', projects: [{ title: 'Secret' }] },
  visibleFields: ['role', 'email', 'website', 'projects'],
};
test('publication is an allowlisted copy and never includes hidden data', () => {
  const p = snapshot(c, ['role', 'company', 'website']);
  assert.equal(p.role, 'Engineer');
  assert.equal(p.company, '');
  assert.equal(p.website, '');
  assert.equal(p.email, '');
  assert.deepEqual(p.professional.projects, []);
  assert.ok(!JSON.stringify(p).includes('secret'));
  assert.ok(!JSON.stringify(p).includes('Private'));
});
test('public HTML escapes content and does not inject arbitrary attributes', () => {
  const p = snapshot(c, ['role']);
  p.name = '<script>alert(1)</script>';
  p.photo = false;
  const html = render(p, 'a'.repeat(32), 'https://reson-app.web.app');
  assert.ok(!html.includes('<script>'));
  assert.ok(html.includes('&lt;script&gt;'));
  assert.ok(!html.includes('private@example.com'));
});
test('vCard escapes newlines and folds multibyte content', () => {
  const vc = vcard(
    { name: 'Á'.repeat(100), bio: 'x\nTEL:evil', email: 'test@example.com' },
    'https://example.com',
  );
  assert.ok(!vc.includes('\r\nTEL:evil'));
  assert.ok(vc.includes('x\\nTEL:evil'));
  assert.ok(vc.split('\r\n').every(l => Buffer.byteLength(l) <= 75));
});
test('connection identifiers are stable and order independent', () => {
  assert.equal(connectionId('a', 'b'), connectionId('b', 'a'));
  assert.notEqual(connectionId('ab', 'c'), connectionId('a', 'bc'));
});

const WEEK = 7 * 24 * 60 * 60 * 1000;

test('a first request creates the connection', () => {
  assert.equal(requestOutcome(null, 1000, WEEK), 'create');
});

test('an open connection is returned instead of duplicated', () => {
  assert.equal(requestOutcome({ status: 'pending' }, 1000, WEEK), 'keep');
  assert.equal(requestOutcome({ status: 'accepted' }, 1000, WEEK), 'keep');
});

test('a block stays shut to new requests', () => {
  assert.equal(requestOutcome({ status: 'blocked' }, 1e12, WEEK), 'blocked');
  assert.equal(requestOutcome({ status: 'blocked', respondedAt: 0 }, 1e12, WEEK), 'blocked');
});

test('a decline is not permanent but costs the sender a wait', () => {
  const declined = { status: 'declined', respondedAt: 1000 };
  assert.equal(requestOutcome(declined, 1000, WEEK), 'wait');
  assert.equal(requestOutcome(declined, 1000 + WEEK - 1, WEEK), 'wait');
  assert.equal(requestOutcome(declined, 1000 + WEEK, WEEK), 'revive');
});

test('a decline recorded before respondedAt existed can be retried', () => {
  // Connections declined by the previous build carry no respondedAt at all.
  assert.equal(requestOutcome({ status: 'declined' }, WEEK + 1, WEEK), 'revive');
});

test('only the recipient answers a request', () => {
  const pending = { status: 'pending', recipient: 'bob' };
  assert.equal(respondOutcome(pending, 'alice', 'accept'), 'forbidden');
  assert.equal(respondOutcome(null, 'bob', 'accept'), 'forbidden');
  assert.equal(respondOutcome(pending, 'bob', 'accept'), 'accept');
  assert.equal(respondOutcome(pending, 'bob', 'decline'), 'decline');
  assert.equal(respondOutcome(pending, 'bob', 'whatever'), 'invalid');
});

test('the recipient can undo a decline by accepting it', () => {
  const declined = { status: 'declined', recipient: 'bob' };
  assert.equal(respondOutcome(declined, 'bob', 'accept'), 'accept');
  assert.equal(respondOutcome(declined, 'bob', 'decline'), 'answered');
  assert.equal(respondOutcome(declined, 'alice', 'accept'), 'forbidden');
});

test('accepting twice is idempotent and a block is never answered away', () => {
  assert.equal(respondOutcome({ status: 'accepted', recipient: 'bob' }, 'bob', 'accept'), 'noop');
  assert.equal(
    respondOutcome({ status: 'accepted', recipient: 'bob' }, 'bob', 'decline'),
    'answered',
  );
  assert.equal(
    respondOutcome({ status: 'blocked', recipient: 'bob' }, 'bob', 'accept'),
    'answered',
  );
});

test('a message preview is one short line', () => {
  assert.equal(preview('Hola María'), 'Hola María');
  assert.equal(preview('  Hola \n\n  María  '), 'Hola María');
  assert.equal(preview(''), '');
  assert.equal(preview(null), '');
});

test('a long message is cut, never stretched across the row', () => {
  const long = 'a'.repeat(300);
  const cut = preview(long);
  assert.equal(cut.length, 120);
  assert.ok(cut.endsWith('…'));
  assert.equal(preview('b'.repeat(120)).length, 120);
  assert.ok(!preview('b'.repeat(120)).endsWith('…'));
});
