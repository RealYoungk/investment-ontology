const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../web/ad_loader.js'), 'utf8');
const publisher = 'ca-pub-1234567890123456';
const slot = '1234567890';
function environment() {
  const scripts = [], cmpScripts = [], frames = new Map(), timers = new Map(), observers = [];
  let id = 0;
  function element() {
    const attrs = new Map();
    return {isConnected: true, style: {}, children: [],
      getBoundingClientRect: () => ({width: 728}),
      appendChild(child) {this.children.push(child);},
      replaceChildren() {this.children=[];},
      setAttribute(k,v) {attrs.set(k,v);}, getAttribute(k) {return attrs.get(k);}};
  }
  const events={};
  const root={addEventListener:(name,fn)=>events[name]=fn};
  root.alfinderAdConsent={choice:()=>true,request:async()=>true};
  root.__tcfapi=(_cmd,_version,callback)=>callback({eventStatus:'tcloaded',gdprApplies:false},true);
  root.googlefc={usstatesoptout:{getInitialUsStatesOptOutStatus:()=>1},callbackQueue:{push:item=>{if(item.CONSENT_API_READY)item.CONSENT_API_READY();if(item.INITIAL_US_STATES_OPT_OUT_DATA_READY)item.INITIAL_US_STATES_OPT_OUT_DATA_READY();}}};
  vm.runInNewContext(source, {window:root,URLSearchParams,
    document:{head:{appendChild:s=>{if(s.src.includes('fundingchoicesmessages')){cmpScripts.push(s);Promise.resolve().then(()=>s.onload());}else scripts.push(s);}},createElement:()=>element()},
    requestAnimationFrame:fn=>{frames.set(++id,fn);return id;}, cancelAnimationFrame:i=>frames.delete(i),
    setTimeout:fn=>{timers.set(++id,fn);return id;}, clearTimeout:i=>timers.delete(i),
    MutationObserver:class {constructor(fn){this.fn=fn;observers.push(this);} observe(){} disconnect(){this.disconnected=true;}}
  });
  async function tick(){const f=[...frames.values()];frames.clear();for(const fn of f)fn();for(let i=0;i<12;i++)await Promise.resolve();}
  return {root,scripts,cmpScripts,frames,timers,observers,element,tick,events};
}
test('loading local bridge and invalid IDs never request ads', async()=>{
  const e=environment();assert.equal(e.scripts.length,0);
  assert.equal(await e.root.alfinderAds.mount(e.element(),'bad',slot,true),false);
  assert.equal(e.scripts.length,0);
});
test('dispose before attachment cancels loading',async()=>{
  const e=environment(),el=e.element();el.isConnected=false;
  const p=e.root.alfinderAds.mount(el,publisher,slot,true);
  e.root.alfinderAds.dispose(el);await e.tick();assert.equal(await p,false);
  assert.equal(e.scripts.length,0);assert.equal(e.frames.size,0);
});
test('loads once, test mode is explicit, never refreshes same element',async()=>{
  const e=environment(),el=e.element();
  const p=e.root.alfinderAds.mount(el,publisher,slot,true);
  assert.equal(e.root.alfinderAds.mount(el,publisher,slot,true),p);
  await e.tick();assert.equal(e.scripts.length,1);e.scripts[0].onload();await e.tick();
  assert.equal(e.root.adsbygoogle.length,1);assert.equal(el.children[0].getAttribute('data-adtest'),'on');
  el.children[0].setAttribute('data-ad-status','filled');e.observers[0].fn();assert.equal(await p,true);
  await e.tick();assert.equal(e.root.adsbygoogle.length,1);assert.equal(e.timers.size,0);
  e.root.alfinderAds.dispose(el);assert.equal(el.children.length,0);
  const next=e.element(),p2=e.root.alfinderAds.mount(next,publisher,slot,false);await e.tick();
  assert.equal(e.scripts.length,1);assert.equal(next.children[0].getAttribute('data-adtest'),undefined);
  e.root.alfinderAds.dispose(next);assert.equal(await p2,false);
});
test('no fill and script failure resolve false without retries',async()=>{
  const e=environment(),el=e.element();const p=e.root.alfinderAds.mount(el,publisher,slot,true);
  await e.tick();e.scripts[0].onload();await e.tick();
  el.children[0].setAttribute('data-ad-status','unfilled');e.observers[0].fn();assert.equal(await p,false);
  const f=environment(),p2=f.root.alfinderAds.mount(f.element(),publisher,slot,true);
  await f.tick();f.scripts[0].onerror();await f.tick();assert.equal(await p2,false);assert.equal(f.scripts.length,1);
});
test('paid-account disposal during script loading prevents late ad push',async()=>{
  const e=environment(),el=e.element();const p=e.root.alfinderAds.mount(el,publisher,slot,true);
  await e.tick();e.root.alfinderAds.dispose(el);e.scripts[0].onload();await e.tick();
  assert.equal(await p,false);assert.equal(e.root.adsbygoogle,undefined);assert.equal(el.children.length,0);
});
test('narrow container waits without requesting then cancels on disposal',async()=>{
 const e=environment(),el=e.element();el.getBoundingClientRect=()=>({width:249});
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();
 assert.equal(e.scripts.length,0);e.root.alfinderAds.dispose(el);assert.equal(await p,false);
 assert.equal(e.frames.size,0);
});
test('slot timeout cancels observers and prevents later pushes',async()=>{
 const e=environment(),el=e.element();el.isConnected=false;
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);
 for(const fn of [...e.timers.values()])fn();assert.equal(await p,false);
 el.isConnected=true;await e.tick();assert.equal(e.scripts.length,0);
});
test('publisher change cannot silently reuse another publisher script',async()=>{
 const e=environment(),el=e.element();const p=e.root.alfinderAds.mount(el,publisher,slot,true);
 await e.tick();e.scripts[0].onload();await e.tick();e.root.alfinderAds.dispose(el);await p;
 const next=e.element(),p2=e.root.alfinderAds.mount(next,'ca-pub-9999999999999999',slot,true);
 await e.tick();assert.equal(await p2,false);assert.equal(e.scripts.length,1);
});
test('dispose after no fill clears DOM and disconnected observers',async()=>{
 const e=environment(),el=e.element();const p=e.root.alfinderAds.mount(el,publisher,slot,true);
 await e.tick();e.scripts[0].onload();await e.tick();
 el.children[0].setAttribute('data-ad-status','unfilled');e.observers[0].fn();await p;
 assert.equal(e.observers[0].disconnected,true);e.root.alfinderAds.dispose(el);assert.equal(el.children.length,0);
});

test('reject or missing consent bridge never fetches Google',async()=>{
 for(const consent of [undefined,{choice:()=>false,request:async()=>false}]) {
  const e=environment();e.root.alfinderAdConsent=consent;
  const p=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
  assert.equal(await p,false);assert.equal(e.scripts.length,0);
 }
});
test('EU rejection or CMP failure never pushes an ad',async()=>{
 for(const data of [null,{eventStatus:'useractioncomplete',gdprApplies:true,cmpId:300,purpose:{consents:{1:false}},vendor:{consents:{755:true}}}]){
  const e=environment();e.root.__tcfapi=(_c,_v,cb)=>cb(data,!!data);
  const p=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
  assert.equal(e.scripts.length,0);assert.equal(await p,false);assert.equal(e.root.adsbygoogle,undefined);
 }
});

test('CMP opt-in permits contextual ads; later withdrawal removes filled DOM',async()=>{
 const e=environment(),el=e.element();let listener,removed=0;
 e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='removeEventListener'){removed++;return;}listener=cb;cb({eventStatus:'tcloaded',gdprApplies:true,cmpId:300,listenerId:12,purpose:{consents:{1:true}},vendor:{consents:{755:true}}},true);};
 const p=e.root.alfinderAds.mount(el,publisher,slot,false);await e.tick();e.scripts[0].onload();await e.tick();
 assert.equal(e.root.adsbygoogle.requestNonPersonalizedAds,1);assert.equal(e.root.adsbygoogle.length,1);
 el.children[0].setAttribute('data-ad-status','filled');e.observers[0].fn();assert.equal(await p,true);
 listener({eventStatus:'useractioncomplete',gdprApplies:true,cmpId:300,listenerId:12,purpose:{consents:{1:false}},vendor:{consents:{755:false}}},true);
 assert.equal(el.children.length,0);assert.equal(removed,1);
});
test('local withdrawal while CMP is pending prevents late ad push',async()=>{
 const e=environment(),el=e.element();let listener;
 e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='addEventListener')listener=cb;};
 const p=e.root.alfinderAds.mount(el,publisher,slot,false);await e.tick();
 assert.equal(e.scripts.length,0);
 e.root.alfinderAdConsent.choice=()=>false;e.events['alfinder-ad-consent']();
 listener({eventStatus:'tcloaded',gdprApplies:false},true);await e.tick();
 assert.equal(await p,false);assert.equal(el.children.length,0);assert.equal(e.root.adsbygoogle,undefined);
});

// These test both transport setup and slot pushes; a script fetch is not an ad push.
test('CMP missing, unknown jurisdiction, wrong CMP or missing vendor cannot request inventory',async()=>{
 for(const data of [undefined,{eventStatus:'tcloaded'},
  {eventStatus:'tcloaded',gdprApplies:true,cmpId:999,purpose:{consents:{1:true}},vendor:{consents:{755:true}}},
  {eventStatus:'tcloaded',gdprApplies:true,cmpId:300,purpose:{consents:{1:true}}}]){
  const e=environment(),el=e.element();
  if(data===undefined)e.root.googlefc.callbackQueue=[];
  else e.root.__tcfapi=(_c,_v,cb)=>cb(data,true);
  const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();
  assert.equal(e.scripts.length,0);
  for(const fn of [...e.timers.values()])fn();await e.tick();
  assert.equal(await p,false);assert.equal(e.root.adsbygoogle,undefined);assert.equal(el.children.length,0);
 }
});
test('initial CMP UI has a deadline and late consent cannot push',async()=>{
 const e=environment(),el=e.element();let listener;
 e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='addEventListener'){listener=cb;cb({eventStatus:'cmpuishown',listenerId:3},true);}};
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();
 assert.equal(e.scripts.length,0);assert.ok(e.timers.size>0);
 for(const fn of [...e.timers.values()])fn();await e.tick();assert.equal(await p,false);
 listener({eventStatus:'useractioncomplete',gdprApplies:false},true);await e.tick();assert.equal(e.root.adsbygoogle,undefined);
});
test('post-approval error, reopened UI or unknown jurisdiction removes inventory',async()=>{
 for(const data of [null,{eventStatus:'cmpuishown'},{eventStatus:'tcloaded'},
  {eventStatus:'tcloaded',gdprApplies:false,cmpStatus:'error'}]){
  const e=environment(),el=e.element();let listener;
  e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='addEventListener'){listener=cb;cb({eventStatus:'tcloaded',gdprApplies:false,listenerId:3},true);}};
  const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();e.scripts[0].onload();await e.tick();
  assert.equal(e.root.adsbygoogle.length,1);el.children[0].setAttribute('data-ad-status','filled');e.observers[0].fn();assert.equal(await p,true);
  listener(data,!!data);await e.tick();assert.equal(el.children.length,0);assert.equal(e.root.adsbygoogle.length,1);
 }
});

test('actual Google non-GDPR loaded callback may omit eventStatus',async()=>{
 const e=environment(),el=e.element();
 e.root.__tcfapi=(_c,_v,cb)=>cb({gdprApplies:false,cmpId:300,cmpStatus:'loaded'},true);
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();e.scripts[0].onload();await e.tick();
 assert.equal(e.root.adsbygoogle.length,1);e.root.alfinderAds.dispose(el);assert.equal(await p,false);
});

test('delayed CMP grants permission before AdSense script is inserted',async()=>{
 const e=environment(),el=e.element();let listener;
 e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='addEventListener')listener=cb;};
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();
 assert.equal(e.cmpScripts.length,1);assert.equal(e.scripts.length,0);
 listener({eventStatus:'useractioncomplete',gdprApplies:true,cmpId:300,purpose:{consents:{1:true}},vendor:{consents:{755:true}}},true);
 await e.tick();assert.equal(e.scripts.length,1);e.scripts[0].onload();await e.tick();
 assert.equal(e.root.adsbygoogle.length,1);e.root.alfinderAds.dispose(el);await p;
});

test('reopened CMP during AdSense download prevents late slot push',async()=>{
 const e=environment(),el=e.element();let listener;
 e.root.__tcfapi=(cmd,_v,cb)=>{if(cmd==='addEventListener'){listener=cb;cb({eventStatus:'tcloaded',gdprApplies:false,listenerId:8},true);}};
 const p=e.root.alfinderAds.mount(el,publisher,slot,true);await e.tick();assert.equal(e.scripts.length,1);
 listener({eventStatus:'cmpuishown',listenerId:8},true);e.scripts[0].onload();await e.tick();
 assert.equal(await p,false);assert.equal(e.root.adsbygoogle,undefined);assert.equal(el.children.length,0);
});

test('US unknown, opt-out, missing GPP, or GPC never loads inventory',async()=>{
 for(const status of [0,3,undefined,2]) {
  const e=environment();e.root.googlefc.usstatesoptout.getInitialUsStatesOptOutStatus=()=>status;
  const p=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
  for(const fn of [...e.timers.values()])fn();await e.tick();
  assert.equal(await p,false);assert.equal(e.scripts.length,0);
 }
 const e=environment();e.root.navigator={globalPrivacyControl:true};
 const p=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
 assert.equal(await p,false);assert.equal(e.scripts.length,0);
});
test('US GPP ready permits once; a signal change invalidates before or after inventory download',async()=>{
 for(const [loaded,signal] of [[false,'not ready'],[true,'not ready'],[true,'error']]) {
  const e=environment();e.root.googlefc.usstatesoptout.getInitialUsStatesOptOutStatus=()=>2;
  let callback;
  e.root.__gpp=(cmd,cb)=>{if(cmd==='addEventListener'){callback=cb;cb({listenerId:1,eventName:'listenerRegistered',pingData:{cmpStatus:'loaded',signalStatus:'ready',parsedSections:{usnat:{SaleOptOut:2,SharingOptOut:2,TargetedAdvertisingOptOut:2}}}},true);}};
  const el=e.element(),p=e.root.alfinderAds.mount(el,publisher,slot,false);await e.tick();
  assert.equal(e.scripts.length,1);
  if(loaded){e.scripts[0].onload();await e.tick();assert.equal(e.root.adsbygoogle.length,1);}
  callback({eventName:'signalStatus',pingData:{cmpStatus:signal==='error'?'error':'loaded',signalStatus:signal==='error'?'ready':signal}},true);
  if(!loaded){e.scripts[0].onload();await e.tick();assert.equal(e.root.adsbygoogle,undefined);}
  assert.equal(await p,false);assert.equal(el.children.length,0);
 }
});

test('only documented CMP previews are forwarded, never activation or arbitrary URLs',async()=>{
 const e=environment();e.root.location={search:'?fc=alwaysshow&fctype=gdpr&enabled=true&redirect=https://other.test'};
 e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
 assert.match(e.cmpScripts[0].src,/\?ers=1&fc=alwaysshow&fctype=gdpr$/);
 assert.equal(e.cmpScripts[0].src.includes('enabled'),false);
});


test('cached US initial allow cannot override a current opt-out on remount',async()=>{
 const e=environment();e.root.googlefc.usstatesoptout.getInitialUsStatesOptOutStatus=()=>2;
 let optedOut=false;
 e.root.__gpp=(cmd,cb)=>{if(cmd==='addEventListener')cb({listenerId:1,eventName:'listenerRegistered',pingData:{cmpStatus:'loaded',signalStatus:'ready',parsedSections:{usnat:{SaleOptOut:optedOut?1:2,SharingOptOut:optedOut?1:2,TargetedAdvertisingOptOut:optedOut?1:2}}}},true);};
 const first=e.element();e.root.alfinderAds.mount(first,publisher,slot,false);await e.tick();assert.equal(e.scripts.length,1);
 e.root.alfinderAds.dispose(first);optedOut=true;
 const remount=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();
 assert.equal(await remount,false);assert.equal(e.scripts.length,1);assert.equal(e.root.adsbygoogle,undefined);
});
test('ready GPP with missing or unknown parsed choices remains blocked',async()=>{
 for(const parsedSections of [undefined,{}, {usnat:{SaleOptOut:undefined}}, {usnat:{SaleOptOut:4}}]){
  const e=environment();e.root.googlefc.usstatesoptout.getInitialUsStatesOptOutStatus=()=>2;
  e.root.__gpp=(cmd,cb)=>{if(cmd==='addEventListener')cb({listenerId:1,eventName:'listenerRegistered',pingData:{cmpStatus:'loaded',signalStatus:'ready',parsedSections}},true);};
  const p=e.root.alfinderAds.mount(e.element(),publisher,slot,false);await e.tick();for(const fn of [...e.timers.values()])fn();await e.tick();
  assert.equal(await p,false);assert.equal(e.scripts.length,0);
 }
});
