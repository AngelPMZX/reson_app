'use strict';
// Explicitly opt in: creates and removes only temporary diagnostic accounts/data.
if(process.env.RESON_LIVE_SMOKE!=='1')throw Error('Set RESON_LIVE_SMOKE=1');
const assert=require('node:assert/strict');const {randomBytes}=require('node:crypto');
const cli=require('../tools/firestore-tests/node_modules/firebase-tools/lib/configstore').configstore;
const cliAuth=require('../tools/firestore-tests/node_modules/firebase-tools/lib/auth');
const fRequire=require('node:module').createRequire(require.resolve('../functions/package.json'));
const {initializeApp,deleteApp}=fRequire('firebase-admin/app');
const {getFirestore,FieldValue}=fRequire('firebase-admin/firestore');
const {getAuth}=fRequire('firebase-admin/auth');
const {getStorage}=fRequire('firebase-admin/storage');
const {connectionId}=require('../functions/domain');
const project='reson-app',base='https://us-central1-reson-app.cloudfunctions.net/';
(async()=>{
 const token=await cliAuth.getAccessToken(cli.get('tokens').refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
 const app=initializeApp({projectId:project,storageBucket:project+'.firebasestorage.app',credential:{getAccessToken:async()=>({access_token:token.access_token,expires_in:3600})}},'reson-social-smoke');
 const api=require('../tools/firestore-tests/node_modules/firebase-tools/lib/api');
 const credentials={type:'authorized_user',client_id:api.clientId(),client_secret:api.clientSecret(),refresh_token:cli.get('tokens').refresh_token};
 const db=new (fRequire('@google-cloud/firestore').Firestore)({projectId:project,credentials}),auth=getAuth(app),bucket=new (fRequire('@google-cloud/storage').Storage)({projectId:project,credentials}).bucket(project+'.firebasestorage.app'),users=[],pubs=[];let conn;
 const key=require('node:fs').readFileSync('lib/firebase_options.dart','utf8').match(/apiKey: '([^']+)'/)[1];
 async function call(user,action,data={}){const response=await fetch(base+'socialAction',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+user.token},body:JSON.stringify({data:{action,...data}})});const result=await response.json();if(result.error){const err=Error(result.error.status);err.code=result.error.status;throw err;}return result.result;}
 try{
  for(let i=0;i<3;i++){
   const password=randomBytes(24).toString('base64url'),email=`reson-diagnostic-social-${Date.now()}-${i}@example.com`;
   const user=await auth.createUser({email,password,emailVerified:true,displayName:'Reson diagnostic'});users.push({uid:user.uid,email});
   const response=await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key='+key,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});const result=await response.json();assert.ok(result.idToken);users[i].token=result.idToken;
  }
  const [a,b,eve]=users;const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=','base64');const photo=`users/${a.uid}/profile/${Date.now()}`;await bucket.file(photo).save(png,{contentType:'image/png'});
  for(const u of [a,b]){
   const ref=db.collection('users/'+u.uid+'/cards').doc();u.cardId=ref.id;
   await ref.set({ownerId:u.uid,label:'Diagnostic',identity:{displayName:'Reson test',jobTitle:'Designer',company:'HIDDEN COMPANY'},contact:{email:'HIDDEN EMAIL',phone:'',website:''},theme:{primaryHex:'#C8102E'},kind:'work',layout:'signature',bio:'',visibleFields:['photo','role','company','email'],photoPath:u===a?photo:'',professional:{},schemaVersion:1,createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
   const p=await call(u,'publish',{cardId:u.cardId,fields:['photo','role']});u.publicId=p.id;pubs.push(p.id);
  }
  let r=await fetch('https://reson-app.web.app/c/'+a.publicId);assert.equal(r.status,200);const html=await r.text();assert.ok(html.includes('Reson test'));assert.ok(!html.includes('HIDDEN'));
  r=await fetch('https://reson-app.web.app/c/'+a.publicId+'/photo');assert.equal(r.status,200);assert.deepEqual(Buffer.from(await r.arrayBuffer()),png);
  r=await fetch('https://reson-app.web.app/c/'+a.publicId+'/contact.vcf');const vc=await r.text();assert.ok(vc.startsWith('BEGIN:VCARD'));assert.ok(!vc.includes('HIDDEN'));
  console.log('PASS public HTML, private-field redaction, public photo and vCard');
  await call(b,'save',{publicId:a.publicId});assert.ok((await db.doc(`users/${b.uid}/received/${a.publicId}`).get()).exists);
  conn=(await call(a,'request',{publicId:b.publicId,ownPublicId:a.publicId})).id;
  await assert.rejects(()=>call(a,'message',{connectionId:conn,messageId:'smoke',text:'Diagnostic hello'}));
  await assert.rejects(()=>call(a,'respond',{connectionId:conn,decision:'accept'}));
  await call(b,'respond',{connectionId:conn,decision:'accept'});
  await call(a,'message',{connectionId:conn,messageId:'smoke',text:'Diagnostic hello'});
  await call(a,'message',{connectionId:conn,messageId:'smoke',text:'Diagnostic hello'});
  assert.equal((await db.collection('connections/'+conn+'/messages').get()).size,1);
  const docUrl='https://firestore.googleapis.com/v1/projects/'+project+'/databases/(default)/documents/connections/'+conn+'/messages/smoke';
  assert.equal((await fetch(docUrl,{headers:{Authorization:'Bearer '+eve.token}})).status,403);
  assert.equal((await fetch(docUrl,{headers:{Authorization:'Bearer '+b.token}})).status,200);
  console.log('PASS save, request, recipient acceptance, idempotent chat and outsider rejection');
  await call(b,'block',{connectionId:conn});await assert.rejects(()=>call(a,'message',{connectionId:conn,messageId:'blocked',text:'Must fail'}));
  await call(a,'unpublish',{cardId:a.cardId});assert.equal((await fetch('https://reson-app.web.app/c/'+a.publicId)).status,404);assert.equal((await fetch('https://reson-app.web.app/c/'+a.publicId+'/photo')).status,404);
  console.log('PASS blocking and revocation of link/photo');
 }finally{
  for(const u of users){if(!u.email.startsWith('reson-diagnostic-social-'))throw Error('Unexpected test user');const owned=await db.collection('publicCards').where('ownerId','==',u.uid).get();for(const d of owned.docs){await bucket.deleteFiles({prefix:'sharedPhotos/'+d.id+'/'});await d.ref.delete();}await bucket.deleteFiles({prefix:'users/'+u.uid+'/'});await db.recursiveDelete(db.doc('users/'+u.uid));await db.doc('socialLimits/'+u.uid).delete();await auth.deleteUser(u.uid);}
  if(users.length>=2){const id=connectionId(users[0].uid,users[1].uid);await db.recursiveDelete(db.doc('connections/'+id));for(const u of users)await db.doc('reports/'+id+'_'+u.uid).delete();}
  await deleteApp(app);console.log('Temporary diagnostic accounts, photos, cards and messages removed.');
 }
})().catch(e=>{console.error('SMOKE FAILED:',e.code||e.message);process.exitCode=1;});
