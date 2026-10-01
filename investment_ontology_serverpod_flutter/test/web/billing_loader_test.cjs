const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../web/billing_loader.js'), 'utf8');
function env(protocol='http:') {
  const scripts=[], timers=new Map(), calls=[], replacements=[];
  let id=0;
  const window={};
  const location={protocol, origin:protocol+'//localhost:9110', pathname:'/membership/checkout',href:protocol+'//localhost:9110/membership/checkout'};
  vm.runInNewContext(source, {window,location,URL,
    history:{state:null, replaceState:(...args)=>replacements.push(args)},
    document:{createElement:()=>({remove(){this.removed=true;}}), head:{appendChild:s=>scripts.push(s)}},
    setTimeout:fn=>{timers.set(++id,fn);return id;}, clearTimeout:i=>timers.delete(i)});
  function install() { window.TossPayments=key=>({payment:({customerKey})=>({requestBillingAuth:async opts=>calls.push({key,customerKey,opts})})}); }
  return {window,scripts,timers,calls,replacements,install};
}
test('no SDK request before an explicit valid checkout',async()=>{
  const e=env(); assert.equal(e.scripts.length,0);
  await assert.rejects(e.window.alfinderBilling.start('bad','customer','state'));
  await assert.rejects(e.window.alfinderBilling.start('live_ck_fixture','customer','state'));
  assert.equal(e.scripts.length,0);
});
test('SDK failure allows retry and does not submit card authorization',async()=>{
  const e=env(), p=e.window.alfinderBilling.start('test_ck_fixture','customer','state');
  e.scripts[0].onerror(); await assert.rejects(p);
  assert.equal(e.calls.length,0); assert.equal(e.scripts[0].removed,true);
  const retry=e.window.alfinderBilling.start('test_ck_fixture','customer','state');
  e.install(); e.scripts[1].onload(); await retry;
  assert.equal(e.calls.length,1);
});
test('callback stays on same origin with server state and no amount from browser',async()=>{
  const e=env();e.install();
  await e.window.alfinderBilling.start('test_ck_fixture','customer','nonce');
  const opts=e.calls[0].opts;
  assert.equal(opts.method,'CARD');assert.equal(opts.successUrl,opts.failUrl);
  assert.equal(new URL(opts.successUrl).searchParams.get('state'),'nonce');
  assert.equal(new URL(opts.successUrl).origin,'http://localhost:9110');
  assert.equal(opts.amount,undefined);
  e.window.alfinderBilling.clearQuery();
  assert.equal(e.replacements[0][2],'/membership/checkout');
});
test('SDK timeout removes script and permits retry',async()=>{
  const e=env(),p=e.window.alfinderBilling.start('test_ck_fixture','customer','state');
  for(const fn of [...e.timers.values()])fn();await assert.rejects(p);
  assert.equal(e.scripts[0].removed,true);
  const retry=e.window.alfinderBilling.start('test_ck_fixture','customer','state');
  e.install();e.scripts[1].onload();await retry;assert.equal(e.calls.length,1);
});
