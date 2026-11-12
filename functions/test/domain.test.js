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
  shade,
  credentialSkin,
  searchTerms,
  searchQuery,
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

test('a colour is mixed towards black and white, and garbage falls back', () => {
  assert.equal(shade('#C8102E', 0), '#c8102e');
  assert.equal(shade('#FFFFFF', -1), '#000000');
  assert.equal(shade('#000000', 1), '#ffffff');
  // An unparseable colour must not produce an unparseable CSS variable.
  for (const bad of ['', null, 'red', '#12345', 'javascript:x']) {
    assert.match(shade(bad, 0), /^#[0-9a-f]{6}$/);
  }
});

test('the public page wears the colour its owner chose', () => {
  const p = snapshot({ ...c, theme: { primaryHex: '#1E6BB8' } }, ['role', 'company']);
  p.photo = false;
  const html = render(p, 'a'.repeat(32), 'https://reson-app.web.app');
  // It used to be carmine for everybody, so every card looked like the same
  // card however the owner had designed theirs.
  assert.ok(html.includes('--accent:#1e6bb8'));
  assert.ok(!html.includes('#C2415B'));
});

test('empty fields leave no empty paragraphs under the name', () => {
  const bare = snapshot({ ...c, bio: '' }, []);
  bare.photo = false;
  const html = render(bare, 'a'.repeat(32), 'https://reson-app.web.app');
  assert.ok(!html.includes('<p></p>'));
});

test('search terms are accent free prefixes of every findable word', () => {
  const terms = searchTerms({
    name: 'María Soto',
    role: 'Diseñadora',
    company: 'Acme',
    sector: 'Tecnología',
    location: 'CDMX',
  });
  // Typing without accents has to find somebody who writes with them.
  assert.ok(terms.includes('ma'));
  assert.ok(terms.includes('maria'));
  assert.ok(terms.includes('disen'));
  assert.ok(terms.includes('tecnologia'));
  // One letter is not a search, and the array is an index: it stays bounded.
  assert.ok(!terms.includes('a'));
  assert.ok(terms.length <= 120);
  assert.ok(searchTerms({ name: 'A'.repeat(400) }).length <= 120);
});

test('a typed query becomes one server term and the rest for the device', () => {
  // Firestore allows a single array-contains, so the longest word is the one
  // worth sending and the others narrow what comes back.
  assert.deepEqual(searchQuery('María diseño'), {
    term: 'diseno',
    rest: ['maria'],
  });
  assert.deepEqual(searchQuery('  '), { term: '', rest: [] });
  assert.deepEqual(searchQuery('a'), { term: '', rest: [] });
  assert.equal(searchQuery('Z'.repeat(40)).term.length, 14);
});

test('the web credential is painted like the app credential', () => {
  // Mirrors ResonCredentials in reson_tokens.dart: the surface is the owner's
  // colour mixed towards the layout's backdrop by the layout's blend. A cyan
  // aurora card is a dark teal in both places, not a carmine panel.
  assert.equal(credentialSkin('#1BA8C4', 'aurora').surface, '#131920');
  assert.equal(credentialSkin('#1BA8C4', 'aurora').ink, '#FAF9F7');
  // Two layouts that set their own surface ignore the colour for it.
  assert.equal(credentialSkin('#1BA8C4', 'noir').surface, '#101012');
  assert.equal(credentialSkin('#1BA8C4', 'studio').surface, '#FFFCFB');
  // An unknown layout still produces a drawable card.
  assert.match(credentialSkin('#1BA8C4', 'nope').surface, /^#[0-9a-f]{6}$/);
});

test('the page shows every contact line the card shows', () => {
  const p = snapshot(
    {
      ...c,
      contact: { email: 'a@b.com', phone: 'ext 4120', website: 'https://x.com' },
      visibleFields: ['email', 'phone', 'website'],
    },
    ['email', 'phone', 'website'],
  );
  p.photo = false;
  const html = render(p, 'a'.repeat(32), 'https://reson-app.web.app');
  // A phone with no digits cannot be dialled, but the card still shows it, so
  // the page must show it too rather than silently saying less.
  assert.ok(html.includes('ext 4120'));
  assert.ok(html.includes('a@b.com'));
  assert.ok(html.includes('https://x.com'));
});
