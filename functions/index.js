'use strict';
const {initializeApp}=require('firebase-admin/app');
const {getFirestore,FieldValue,Timestamp}=require('firebase-admin/firestore');
const {getStorage}=require('firebase-admin/storage');
const {onCall,onRequest,HttpsError}=require('firebase-functions/v2/https');
const {randomBytes}=require('node:crypto');
const {snapshot,connectionId,vcard}=require('./domain');
const render=require('./render');
initializeApp({storageBucket:'reson-app.firebasestorage.app'});
const db=getFirestore(),bucket=getStorage().bucket(),now=()=>FieldValue.serverTimestamp();
const origin='https://reson-app.web.app';
const options={region:'us-central1',maxInstances:3,memory:'256MiB',timeoutSeconds:30};
const fail=(code,message)=>{throw new HttpsError(code,message);};
function id(v){if(typeof v!=='string'||! /^[a-zA-Z0-9_-]{1,128}$/.test(v))fail('invalid-argument','Invalid identifier');return v;}
function verified(req){if(!req.auth||req.auth.token.email_verified!==true)fail('unauthenticated','Verify your email first');return req.auth.uid;}
async function rate(uid){const ref=db.doc('socialLimits/'+uid);await db.runTransaction(async t=>{const d=(await t.get(ref)).data();const fresh=!d||Date.now()-d.start.toMillis()>60000;const count=fresh?1:d.count+1;if(count>40)fail('resource-exhausted','Please wait a minute');t.set(ref,{start:fresh?Timestamp.now():d.start,count});});}
function exposed(d){return {...d.snapshot,id:d.id,photoUrl:d.snapshot.photo?origin+'/c/'+d.id+'/photo':''};}
async function published(publicId){const d=(await db.doc('publicCards/'+id(publicId)).get()).data();if(!d?.active)fail('not-found','This card is not available');return d;}
async function publish(uid,data){
 const cardId=id(data.cardId),source=db.doc(`users/${uid}/cards/${cardId}`),mapping=db.doc(`users/${uid}/publications/${cardId}`);
 if(!Array.isArray(data.fields)||data.fields.length>17||data.fields.some(f=>typeof f!=='string'))fail('invalid-argument','Select fields');
 const card=(await source.get()).data();if(!card||card.ownerId!==uid)fail('not-found','Card not found');
 const reservation=await db.runTransaction(async t=>{const old=(await t.get(mapping)).data();const value={id:old?.id??randomBytes(16).toString('hex'),revision:(old?.revision??0)+1};t.set(mapping,{...value,label:card.label,active:old?.active??false,updatedAt:now()});return value;});
 const p=snapshot(card,data.fields);p.whatsapp=data.whatsapp===true&&!!p.phone;p.photo=false;
 let photoPath='';
 if(p.visibleFields.includes('photo')&&card.photoPath){
  if(!card.photoPath.startsWith(`users/${uid}/profile/`)&&!card.photoPath.startsWith(`users/${uid}/cards/`))fail('permission-denied','Invalid photo');
  photoPath=`sharedPhotos/${reservation.id}/${reservation.revision}`;
  try{await bucket.file(card.photoPath).copy(bucket.file(photoPath));await bucket.file(photoPath).setMetadata({metadata:{firebaseStorageDownloadTokens:null},cacheControl:'private, no-store'});p.photo=true;}catch{await bucket.file(photoPath).delete({ignoreNotFound:true}).catch(()=>{});fail('unavailable','Photo could not be published');}
 }
 const target=db.doc('publicCards/'+reservation.id);let oldPhoto='';
 try{await db.runTransaction(async t=>{const current=(await t.get(mapping)).data();const old=(await t.get(target)).data();if(current.revision!==reservation.revision)fail('aborted','Publication changed; retry');oldPhoto=old?.photoPath??'';t.set(target,{id:reservation.id,ownerId:uid,cardId,active:true,snapshot:p,photoPath,updatedAt:now()});t.update(mapping,{active:true,updatedAt:now()});});}catch(e){if(photoPath)await bucket.file(photoPath).delete({ignoreNotFound:true}).catch(()=>{});throw e;}
 if(oldPhoto&&oldPhoto!==photoPath)await bucket.file(oldPhoto).delete({ignoreNotFound:true}).catch(()=>{});
 return {id:reservation.id,url:origin+'/c/'+reservation.id};
}
async function social(uid,data){
 const action=data.action;
 if(action==='publish')return publish(uid,data);
 if(action==='unpublish'){
  const ref=db.doc(`users/${uid}/publications/${id(data.cardId)}`);let photo='';
  await db.runTransaction(async t=>{const d=(await t.get(ref)).data();if(!d)return;const pub=db.doc('publicCards/'+d.id);const old=(await t.get(pub)).data();photo=old?.photoPath??'';t.update(ref,{active:false,revision:d.revision+1,updatedAt:now()});t.set(pub,{active:false},{merge:true});});
  if(photo)await bucket.file(photo).delete({ignoreNotFound:true}).catch(()=>{});return {ok:true};
 }
 if(action==='save'){
  const p=await published(data.publicId);await db.doc(`users/${uid}/received/${p.id}`).set({publicId:p.id,name:p.snapshot.name,label:p.snapshot.label,savedAt:now()});return {ok:true};
 }
 if(action==='removeSaved'){await db.doc(`users/${uid}/received/${id(data.publicId)}`).delete();return {ok:true};}
 if(action==='request'){
  const targetId=id(data.publicId),ownId=id(data.ownPublicId);let result;
  await db.runTransaction(async t=>{
   const target=(await t.get(db.doc('publicCards/'+targetId))).data(),own=(await t.get(db.doc('publicCards/'+ownId))).data();
   if(!target?.active||!own?.active||own.ownerId!==uid)fail('failed-precondition','Publish your card first');const other=target.ownerId;if(other===uid)fail('invalid-argument','You cannot connect to yourself');
   const key=connectionId(uid,other),ref=db.doc('connections/'+key);
   const [a,b,current]=await Promise.all([t.get(db.doc(`users/${uid}/blocks/${other}`)),t.get(db.doc(`users/${other}/blocks/${uid}`)),t.get(ref)]);
   if(a.exists||b.exists)fail('permission-denied','Connection unavailable');
   if(current.exists){if(['declined','blocked'].includes(current.data().status))fail('failed-precondition','Connection unavailable');result={id:key,status:current.data().status};return;}
   t.set(ref,{members:[uid,other],requester:uid,recipient:other,status:'pending',cards:{[uid]:ownId,[other]:targetId},names:{[uid]:own.snapshot.name,[other]:target.snapshot.name},createdAt:now(),updatedAt:now(),lastMessageAt:Timestamp.fromMillis(0)});result={id:key,status:'pending'};
  });return result;
 }
 if(action==='respond'){
  const ref=db.doc('connections/'+id(data.connectionId));if(!['accept','decline'].includes(data.decision))fail('invalid-argument','Invalid decision');
  await db.runTransaction(async t=>{const d=(await t.get(ref)).data();if(!d||d.recipient!==uid)fail('permission-denied','Recipient only');if(d.status!=='pending'){if(data.decision==='accept'&&d.status==='accepted')return;fail('failed-precondition','Request already answered');}
   const other=d.requester;const [a,b]=await Promise.all([t.get(db.doc(`users/${uid}/blocks/${other}`)),t.get(db.doc(`users/${other}/blocks/${uid}`))]);if(a.exists||b.exists)fail('permission-denied','Connection unavailable');
   t.update(ref,{status:data.decision==='accept'?'accepted':'declined',updatedAt:now()});
  });return {ok:true};
 }
 if(action==='message'){
  const text=typeof data.text==='string'?data.text.trim():'';if(!text||text.length>2000)fail('invalid-argument','Message must be 1–2000 characters');
  const ref=db.doc('connections/'+id(data.connectionId)),message=ref.collection('messages').doc(id(data.messageId));
  await db.runTransaction(async t=>{const d=(await t.get(ref)).data();if(!d||!d.members.includes(uid)||d.status!=='accepted')fail('permission-denied','Accepted connection required');const other=d.members.find(m=>m!==uid);
   const [a,b,existing]=await Promise.all([t.get(db.doc(`users/${uid}/blocks/${other}`)),t.get(db.doc(`users/${other}/blocks/${uid}`)),t.get(message)]);if(a.exists||b.exists)fail('permission-denied','Connection unavailable');
   if(existing.exists){if(existing.data().sender!==uid||existing.data().text!==text)fail('already-exists','Message ID conflict');return;}
   if(Date.now()-d.lastMessageAt.toMillis()<700)fail('resource-exhausted','Please wait');
   t.create(message,{sender:uid,text,createdAt:now()});t.update(ref,{lastMessageAt:now(),updatedAt:now()});
  });return {ok:true};
 }
 if(action==='block'){
  const ref=db.doc('connections/'+id(data.connectionId));await db.runTransaction(async t=>{const d=(await t.get(ref)).data();if(!d?.members.includes(uid))fail('permission-denied','Not a member');const other=d.members.find(m=>m!==uid);t.set(db.doc(`users/${uid}/blocks/${other}`),{createdAt:now()});t.update(ref,{status:'blocked',updatedAt:now()});});return {ok:true};
 }
 if(action==='report'){
  const ref=db.doc('connections/'+id(data.connectionId)),d=(await ref.get()).data();if(!d?.members.includes(uid))fail('permission-denied','Not a member');const reason=String(data.reason??'').trim();if(!reason||reason.length>500)fail('invalid-argument','Reason required');await db.doc(`reports/${ref.id}_${uid}`).set({reporter:uid,connectionId:ref.id,reason,createdAt:now()});return {ok:true};
 }
 fail('invalid-argument','Unknown action');
}
exports.socialAction=onCall(options,async req=>{const uid=verified(req);await rate(uid);return social(uid,req.data??{});});
exports.sharedCard=onRequest({...options,invoker:'public'},async(req,res)=>{
 res.set('Cache-Control','private, no-store');res.set('X-Content-Type-Options','nosniff');res.set('Referrer-Policy','no-referrer');res.set('Content-Security-Policy',"default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'");
 if(!['GET','HEAD'].includes(req.method)){res.status(405).end();return;}
 const match=req.path.match(/^\/c\/([a-f0-9]{32})(?:\/(photo|contact\.vcf))?\/?$/);if(!match){res.status(404).send('Tarjeta no disponible · Card unavailable');return;}
 try{const p=await published(match[1]);if(match[2]==='photo'){
   if(!p.photoPath||!p.snapshot.photo){res.status(404).end();return;}
   const file=bucket.file(p.photoPath);const [meta]=await file.getMetadata();res.type(meta.contentType??'image/jpeg');file.createReadStream().on('error',()=>res.end()).pipe(res);return;
  }if(match[2]==='contact.vcf'){res.set('Content-Disposition','attachment; filename="reson.vcf"');res.type('text/vcard; charset=utf-8').send(vcard(p.snapshot,origin+'/c/'+p.id));return;}
  res.type('html').send(render(p.snapshot,p.id,origin,req.query.lang==='en'));
 }catch{res.status(404).type('html').send('<meta name="viewport" content="width=device-width"><p>Esta tarjeta no está disponible. · This card is unavailable.</p>');}
});
// Public lookup is deliberately independent of private profile documents.
exports.getSharedCard=onCall(options,async req=>exposed(await published(req.data?.publicId)));
