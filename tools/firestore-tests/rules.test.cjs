const {test,before,after}=require('node:test');
const {readFileSync}=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,updateDoc,serverTimestamp,writeBatch}=require('firebase/firestore');
let env;
const uid='test-owner';
const id=(n)=>'abcdefghijklmnop'+String(n).padStart(4,'0');
const database=(owner=uid,verified=true)=>env.authenticatedContext(owner,{email_verified:verified}).firestore();
const path=(n)=>'users/'+uid+'/cards/'+id(n);
const career={title:'Engineer',organization:'Example',period:'2022 – present',details:'Product development'};
function card(extra={}) {return {
  ownerId:uid,label:'Work',identity:{displayName:'Alex',jobTitle:'Engineer',company:'Example'},
  contact:{email:'alex@example.com',phone:'',website:''},theme:{primaryHex:'#7860E9'},
  schemaVersion:1,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),...extra
};}
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-reson',
  firestore:{host:'127.0.0.1',port:8085,rules:readFileSync('firestore.rules','utf8')}});});
after(async()=>{if(env) await env.cleanup();});
test('legacy cards remain valid and private',async()=>{
  await assertSucceeds(setDoc(doc(database(),path(0)),card()));
  await assertSucceeds(getDoc(doc(database(),path(0))));
  await assertFails(getDoc(doc(database('another-owner'),path(0))));
  await assertFails(getDoc(doc(database(uid,false),path(0))));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),path(0))));
});
test('professional profile and new layouts can be saved',async()=>{
  for(const [i,layout] of ['noir','studio'].entries()){
    await assertSucceeds(setDoc(doc(database(),path(i+1)),card({layout,
      visibleFields:['photo','role','company','email','phone','website','bio','location','linkedin','skills','experience','education'],
      professional:{location:'Mexico',linkedin:'https://www.linkedin.com/in/example',skills:'Flutter, Design',
        experience:[career],education:[career]}})));
  }
});
test('entry limits, unexpected fields and unsafe links are rejected',async()=>{
  const p={location:'',linkedin:'',skills:'',experience:[],education:[]};
  for(const [i,professional] of [
    {...p,experience:Array(5).fill(career)},
    {...p,education:[{...career,title:''}]},
    {...p,experience:[{...career,admin:true}]},
    {...p,linkedin:'https://linkedin.com.evil.example/in/test'},
    {...p,skills:'x'.repeat(181)},
  ].entries()) await assertFails(setDoc(doc(database(),path(i+10)),card({professional})));
});
test('ownership, photo paths and immutable timestamps cannot be changed',async()=>{
  await assertFails(setDoc(doc(database(),path(20)),card({ownerId:'another-owner'})));
  await assertFails(setDoc(doc(database(),path(21)),card({photoPath:'users/another-owner/cards/'+id(21)+'/1'})));
  await assertFails(updateDoc(doc(database(),path(0)),{createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
});
test('hidden fields and valid updates preserve access restrictions',async()=>{
  await assertSucceeds(updateDoc(doc(database(),path(0)),{visibleFields:['education'],updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(database(uid,false),path(0)),{label:'Changed',updatedAt:serverTimestamp()}));
});

test('four entries in each section are accepted',async()=>{
 await assertSucceeds(setDoc(doc(database(),path(30)),card({professional:{location:'',linkedin:'',skills:'',
   experience:Array(4).fill(career),education:Array(4).fill(career)}})));
});

test('first card and account profile commit atomically with a full career',async()=>{
 const db=database('batch-owner');const batch=writeBatch(db);const cardId=id(40);
 batch.set(doc(db,'users/batch-owner/cards/'+cardId),card({ownerId:'batch-owner',
   professional:{location:'',linkedin:'',skills:'',experience:Array(4).fill(career),education:Array(4).fill(career)}}));
 batch.set(doc(db,'users/batch-owner'),{displayName:'Alex',activeCardId:cardId,schemaVersion:1,
   createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
 await assertSucceeds(batch.commit());
});

test('personal identity is optional, private and restricted to verified owners',async()=>{
 const target='users/'+uid+'/settings/identity';
 const identity={name:'',role:'',company:'',bio:'',email:'',phone:'',website:'',professional:{location:'',linkedin:'',skills:'',experience:[],education:[]},updatedAt:serverTimestamp()};
 await assertSucceeds(setDoc(doc(database(),target),identity));
 await assertSucceeds(getDoc(doc(database(),target)));
 await assertFails(getDoc(doc(database('other'),target)));
 await assertFails(getDoc(doc(database(uid,false),target)));
 await assertFails(setDoc(doc(database(uid,false),target),identity));
 await assertFails(setDoc(doc(database('other'),target),identity));
 await assertFails(setDoc(doc(database(),target),{...identity,admin:true}));
 await assertFails(setDoc(doc(database(),target),{...identity,name:'x'.repeat(81)}));
 await assertFails(setDoc(doc(database(),target),{...identity,website:'javascript:alert(1)'}));
 await assertSucceeds(setDoc(doc(database(),target),{...identity,professional:{...identity.professional,experience:Array(4).fill(career),education:Array(4).fill(career)}}));
});

test('profile extensions accept private photos and reject cross-owner paths',async()=>{
 const target='users/'+uid+'/settings/identity';
 const data={name:'Alex',role:'',company:'',bio:'',email:'',phone:'',website:'',professional:{location:'',linkedin:'',skills:'',experience:[],education:[]},updatedAt:serverTimestamp(),languages:'Español',services:'Diseño',availability:'projects',photoSource:'upload',photoPath:'users/'+uid+'/profile/123'};
 await assertSucceeds(setDoc(doc(database(),target),data));
 for(const extra of [{photoPath:'users/other/profile/123'},{photoPath:'https://example.com/photo.png'},{availability:'admin'},{languages:'x'.repeat(181)},{photoSource:'none',photoPath:data.photoPath}])await assertFails(setDoc(doc(database(),target),{...data,...extra}));
 await assertSucceeds(setDoc(doc(database(),target),{...data,photoSource:'none',photoPath:''}));
 await assertSucceeds(setDoc(doc(database(),path(70)),card({photoPath:data.photoPath})));
 await assertFails(setDoc(doc(database(),path(71)),card({photoPath:'users/other/profile/123'})));
});

test('extended professional data is private and validates limits',async()=>{
 const professional={location:'',linkedin:'',skills:'',experience:[],education:[],sector:'Salud',specialty:'Fisioterapia',workMode:'Presencial',projects:[career],certifications:[career]};
 await assertSucceeds(setDoc(doc(database(),path(81)),card({professional,visibleFields:['sector','specialty','workMode','projects','certifications']})));
 await assertFails(getDoc(doc(database('other'),path(81))));
 await assertFails(setDoc(doc(database(),path(82)),card({professional:{...professional,sector:'x'.repeat(101)}})));
 await assertFails(setDoc(doc(database(),path(83)),card({professional:{...professional,projects:Array(5).fill(career)}})));
 await assertFails(setDoc(doc(database(),path(84)),card({professional:{...professional,certifications:[{...career,title:''}]}})));
});

test('eight entries across four career sections save and update',async()=>{
 const professional={location:'',linkedin:'',skills:'',sector:'Salud',specialty:'General',workMode:'Remoto',experience:Array(2).fill(career),education:Array(2).fill(career),projects:Array(2).fill(career),certifications:Array(2).fill(career)};
 await assertSucceeds(setDoc(doc(database(),path(85)),card({professional})));
 await assertSucceeds(updateDoc(doc(database(),path(85)),{professional,updatedAt:serverTimestamp()}));
});

test('social data cannot be forged and conversations are member-only',async()=>{
 await env.withSecurityRulesDisabled(async context=>{
  const db=context.firestore();await setDoc(doc(db,'connections/test-connection'),{members:[uid,'friend'],status:'accepted'});
  await setDoc(doc(db,'connections/test-connection/messages/first'),{sender:uid,text:'Private hello'});
  await setDoc(doc(db,'publicCards/test-public'),{active:true,snapshot:{name:'Shared'}});
 });
 await assertSucceeds(getDoc(doc(database(),'connections/test-connection/messages/first')));
 await assertFails(getDoc(doc(database('stranger'),'connections/test-connection/messages/first')));
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'publicCards/test-public')));
 await assertFails(setDoc(doc(database(),'connections/forged'),{members:[uid,'victim'],status:'accepted'}));
 await assertFails(setDoc(doc(database(),'connections/test-connection/messages/forged'),{sender:'friend',text:'Fake'}));
 await assertFails(setDoc(doc(database(),'users/'+uid+'/publications/forged'),{active:true}));
 await env.withSecurityRulesDisabled(async context=>updateDoc(doc(context.firestore(),'connections/test-connection'),{status:'blocked'}));
 await assertFails(getDoc(doc(database(),'connections/test-connection/messages/first')));
});

test('the directory is readable by members and writable by nobody',async()=>{
 await env.withSecurityRulesDisabled(async context=>{
  await setDoc(doc(context.firestore(),'directory/someone'),{uid:'someone',name:'Listed',terms:['li','lis']});
 });
 // Searching is for verified accounts; being listed is the backend's to write.
 await assertSucceeds(getDoc(doc(database(),'directory/someone')));
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'directory/someone')));
 await assertFails(setDoc(doc(database(),'directory/'+uid),{uid,name:'Me',terms:['me']}));
 await assertFails(setDoc(doc(database(),'directory/someone'),{uid:'someone',name:'Hijacked',terms:['hi']}));
});
