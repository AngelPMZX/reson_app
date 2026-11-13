'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;

test('a message can be answered, corrected and withdrawn', { skip: !enabled }, async () => {
  const { socialAction } = require('../index');
  const { getFirestore } = require('firebase-admin/firestore');
  const db = getFirestore();
  const call = (uid, action, data = {}) =>
    socialAction.run({ auth: { uid, token: { email_verified: true } }, data: { action, ...data } });
  const wait = () => new Promise(r => setTimeout(r, 800));

  const id = 'thread';
  await db.doc('connections/' + id).set({
    members: ['ana', 'ben'],
    requester: 'ana',
    recipient: 'ben',
    status: 'accepted',
    names: { ana: 'Ana', ben: 'Ben' },
    lastMessageAt: new Date(0),
  });

  await call('ana', 'message', { connectionId: id, messageId: 'm1', text: 'Hola Ben' });
  await wait();
  await call('ben', 'message', {
    connectionId: id,
    messageId: 'm2',
    text: 'Claro',
    replyTo: 'm1',
  });

  const quoted = (await db.doc(`connections/${id}/messages/m2`).get()).data();
  // The quote is a copy, so a reply still reads even if its target goes.
  assert.equal(quoted.replyTo.id, 'm1');
  assert.equal(quoted.replyTo.sender, 'ana');
  assert.equal(quoted.replyTo.text, 'Hola Ben');

  // Only your own words.
  await assert.rejects(() =>
    call('ana', 'editMessage', { connectionId: id, messageId: 'm2', text: 'no' }),
  );
  await assert.rejects(() => call('ana', 'deleteMessage', { connectionId: id, messageId: 'm2' }));
  await assert.rejects(() =>
    call('eve', 'editMessage', { connectionId: id, messageId: 'm1', text: 'no' }),
  );

  await call('ana', 'editMessage', { connectionId: id, messageId: 'm1', text: 'Hola Benjamín' });
  const edited = (await db.doc(`connections/${id}/messages/m1`).get()).data();
  assert.equal(edited.text, 'Hola Benjamín');
  assert.ok(edited.editedAt);

  // Editing the newest message updates what the list shows.
  await call('ben', 'editMessage', { connectionId: id, messageId: 'm2', text: 'Claro que sí' });
  assert.equal((await db.doc('connections/' + id).get()).data().lastMessage.text, 'Claro que sí');

  // Deleting keeps the row, loses the words, and clears the list preview.
  await call('ben', 'deleteMessage', { connectionId: id, messageId: 'm2' });
  const gone = (await db.doc(`connections/${id}/messages/m2`).get()).data();
  assert.equal(gone.deleted, true);
  assert.equal(gone.text, '');
  assert.ok(!gone.replyTo);
  assert.ok(!(await db.doc('connections/' + id).get()).data().lastMessage);

  // What is already gone cannot be edited or deleted again.
  await assert.rejects(() =>
    call('ben', 'editMessage', { connectionId: id, messageId: 'm2', text: 'otra vez' }),
  );
  await assert.rejects(() => call('ben', 'deleteMessage', { connectionId: id, messageId: 'm2' }));

  // Answering something deleted is simply not a reply.
  await wait();
  await call('ana', 'message', {
    connectionId: id,
    messageId: 'm3',
    text: 'eco',
    replyTo: 'm2',
  });
  assert.ok(!(await db.doc(`connections/${id}/messages/m3`).get()).data().replyTo);
});
