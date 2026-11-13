'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;

test('a message can carry a picture, but only its own', { skip: !enabled }, async () => {
  const { socialAction } = require('../index');
  const { getFirestore } = require('firebase-admin/firestore');
  const db = getFirestore();
  const call = (uid, action, data = {}) =>
    socialAction.run({ auth: { uid, token: { email_verified: true } }, data: { action, ...data } });
  const wait = () => new Promise(r => setTimeout(r, 800));

  const id = 'album';
  await db.doc('connections/' + id).set({
    members: ['ana', 'ben'],
    requester: 'ana',
    recipient: 'ben',
    status: 'accepted',
    names: { ana: 'Ana', ben: 'Ben' },
    lastMessageAt: new Date(0),
  });

  // Nothing at all is still nothing: a message needs words, a picture, or both.
  await assert.rejects(() => call('ana', 'message', { connectionId: id, messageId: 'p0' }));

  // The attachment has to be this very message's own object. Anything else
  // would let a message point at somebody else's picture.
  await assert.rejects(() =>
    call('ana', 'message', {
      connectionId: id,
      messageId: 'p1',
      image: `connections/${id}/somebody-else`,
    }),
  );
  await assert.rejects(() =>
    call('ana', 'message', {
      connectionId: id,
      messageId: 'p1',
      image: 'connections/otherthread/p1',
    }),
  );

  // A picture with no words is a message on its own, and the list is told
  // there is one so it can say so in the reader's own language.
  await call('ana', 'message', {
    connectionId: id,
    messageId: 'p1',
    image: `connections/${id}/p1`,
  });
  const photo = (await db.doc(`connections/${id}/messages/p1`).get()).data();
  assert.equal(photo.image, `connections/${id}/p1`);
  assert.equal(photo.text, '');
  const list = (await db.doc('connections/' + id).get()).data();
  assert.equal(list.lastMessage.image, true);
  assert.equal(list.lastMessage.text, '');

  // A caption travels with the picture and is what the list previews.
  await wait();
  await call('ben', 'message', {
    connectionId: id,
    messageId: 'p2',
    text: 'Mira el stand',
    image: `connections/${id}/p2`,
  });
  const captioned = (await db.doc('connections/' + id).get()).data();
  assert.equal(captioned.lastMessage.text, 'Mira el stand');
  assert.equal(captioned.lastMessage.image, true);

  // Withdrawing a picture takes the reference with it, so nothing is left
  // pointing at bytes the sender asked to remove.
  await call('ben', 'deleteMessage', { connectionId: id, messageId: 'p2' });
  const gone = (await db.doc(`connections/${id}/messages/p2`).get()).data();
  assert.equal(gone.deleted, true);
  assert.ok(!gone.image);
});
