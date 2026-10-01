'use strict';
document.querySelector('#run').onclick = async () => {
 const results=[];
 const cases=['unselected','reject','allow','withdraw','missing','delay','error','unknown','reopen','paidBefore','paidPending'];
 for(const scenario of cases){
  const frame=document.createElement('iframe');frame.style.width='800px';document.body.append(frame);
  const doc=frame.contentDocument,w=frame.contentWindow;
  doc.body.innerHTML='<div id="slot" style="width:728px;height:100px"></div>';
  let scripts=0,cmpScripts=0,pushes=0,listener,choice=scenario==='reject'?false:scenario==='unselected'?null:true;
  const timers=new Map();let timer=0;
  w.setTimeout=(fn)=>{timers.set(++timer,fn);return timer;};w.clearTimeout=id=>timers.delete(id);
  w.alfinderAdConsent={choice:()=>choice,request:async()=>choice===true};
  w.adsbygoogle={push:()=>{pushes++;doc.querySelector('ins')?.setAttribute('data-ad-status','filled');}};
  w.googlefc={callbackQueue:scenario==='missing'?[]:{push:item=>item.CONSENT_API_READY()}};
  w.__tcfapi=(command,_v,cb)=>{if(command!=='addEventListener')return;listener=cb;
   if(scenario==='delay')return;
   cb(scenario==='error'?null:scenario==='unknown'?{eventStatus:'tcloaded'}:{eventStatus:'tcloaded',gdprApplies:true,cmpId:300,listenerId:1,purpose:{consents:{1:true}},vendor:{consents:{755:true}}},scenario!=='error');};
  const append=doc.head.appendChild.bind(doc.head);
  doc.head.appendChild=el=>{if(el.src?.includes('fundingchoicesmessages')){cmpScripts++;queueMicrotask(()=>el.onload());return el;}if(el.src?.includes('googlesyndication')){scripts++;if(scenario!=='paidPending')queueMicrotask(()=>el.onload());return el;}return append(el);};
  const source=await fetch('../../investment_ontology_serverpod_flutter/web/ad_loader.js').then(r=>r.text());
  const script=doc.createElement('script');script.textContent=source;append(script);
  const slot=doc.querySelector('#slot');let p;
  if(scenario!=='paidBefore')p=w.alfinderAds.mount(slot,'ca-pub-4209548390738211','3239020318',true);
  await new Promise(r=>setTimeout(r,70));
  if(scenario==='withdraw'){choice=false;w.dispatchEvent(new w.Event('alfinder-ad-consent'));}
  if(scenario==='reopen')listener({eventStatus:'cmpuishown'},true);
  if(scenario==='paidPending')w.alfinderAds.dispose(slot);
  if(['missing','delay','unknown'].includes(scenario))for(const fn of [...timers.values()])fn();
  if(scenario==='delay')listener({eventStatus:'tcloaded',gdprApplies:false},true);
  await new Promise(r=>setTimeout(r,20));
  const expectedPush=['allow','withdraw','reopen'].includes(scenario)?1:0;
  const expectedScripts=['allow','withdraw','reopen','paidPending'].includes(scenario)?1:0;
  const expectedCmp=['unselected','reject','paidBefore'].includes(scenario)?0:1;
  const result={scenario,cmpScripts,scripts,pushes,slots:slot.children.length,pass:cmpScripts===expectedCmp&&scripts===expectedScripts&&pushes===expectedPush&&(scenario==='allow'||slot.children.length===0)};
  results.push(result);w.alfinderAds.dispose(slot);frame.remove();
 }
 document.querySelector('#result').textContent=JSON.stringify({passed:results.filter(r=>r.pass).length,total:results.length,results},null,2);
};
