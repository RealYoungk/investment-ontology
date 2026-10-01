const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../web/ad_loader.js'), 'utf8');
const publisher = 'ca-pub-1234567890123456';
const slot = '1234567890';
function environment() {
  const scripts = [], frames = new Map(), timers = new Map(), observers = [];
  let id = 0;
  function element() {
    const attrs = new Map();
    return {isConnected: true, style: {}, children: [],
      getBoundingClientRect: () => ({width: 728}),
      appendChild(child) {this.children.push(child);},
      replaceChildren() {this.children=[];},
      setAttribute(k,v) {attrs.set(k,v);}, getAttribute(k) {return attrs.get(k);}};
  }
  const root={};
  vm.runInNewContext(source, {window:root,
    document:{head:{appendChild:s=>scripts.push(s)},createElement:()=>element()},
    requestAnimationFrame:fn=>{frames.set(++id,fn);return id;}, cancelAnimationFrame:i=>frames.delete(i),
    setTimeout:fn=>{timers.set(++id,fn);return id;}, clearTimeout:i=>timers.delete(i),
    MutationObserver:class {constructor(fn){this.fn=fn;observers.push(this);} observe(){} disconnect(){this.disconnected=true;}}
  });
  async function tick(){const f=[...frames.values()];frames.clear();for(const fn of f)fn();await Promise.resolve();await Promise.resolve();}
  return {root,scripts,frames,timers,observers,element,tick};
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
