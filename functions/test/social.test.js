'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;
test('publish → save → request → accept → chat → block → revoke', { skip: !enabled }, async () => {
  const { socialAction, getSharedCard } = require('../index');
  const { getFirestore } = require('firebase-admin/firestore');
  const db = getFirestore();
  const call = (uid, action, data = {}) =>
    socialAction.run({ auth: { uid, token: { email_verified: true } }, data: { action, ...data } });
  const seed = uid => ({
    ownerId: uid,
    label: 'Work',
    identity: { displayName: uid, jobTitle: 'Engineer', company: 'SECRET COMPANY' },
    contact: { email: 'SECRET EMAIL', phone: '', website: '' },
    theme: { primaryHex: '#C8102E' },
    visibleFields: ['role', 'company', 'email'],
    professional: {},
    schemaVersion: 1,
  });
  await db.doc('users/alice/cards/cardA').set(seed('alice'));
  await db.doc('users/bob/cards/cardB').set(seed('bob'));
  await assert.rejects(() =>
    socialAction.run({
      auth: { uid: 'alice', token: { email_verified: false } },
      data: { action: 'publish', cardId: 'cardA', fields: [] },
    }),
  );
  const a = await call('alice', 'publish', { cardId: 'cardA', fields: ['role'] });
  const b = await call('bob', 'publish', { cardId: 'cardB', fields: ['role'] });
  const pub = await getSharedCard.run({ data: { publicId: a.id } });
  assert.equal(pub.email, '');
  assert.equal(pub.company, '');
  assert.ok(!JSON.stringify(pub).includes('SECRET'));
  await assert.rejects(() => call('bob', 'publish', { cardId: 'cardA', fields: [] }));
  await call('bob', 'save', { publicId: a.id });
  const saved = (await db.doc('users/bob/received/' + a.id).get()).data();
  // The wallet draws the credential, so the whole sanitised snapshot is kept
  // and the redaction must survive the copy.
  assert.equal(saved.snapshot.name, 'alice');
  assert.equal(saved.snapshot.email, '');
  assert.ok(!JSON.stringify(saved).includes('SECRET'));
  assert.equal(saved.active, true);
  const request = await call('alice', 'request', { publicId: b.id, ownPublicId: a.id });
  assert.equal(
    (await call('alice', 'request', { publicId: b.id, ownPublicId: a.id })).id,
    request.id,
  );
  await assert.rejects(() =>
    call('alice', 'message', { connectionId: request.id, messageId: 'first', text: 'hello' }),
  );
  await assert.rejects(() =>
    call('alice', 'respond', { connectionId: request.id, decision: 'accept' }),
  );
  await call('bob', 'respond', { connectionId: request.id, decision: 'accept' });
  await call('alice', 'message', { connectionId: request.id, messageId: 'first', text: 'hello' });
  await call('alice', 'message', { connectionId: request.id, messageId: 'first', text: 'hello' });
  assert.equal((await db.collection('connections/' + request.id + '/messages').get()).size, 1);
  // The list reads the trace of the last message instead of opening the thread.
  const afterFirst = (await db.doc('connections/' + request.id).get()).data();
  assert.equal(afterFirst.lastMessage.text, 'hello');
  assert.equal(afterFirst.lastMessage.sender, 'alice');
  // Bob has not read it, so his marker is missing and the row counts as unread.
  assert.ok(!afterFirst.reads?.bob);
  await call('bob', 'markRead', { connectionId: request.id });
  const afterRead = (await db.doc('connections/' + request.id).get()).data();
  assert.ok(afterRead.reads.bob.toMillis() >= afterRead.lastMessageAt.toMillis());
  // Reading must not reorder the other member's list.
  assert.equal(afterRead.updatedAt.toMillis(), afterFirst.updatedAt.toMillis());
  await assert.rejects(() => call('eve', 'markRead', { connectionId: request.id }));
  await assert.rejects(() =>
    call('eve', 'message', { connectionId: request.id, messageId: 'evil', text: 'hello' }),
  );
  await call('bob', 'report', { connectionId: request.id, reason: 'Testing moderation' });
  await call('bob', 'block', { connectionId: request.id });
  await assert.rejects(() =>
    call('alice', 'message', { connectionId: request.id, messageId: 'second', text: 'hello' }),
  );
  await assert.rejects(() => call('alice', 'request', { publicId: b.id, ownPublicId: a.id }));
  // Only the member holding the block can lift it.
  await assert.rejects(() => call('alice', 'unblock', { connectionId: request.id }));
  await call('bob', 'unblock', { connectionId: request.id });
  assert.ok(!(await db.doc('users/bob/blocks/alice').get()).exists);
  assert.equal((await db.doc('connections/' + request.id).get()).data().status, 'declined');
  // Lifting a block reopens the pair without reopening the chat: the sender
  // still waits out the cooldown, while the recipient may accept right away.
  await assert.rejects(() => call('alice', 'request', { publicId: b.id, ownPublicId: a.id }));
  await call('bob', 'respond', { connectionId: request.id, decision: 'accept' });
  await call('alice', 'message', { connectionId: request.id, messageId: 'third', text: 'again' });
  // Bob has a device registered, so this send also tries to notify. A push
  // that cannot go out must not fail the message that earned it.
  assert.equal((await db.collection('connections/' + request.id + '/messages').get()).size, 2);
  // The connection throttles to one message per 700ms, so this waits it out
  // rather than measuring the throttle by accident.
  await new Promise(r => setTimeout(r, 800));
  await call('alice', 'message', { connectionId: request.id, messageId: 'fourth', text: 'ping' });
  assert.equal((await db.collection('connections/' + request.id + '/messages').get()).size, 3);
  // Being findable is opt in: publishing a card does not list anybody.
  assert.ok(!(await db.doc('directory/alice').get()).exists);
  await assert.rejects(() => call('alice', 'setDiscoverable', { enabled: true, publicId: b.id }));
  await call('alice', 'setDiscoverable', { enabled: true, publicId: a.id });
  const listing = (await db.doc('directory/alice').get()).data();
  assert.equal(listing.publicId, a.id);
  assert.ok(listing.terms.includes('ali'));
  // Only what was already public travels into the directory.
  assert.ok(!JSON.stringify(listing).includes('SECRET'));
  await call('alice', 'setDiscoverable', { enabled: false });
  assert.ok(!(await db.doc('directory/alice').get()).exists);
  // A listing points at a published card, so withdrawing the card withdraws it.
  await call('alice', 'setDiscoverable', { enabled: true, publicId: a.id });
  await call('alice', 'unpublish', { cardId: 'cardA' });
  assert.ok(!(await db.doc('directory/alice').get()).exists);
  await assert.rejects(() => getSharedCard.run({ data: { publicId: a.id } }));
  // A saved card is a copy, so it ages. Refreshing a withdrawn one records
  // that it is gone instead of failing, and the wallet keeps showing it.
  const gone = await call('bob', 'refreshSaved', { publicId: a.id });
  assert.equal(gone.active, false);
  const stale = (await db.doc('users/bob/received/' + a.id).get()).data();
  assert.equal(stale.active, false);
  assert.equal(stale.snapshot.name, 'alice');
  await assert.rejects(() => call('bob', 'refreshSaved', { publicId: b.id }));
});
