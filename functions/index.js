'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { randomBytes, createHash } = require('node:crypto');
const {
  snapshot,
  connectionId,
  vcard,
  requestOutcome,
  respondOutcome,
  preview,
  searchTerms,
} = require('./domain');
const render = require('./render');
initializeApp({ storageBucket: 'reson-app.firebasestorage.app' });
const db = getFirestore(),
  bucket = getStorage().bucket(),
  now = () => FieldValue.serverTimestamp();
const origin = 'https://reson-app.web.app';
const options = { region: 'us-central1', maxInstances: 3, memory: '256MiB', timeoutSeconds: 30 };
// A declined request may be sent again once this much time has passed, so a
// refusal is not permanent while repeated asking still costs the sender a wait.
// Someone who declined by mistake does not wait: they can accept it directly.
const RECONNECT_AFTER_MS = 7 * 24 * 60 * 60 * 1000;
const fail = (code, message) => {
  throw new HttpsError(code, message);
};
function id(v) {
  if (typeof v !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(v))
    fail('invalid-argument', 'Invalid identifier');
  return v;
}
function verified(req) {
  if (!req.auth || req.auth.token.email_verified !== true)
    fail('unauthenticated', 'Verify your email first');
  return req.auth.uid;
}
async function rate(uid) {
  const ref = db.doc('socialLimits/' + uid);
  await db.runTransaction(async t => {
    const d = (await t.get(ref)).data();
    const fresh = !d || Date.now() - d.start.toMillis() > 60000;
    const count = fresh ? 1 : d.count + 1;
    if (count > 40) fail('resource-exhausted', 'Please wait a minute');
    t.set(ref, { start: fresh ? Timestamp.now() : d.start, count });
  });
}
function exposed(d) {
  return {
    ...d.snapshot,
    id: d.id,
    photoUrl: d.snapshot.photo ? origin + '/c/' + d.id + '/photo' : '',
  };
}
async function published(publicId) {
  const d = (await db.doc('publicCards/' + id(publicId)).get()).data();
  if (!d?.active) fail('not-found', 'This card is not available');
  return d;
}
async function publish(uid, data) {
  const cardId = id(data.cardId),
    source = db.doc(`users/${uid}/cards/${cardId}`),
    mapping = db.doc(`users/${uid}/publications/${cardId}`);
  if (
    !Array.isArray(data.fields) ||
    data.fields.length > 17 ||
    data.fields.some(f => typeof f !== 'string')
  )
    fail('invalid-argument', 'Select fields');
  const card = (await source.get()).data();
  if (!card || card.ownerId !== uid) fail('not-found', 'Card not found');
  const reservation = await db.runTransaction(async t => {
    const old = (await t.get(mapping)).data();
    const value = {
      id: old?.id ?? randomBytes(16).toString('hex'),
      revision: (old?.revision ?? 0) + 1,
    };
    t.set(mapping, { ...value, label: card.label, active: old?.active ?? false, updatedAt: now() });
    return value;
  });
  const p = snapshot(card, data.fields);
  p.whatsapp = data.whatsapp === true && !!p.phone;
  p.photo = false;
  let photoPath = '';
  if (p.visibleFields.includes('photo') && card.photoPath) {
    if (
      !card.photoPath.startsWith(`users/${uid}/profile/`) &&
      !card.photoPath.startsWith(`users/${uid}/cards/`)
    )
      fail('permission-denied', 'Invalid photo');
    photoPath = `sharedPhotos/${reservation.id}/${reservation.revision}`;
    try {
      await bucket.file(card.photoPath).copy(bucket.file(photoPath));
      await bucket.file(photoPath).setMetadata({
        metadata: { firebaseStorageDownloadTokens: null },
        cacheControl: 'private, no-store',
      });
      p.photo = true;
    } catch {
      await bucket
        .file(photoPath)
        .delete({ ignoreNotFound: true })
        .catch(() => {});
      fail('unavailable', 'Photo could not be published');
    }
  }
  const target = db.doc('publicCards/' + reservation.id);
  let oldPhoto = '';
  try {
    await db.runTransaction(async t => {
      const current = (await t.get(mapping)).data();
      const old = (await t.get(target)).data();
      if (current.revision !== reservation.revision) fail('aborted', 'Publication changed; retry');
      oldPhoto = old?.photoPath ?? '';
      t.set(target, {
        id: reservation.id,
        ownerId: uid,
        cardId,
        active: true,
        snapshot: p,
        photoPath,
        updatedAt: now(),
      });
      t.update(mapping, { active: true, updatedAt: now() });
    });
  } catch (e) {
    if (photoPath)
      await bucket
        .file(photoPath)
        .delete({ ignoreNotFound: true })
        .catch(() => {});
    throw e;
  }
  if (oldPhoto && oldPhoto !== photoPath)
    await bucket
      .file(oldPhoto)
      .delete({ ignoreNotFound: true })
      .catch(() => {});
  return { id: reservation.id, url: origin + '/c/' + reservation.id };
}
/// What a push says, in the reader's language.
///
/// The device registers the language it is showing, because a notification is
/// built on the server where there is no UI to ask.
const pushCopy = {
  es: {
    message: name => ({ title: name, body: 'Te escribió un mensaje.' }),
    request: name => ({ title: name, body: 'Quiere conectar contigo.' }),
    accepted: name => ({ title: name, body: 'Aceptó tu solicitud. Ya pueden conversar.' }),
  },
  en: {
    message: name => ({ title: name, body: 'Sent you a message.' }),
    request: name => ({ title: name, body: 'Wants to connect with you.' }),
    accepted: name => ({ title: name, body: 'Accepted your request. You can talk now.' }),
  },
};

/// Sends a push to every device of [uid], and forgets the ones that are gone.
///
/// Never throws: a notification that does not arrive must not fail the action
/// that earned it. Sending a message is the point; telling about it is not.
async function notify(uid, kind, name, data = {}) {
  try {
    const devices = await db.collection(`users/${uid}/devices`).get();
    if (devices.empty) return;
    const byLanguage = new Map();
    for (const d of devices.docs) {
      const language = pushCopy[d.data().language] ? d.data().language : 'es';
      if (!byLanguage.has(language)) byLanguage.set(language, []);
      byLanguage.get(language).push(d);
    }
    for (const [language, group] of byLanguage) {
      const copy = pushCopy[language][kind](name);
      const result = await getMessaging().sendEachForMulticast({
        tokens: group.map(d => d.data().token),
        notification: copy,
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        android: { priority: 'high', notification: { tag: kind } },
      });
      await Promise.all(
        result.responses.map((r, i) => {
          const code = r.error?.code ?? '';
          // A token dies when the app is uninstalled or its data cleared.
          // Keeping it means paying to send into the void forever.
          const dead =
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/invalid-argument';
          return dead ? group[i].ref.delete() : Promise.resolve();
        }),
      );
    }
  } catch {
    /* A push is best effort; the action it follows has already happened. */
  }
}

async function social(uid, data) {
  const action = data.action;
  if (action === 'publish') return publish(uid, data);
  if (action === 'unpublish') {
    const ref = db.doc(`users/${uid}/publications/${id(data.cardId)}`);
    let photo = '';
    let publicId = '';
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      if (!d) return;
      publicId = d.id;
      const pub = db.doc('publicCards/' + d.id);
      const old = (await t.get(pub)).data();
      photo = old?.photoPath ?? '';
      t.update(ref, { active: false, revision: d.revision + 1, updatedAt: now() });
      t.set(pub, { active: false }, { merge: true });
    });
    if (photo)
      await bucket
        .file(photo)
        .delete({ ignoreNotFound: true })
        .catch(() => {});
    // A directory entry points at a published card, so taking the card down
    // must take the listing with it rather than leaving a dead result.
    const listing = db.doc('directory/' + uid);
    const listed = (await listing.get()).data();
    if (listed && listed.publicId === publicId) await listing.delete();
    return { ok: true };
  }
  if (action === 'save') {
    const p = await published(data.publicId);
    // The whole sanitised snapshot is kept, not just a name and a label: the
    // wallet draws real credentials, and reading them back one callable at a
    // time would mean a network round trip per card on every open.
    await db.doc(`users/${uid}/received/${p.id}`).set({
      publicId: p.id,
      name: p.snapshot.name,
      label: p.snapshot.label,
      snapshot: p.snapshot,
      active: true,
      savedAt: now(),
      updatedAt: now(),
    });
    return { ok: true };
  }
  if (action === 'refreshSaved') {
    // A saved card is a copy, so it ages. This pulls the current one, and
    // records that it is gone rather than failing when it was taken down.
    const ref = db.doc(`users/${uid}/received/${id(data.publicId)}`);
    if (!(await ref.get()).exists) fail('not-found', 'This card is not saved');
    const d = (await db.doc('publicCards/' + id(data.publicId)).get()).data();
    if (!d?.active) {
      await ref.set({ active: false, updatedAt: now() }, { merge: true });
      return { ok: true, active: false };
    }
    await ref.set(
      {
        name: d.snapshot.name,
        label: d.snapshot.label,
        snapshot: d.snapshot,
        active: true,
        updatedAt: now(),
      },
      { merge: true },
    );
    return { ok: true, active: true };
  }
  if (action === 'setDiscoverable') {
    // Opt in only. Nobody is listed because they published a card; being
    // findable is a separate thing you ask for, and withdrawing removes the
    // entry rather than hiding it behind a flag.
    const entry = db.doc('directory/' + uid);
    if (data.enabled !== true) {
      await entry.delete();
      return { ok: true, listed: false };
    }
    const publicId = id(data.publicId);
    const mine = (await db.doc('publicCards/' + publicId).get()).data();
    if (!mine?.active || mine.ownerId !== uid)
      fail('failed-precondition', 'Publish that card first');
    const p = mine.snapshot;
    // Only what the owner already made public travels into the directory.
    await entry.set({
      uid,
      publicId,
      name: p.name,
      role: p.role ?? '',
      company: p.company ?? '',
      sector: p.professional?.sector ?? '',
      location: p.professional?.location ?? '',
      photo: p.photo === true,
      terms: searchTerms({
        name: p.name,
        role: p.role,
        company: p.company,
        sector: p.professional?.sector,
        location: p.professional?.location,
      }),
      updatedAt: now(),
    });
    return { ok: true, listed: true };
  }
  if (action === 'removeSaved') {
    await db.doc(`users/${uid}/received/${id(data.publicId)}`).delete();
    return { ok: true };
  }
  if (action === 'request') {
    const targetId = id(data.publicId),
      ownId = id(data.ownPublicId);
    let result;
    let invited = '';
    let asker = '';
    await db.runTransaction(async t => {
      const target = (await t.get(db.doc('publicCards/' + targetId))).data(),
        own = (await t.get(db.doc('publicCards/' + ownId))).data();
      if (!target?.active || !own?.active || own.ownerId !== uid)
        fail('failed-precondition', 'Publish your card first');
      const other = target.ownerId;
      if (other === uid) fail('invalid-argument', 'You cannot connect to yourself');
      const key = connectionId(uid, other),
        ref = db.doc('connections/' + key);
      const [a, b, current] = await Promise.all([
        t.get(db.doc(`users/${uid}/blocks/${other}`)),
        t.get(db.doc(`users/${other}/blocks/${uid}`)),
        t.get(ref),
      ]);
      if (a.exists || b.exists) fail('permission-denied', 'Connection unavailable');
      const existing = current.exists ? current.data() : null;
      const outcome = requestOutcome(
        existing && {
          status: existing.status,
          respondedAt: existing.respondedAt ? existing.respondedAt.toMillis() : 0,
        },
        Date.now(),
        RECONNECT_AFTER_MS,
      );
      if (outcome === 'blocked') fail('permission-denied', 'Connection unavailable');
      if (outcome === 'wait') fail('resource-exhausted', 'You can ask this person again later');
      if (outcome === 'keep') {
        result = { id: key, status: existing.status };
        return;
      }
      // A revived connection keeps its history: the message thread, the first
      // contact date and the message throttle all survive a declined round.
      t.set(ref, {
        members: [uid, other],
        requester: uid,
        recipient: other,
        status: 'pending',
        cards: { [uid]: ownId, [other]: targetId },
        names: { [uid]: own.snapshot.name, [other]: target.snapshot.name },
        createdAt: existing?.createdAt ?? now(),
        updatedAt: now(),
        lastMessageAt: existing?.lastMessageAt ?? Timestamp.fromMillis(0),
      });
      result = { id: key, status: 'pending' };
      invited = other;
      asker = own.snapshot.name;
    });
    if (invited) await notify(invited, 'request', asker, { connectionId: result.id });
    return result;
  }
  if (action === 'respond') {
    const ref = db.doc('connections/' + id(data.connectionId));
    if (!['accept', 'decline'].includes(data.decision))
      fail('invalid-argument', 'Invalid decision');
    let requester = '';
    let accepter = '';
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      const outcome = respondOutcome(d, uid, data.decision);
      if (outcome === 'forbidden') fail('permission-denied', 'Recipient only');
      if (outcome === 'invalid') fail('invalid-argument', 'Invalid decision');
      if (outcome === 'answered') fail('failed-precondition', 'Request already answered');
      if (outcome === 'noop') return;
      const accept = outcome === 'accept';
      const other = d.requester;
      const [a, b] = await Promise.all([
        t.get(db.doc(`users/${uid}/blocks/${other}`)),
        t.get(db.doc(`users/${other}/blocks/${uid}`)),
      ]);
      if (a.exists || b.exists) fail('permission-denied', 'Connection unavailable');
      t.update(ref, {
        status: accept ? 'accepted' : 'declined',
        respondedAt: now(),
        updatedAt: now(),
      });
      // Only an acceptance is news worth a notification. A refusal is told
      // by silence, which is kinder than a push saying no.
      if (accept) {
        requester = other;
        accepter = d.names?.[uid] ?? '';
      }
    });
    if (requester) {
      await notify(requester, 'accepted', accepter, {
        connectionId: id(data.connectionId),
      });
    }
    return { ok: true };
  }
  if (action === 'message') {
    const text = typeof data.text === 'string' ? data.text.trim() : '';
    if (!text || text.length > 2000) fail('invalid-argument', 'Message must be 1–2000 characters');
    const ref = db.doc('connections/' + id(data.connectionId)),
      message = ref.collection('messages').doc(id(data.messageId));
    let recipient = '';
    let sender = '';
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      if (!d || !d.members.includes(uid) || d.status !== 'accepted')
        fail('permission-denied', 'Accepted connection required');
      const other = d.members.find(m => m !== uid);
      const [a, b, existing] = await Promise.all([
        t.get(db.doc(`users/${uid}/blocks/${other}`)),
        t.get(db.doc(`users/${other}/blocks/${uid}`)),
        t.get(message),
      ]);
      if (a.exists || b.exists) fail('permission-denied', 'Connection unavailable');
      if (existing.exists) {
        if (existing.data().sender !== uid || existing.data().text !== text)
          fail('already-exists', 'Message ID conflict');
        return;
      }
      if (Date.now() - d.lastMessageAt.toMillis() < 700) fail('resource-exhausted', 'Please wait');
      t.create(message, { sender: uid, text, createdAt: now() });
      // The network list reads this instead of opening every conversation to
      // find out whether anything was said. Without it a thread with fifty
      // messages looks exactly like an empty one.
      t.update(ref, {
        lastMessageAt: now(),
        updatedAt: now(),
        lastMessage: { text: preview(text), sender: uid },
      });
      recipient = other;
      sender = d.names?.[uid] ?? '';
    });
    // Outside the transaction: a push is not part of the write, and a slow
    // network must not hold a Firestore lock open.
    if (recipient) {
      await notify(recipient, 'message', sender, { connectionId: ref.id });
    }
    return { ok: true };
  }
  if (action === 'registerDevice') {
    // The client cannot write here: devices are addresses, and an address
    // written by anyone is a way to send somebody else's notifications.
    const token = String(data.token ?? '');
    if (!token || token.length > 4096) fail('invalid-argument', 'Invalid token');
    const language = data.language === 'en' ? 'en' : 'es';
    await db
      .doc(`users/${uid}/devices/${createHash('sha256').update(token).digest('hex')}`)
      .set({ token, language, platform: String(data.platform ?? ''), updatedAt: now() });
    return { ok: true };
  }
  if (action === 'markRead') {
    const ref = db.doc('connections/' + id(data.connectionId));
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      if (!d?.members.includes(uid)) fail('permission-denied', 'Not a member');
      // Only the reader's own marker moves, and `updatedAt` stays put so
      // reading a thread does not reorder somebody else's list.
      t.update(ref, { [`reads.${uid}`]: now() });
    });
    return { ok: true };
  }
  if (action === 'block') {
    const ref = db.doc('connections/' + id(data.connectionId));
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      if (!d?.members.includes(uid)) fail('permission-denied', 'Not a member');
      const other = d.members.find(m => m !== uid);
      t.set(db.doc(`users/${uid}/blocks/${other}`), { createdAt: now() });
      t.update(ref, { status: 'blocked', respondedAt: now(), updatedAt: now() });
    });
    return { ok: true };
  }
  if (action === 'unblock') {
    const ref = db.doc('connections/' + id(data.connectionId));
    await db.runTransaction(async t => {
      const d = (await t.get(ref)).data();
      if (!d?.members.includes(uid)) fail('permission-denied', 'Not a member');
      const other = d.members.find(m => m !== uid);
      const mine = db.doc(`users/${uid}/blocks/${other}`);
      // Holding the block is what authorises lifting it, so nobody can clear a
      // block placed against them. The connection never records who blocked.
      const [held, theirs] = await Promise.all([
        t.get(mine),
        t.get(db.doc(`users/${other}/blocks/${uid}`)),
      ]);
      if (!held.exists) fail('failed-precondition', 'You have not blocked this person');
      t.delete(mine);
      // While the other side still blocks, the pair stays shut for both.
      if (theirs.exists) t.update(ref, { updatedAt: now() });
      else t.update(ref, { status: 'declined', respondedAt: now(), updatedAt: now() });
    });
    return { ok: true };
  }
  if (action === 'report') {
    const ref = db.doc('connections/' + id(data.connectionId)),
      d = (await ref.get()).data();
    if (!d?.members.includes(uid)) fail('permission-denied', 'Not a member');
    const reason = String(data.reason ?? '').trim();
    if (!reason || reason.length > 500) fail('invalid-argument', 'Reason required');
    await db
      .doc(`reports/${ref.id}_${uid}`)
      .set({ reporter: uid, connectionId: ref.id, reason, createdAt: now() });
    return { ok: true };
  }
  fail('invalid-argument', 'Unknown action');
}
exports.socialAction = onCall(options, async req => {
  const uid = verified(req);
  await rate(uid);
  return social(uid, req.data ?? {});
});
exports.sharedCard = onRequest({ ...options, invoker: 'public' }, async (req, res) => {
  res.set('Cache-Control', 'private, no-store');
  res.set('X-Content-Type-Options', 'nosniff');
  res.set('Referrer-Policy', 'no-referrer');
  res.set(
    'Content-Security-Policy',
    "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'",
  );
  if (!['GET', 'HEAD'].includes(req.method)) {
    res.status(405).end();
    return;
  }
  const match = req.path.match(/^\/c\/([a-f0-9]{32})(?:\/(photo|contact\.vcf))?\/?$/);
  if (!match) {
    res.status(404).send('Tarjeta no disponible · Card unavailable');
    return;
  }
  try {
    const p = await published(match[1]);
    if (match[2] === 'photo') {
      if (!p.photoPath || !p.snapshot.photo) {
        res.status(404).end();
        return;
      }
      const file = bucket.file(p.photoPath);
      const [meta] = await file.getMetadata();
      res.type(meta.contentType ?? 'image/jpeg');
      file
        .createReadStream()
        .on('error', () => res.end())
        .pipe(res);
      return;
    }
    if (match[2] === 'contact.vcf') {
      res.set('Content-Disposition', 'attachment; filename="reson.vcf"');
      res.type('text/vcard; charset=utf-8').send(vcard(p.snapshot, origin + '/c/' + p.id));
      return;
    }
    res.type('html').send(render(p.snapshot, p.id, origin, req.query.lang === 'en'));
  } catch {
    res
      .status(404)
      .type('html')
      .send(
        '<meta name="viewport" content="width=device-width"><p>Esta tarjeta no está disponible. · This card is unavailable.</p>',
      );
  }
});
// Public lookup is deliberately independent of private profile documents.
exports.getSharedCard = onCall(options, async req => exposed(await published(req.data?.publicId)));

/// Deletes every document of a query, a page at a time.
async function purge(query) {
  for (;;) {
    const page = await query.limit(300).get();
    if (page.empty) return;
    const batch = db.batch();
    for (const d of page.docs) batch.delete(d.ref);
    await batch.commit();
    if (page.size < 300) return;
  }
}

/// Everything one account owns, so it can be handed over or taken away.
///
/// Gathered in one place because an export and a deletion must agree on what
/// "your data" is: anything listed here is both downloadable and removable.
async function ownedBy(uid) {
  const user = db.doc('users/' + uid);
  const [cards, identity, publications, received, blocks, connections] = await Promise.all([
    user.collection('cards').get(),
    user.collection('settings').get(),
    user.collection('publications').get(),
    user.collection('received').get(),
    user.collection('blocks').get(),
    db.collection('connections').where('members', 'array-contains', uid).get(),
  ]);
  return { user, cards, identity, publications, received, blocks, connections };
}

exports.exportAccount = onCall({ ...options, timeoutSeconds: 120 }, async req => {
  const uid = verified(req);
  const owned = await ownedBy(uid);
  const strip = d => ({ id: d.id, ...d.data() });
  // Conversations are shared, so an export carries what was said to you and
  // by you, which is the part that is yours to keep.
  const conversations = [];
  for (const c of owned.connections.docs) {
    const messages = await c.ref.collection('messages').orderBy('createdAt').limit(2000).get();
    conversations.push({ ...strip(c), messages: messages.docs.map(strip) });
  }
  return {
    exportedAt: new Date().toISOString(),
    account: { uid, email: req.auth.token.email ?? '' },
    profile: owned.identity.docs.map(strip),
    cards: owned.cards.docs.map(strip),
    publications: owned.publications.docs.map(strip),
    savedCards: owned.received.docs.map(strip),
    blocked: owned.blocks.docs.map(d => d.id),
    conversations,
  };
});

exports.deleteAccount = onCall({ ...options, timeoutSeconds: 540 }, async req => {
  const uid = verified(req);
  // A destructive action asks to be meant. The client sends the word back.
  if (req.data?.confirm !== 'DELETE') fail('failed-precondition', 'Confirmation required');
  const owned = await ownedBy(uid);

  // 1. Published cards stop existing for anyone holding their link, and the
  //    public copies of their photos go with them.
  for (const pub of owned.publications.docs) {
    const publicId = pub.data().id;
    if (!publicId) continue;
    const target = db.doc('publicCards/' + publicId);
    const photo = (await target.get()).data()?.photoPath;
    if (photo)
      await bucket
        .file(photo)
        .delete({ ignoreNotFound: true })
        .catch(() => {});
    await target.delete();
  }

  // 2. Conversations are deleted with their messages: a thread with an
  //    account that no longer exists is not a thread. The other member's
  //    block against this account goes too, since it can never apply again.
  for (const c of owned.connections.docs) {
    await purge(c.ref.collection('messages'));
    const other = (c.data().members ?? []).find(m => m !== uid);
    if (other) await db.doc(`users/${other}/blocks/${uid}`).delete();
    await c.ref.delete();
  }

  // 3. Everything filed under the account itself.
  for (const name of ['cards', 'settings', 'publications', 'received', 'blocks', 'devices'])
    await purge(owned.user.collection(name));
  await Promise.all([
    db.doc('directory/' + uid).delete(),
    db.doc('socialLimits/' + uid).delete(),
    owned.user.delete(),
  ]);
  await purge(db.collection('reports').where('reporter', '==', uid));

  // 4. Private photos, then the sign-in itself. The account goes last so a
  //    failure before this point leaves the user able to try again.
  await bucket.deleteFiles({ prefix: `users/${uid}/`, force: true }).catch(() => {});
  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    // A sign-in that is already gone means the job is done, not that it
    // failed: everything above has been deleted by this point, and reporting
    // failure would invite a retry that finds nothing left to remove.
    if (error?.code !== 'auth/user-not-found') throw error;
  }
  return { ok: true };
});
