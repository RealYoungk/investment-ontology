const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const code = readFileSync(require('node:path').join(__dirname,'../web/push_bridge.js'),'utf8');
(async () => {
  let calls=0, subscribed=0, removed=0,closed=0;let sub=null;let owner='old';
  const reg={pushManager:{getSubscription:async()=>sub,subscribe:async options=>{assert.equal(options.userVisibleOnly,true);sub={endpoint:'https://fcm.googleapis.com/test',toJSON:()=>({endpoint:'https://fcm.googleapis.com/test',keys:{p256dh:'test',auth:'test'}}),unsubscribe:async()=>{removed++;sub=null;return true;}};subscribed++;return sub;}},getNotifications:async()=>[{close:()=>closed++}]};
  const context={window:{isSecureContext:true,PushManager:{},Notification:{}},navigator:{serviceWorker:{register:async()=>reg,ready:Promise.resolve(reg)}},Notification:{permission:'default',requestPermission:()=>{calls++;return Promise.resolve('granted');}},localStorage:{getItem:()=>owner,setItem:(_,v)=>owner=v,removeItem:()=>owner=null},document:{baseURI:'https://example.com/'},URL,Uint8Array,atob:v=>Buffer.from(v,'base64').toString('binary')};
  vm.runInNewContext(code,context); const api=context.window.alfinderPush;
  const enabled=api.enable('AQID','new');assert.equal(calls,1,'permission request must be synchronous');
  await enabled;assert.equal(subscribed,1);assert.equal(owner,'new');assert.equal(await api.status(),'enabled');
  await api.disable();assert.equal(removed,1);assert.equal(owner,null);assert.ok(closed>=1);assert.equal(await api.endpoint(),null);
  context.Notification.permission='denied';context.Notification.requestPermission=()=>Promise.resolve('denied');await assert.rejects(api.enable('AQID','new'));assert.equal(subscribed,1);
  context.window.isSecureContext=false;assert.equal(await api.status(),'unsupported');
  console.log('Push bridge: permission gesture, subscription, logout, denied and unsupported cases passed');
})().catch(e=>{console.error(e);process.exitCode=1});
