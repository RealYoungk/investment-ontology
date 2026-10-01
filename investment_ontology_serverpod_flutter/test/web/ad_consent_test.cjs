const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../../web/ad_consent.js'),'utf8');
function environment(){
 const values=new Map(),events={},nodes=new Map(),children=[];
 const element=()=>({children:[],style:{},setAttribute(){},appendChild(c){this.children.push(c);},remove(){this.removed=true;}});
 for(const id of ['ad-choice-status','ad-reject','ad-accept','ad-google'])nodes.set(id,element());
 const root={localStorage:{getItem:k=>values.get(k)||null,setItem:(k,v)=>values.set(k,v)},addEventListener:(k,f)=>events[k]=f,dispatchEvent(){}};
 vm.runInNewContext(source,{window:root,document:{getElementById:k=>nodes.get(k),createElement:element,body:{appendChild:c=>children.push(c)}},Event:class{},Date,JSON,Promise});
 return{root,values,events,nodes,children};
}
test('no choice means no permission; reject remains across requests',async()=>{
 const e=environment();assert.equal(e.root.alfinderAdConsent.choice(),null);
 const promise=e.root.alfinderAdConsent.request();assert.equal(e.children.length,1);
 e.children[0].children.find(x=>x.textContent==='광고 거부').onclick();
 assert.equal(await promise,false);assert.equal(await e.root.alfinderAdConsent.request(),false);
 assert.equal(e.children[0].removed,true);
});
test('explicit opt-in only, expiry or old policy invalidates stored choice',async()=>{
 const e=environment();e.nodes.get('ad-accept').onclick();assert.equal(await e.root.alfinderAdConsent.request(),true);
 const stored=JSON.parse(e.values.get('alfinder.adConsent'));stored.expires=0;e.values.set('alfinder.adConsent',JSON.stringify(stored));assert.equal(e.root.alfinderAdConsent.choice(),null);
 stored.expires=Date.now()+10000;stored.version='old';e.values.set('alfinder.adConsent',JSON.stringify(stored));assert.equal(e.root.alfinderAdConsent.choice(),null);
});
test('another tab can revoke; detailed choice first blocks local ads',()=>{
 const e=environment();e.nodes.get('ad-accept').onclick();
 e.values.set('alfinder.adConsent',JSON.stringify({version:'2026-10-01',expires:Date.now()+10000,allowed:false}));e.events.storage({key:'alfinder.adConsent'});
 assert.equal(e.root.alfinderAdConsent.choice(),false);assert.equal(e.nodes.get('ad-choice-status').textContent,'광고 거부됨');
 e.nodes.get('ad-google').onclick();assert.equal(e.root.alfinderAdConsent.choice(),false);assert.ok(e.values.has('alfinder.adSettingsRequest'));
});
test('storage failure does not cause an exception or silently approve',async()=>{
 const e=environment();e.root.localStorage.getItem=()=>{throw Error('blocked')};e.root.localStorage.setItem=()=>{throw Error('blocked')};
 assert.equal(e.root.alfinderAdConsent.choice(),null);e.nodes.get('ad-reject').onclick();assert.equal(await e.root.alfinderAdConsent.request(),false);
});
