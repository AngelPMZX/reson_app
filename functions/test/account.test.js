'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;

test('an account can be taken with it everything it owns', { skip: !enabled }, async () => {
  const { socialAction, deleteAccount, exportAccount } = require('../index');
  const { getFirestore } = require('firebase-admin/firestore');
  const db = getFirestore();
  const call = (uid, action, data = {}) =>
    socialAction.run({ auth: { uid, token: { email_verified: true } }, data: { action, ...data } });
  const seed = uid => ({
    ownerId: uid,
    label: 'Work',
    identity: { displayName: uid, jobTitle: 'Engineer', company: 'Acme' },
    contact: { email: uid + '@example.com', phone: '', website: '' },
    theme: { primaryHex: '#C8102E' },
    visibleFields: ['role'],
    professional: {},
    schemaVersion: 1,
  });

  const { getAuth } = require('firebase-admin/auth');
  await getAuth().createUser({ uid: 'zoe', email: 'zoe@example.com' });

  await db.doc('users/zoe/cards/cardZ').set(seed('zoe'));
  await db.doc('users/max/cards/cardM').set(seed('max'));
  await db.doc('users/zoe/settings/identity').set({ name: 'Zoe' });
  const z = await call('zoe', 'publish', { cardId: 'cardZ', fields: ['role'] });
  const m = await call('max', 'publish', { cardId: 'cardM', fields: ['role'] });
  await call('zoe', 'save', { publicId: m.id });
  await call('zoe', 'setDiscoverable', { enabled: true, publicId: z.id });
  const conn = await call('zoe', 'request', { publicId: m.id, ownPublicId: z.id });
  await call('max', 'respond', { connectionId: conn.id, decision: 'accept' });
  await call('zoe', 'message', { connectionId: conn.id, messageId: 'hi', text: 'hola' });
  await call('max', 'block', { connectionId: conn.id });

  // An export hands back the same things a deletion would take away.
  const dump = await exportAccount.run({
    auth: { uid: 'zoe', token: { email_verified: true, email: 'zoe@example.com' } },
    data: {},
  });
  assert.equal(dump.cards.length, 1);
  assert.equal(dump.savedCards.length, 1);
  assert.equal(dump.conversations.length, 1);
  assert.equal(dump.conversations[0].messages[0].text, 'hola');

  // Deleting is meant, not stumbled into.
  await assert.rejects(() =>
    deleteAccount.run({ auth: { uid: 'zoe', token: { email_verified: true } }, data: {} }),
  );

  await deleteAccount.run({
    auth: { uid: 'zoe', token: { email_verified: true } },
    data: { confirm: 'DELETE' },
  });

  // Nothing of zoe's survives, anywhere it was written.
  for (const path of [
    'users/zoe',
    'users/zoe/cards/cardZ',
    'users/zoe/settings/identity',
    'users/zoe/publications/cardZ',
    'users/zoe/received/' + m.id,
    'publicCards/' + z.id,
    'directory/zoe',
    'socialLimits/zoe',
    'connections/' + conn.id,
    // The other member's block referred to an account that is gone.
    'users/max/blocks/zoe',
  ]) {
    assert.ok(!(await db.doc(path).get()).exists, path + ' survived');
  }
  assert.equal((await db.collection('connections/' + conn.id + '/messages').get()).size, 0);
  // Max keeps everything of his own.
  assert.ok((await db.doc('users/max/cards/cardM').get()).exists);
  assert.ok((await db.doc('publicCards/' + m.id).get()).exists);
  // The sign-in is gone too, and asking again is not an error.
  await assert.rejects(() => getAuth().getUser('zoe'));
  await deleteAccount.run({
    auth: { uid: 'zoe', token: { email_verified: true } },
    data: { confirm: 'DELETE' },
  });
});
