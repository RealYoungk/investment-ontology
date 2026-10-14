/** Real Flutter browser audit. No API corpus collection or server lifecycle changes. */
const fs=require('fs');
const crypto=require('crypto');
const {execFileSync}=require('child_process');
const {chromium}=require('/Users/realyoungk/.agents/skills/gstack/node_modules/playwright');
const root=process.env.BUSINESS_UI_ROOT||'tmp/business-universe-audit-2026-10-13';
const base=process.env.BUSINESS_UI_BASE||'http://localhost:8100';
const inventory=JSON.parse(fs.readFileSync(root+'/inventory.json'));
const excluded=new Set(inventory.unmatchedCompanies.map(x=>x.corpCode));
const all=JSON.parse(fs.readFileSync(root+'/universe.json')).filter(x=>!excluded.has(x.corpCode));
const output=root+'/'+(process.env.BUSINESS_UI_RUN||'ui');fs.mkdirSync(output+'/snapshots',{recursive:true});fs.mkdirSync(output+'/screenshots',{recursive:true});
const sourceTrees=['investment_ontology_serverpod_flutter/lib','investment_ontology_serverpod_server/lib','investment_ontology_serverpod_client/lib'];
function sourceFingerprint(){const paths=[];function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=dir+'/'+e.name;if(e.isDirectory())walk(p);else if(p.endsWith('.dart'))paths.push(p);}}for(const dir of sourceTrees)walk(dir);const h=crypto.createHash('sha256');for(const p of paths.sort()){h.update(p+'\n');h.update(fs.readFileSync(p));}return h.digest('hex');}
const initialSourceFingerprint=sourceFingerprint();
const harnessFingerprint=crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex');
const ledger=output+'/ledger.jsonl';
const old=fs.existsSync(ledger)?fs.readFileSync(ledger,'utf8').split('\n').filter(Boolean).map(JSON.parse):[];
const hasPhysicalEndProof=x=>['primary','verification'].every(scan=>(x.physicalEndPaintProof||[]).some(p=>p.scan===scan&&p.before===p.after));
const latestOld=new Map(old.map(x=>[x.corpCode,x]));
const done=new Set([...latestOld.values()].filter(x=>x.status==='pass'&&(x.consoleErrors||[]).length===0&&hasPhysicalEndProof(x)&&x.sourceTreeFingerprint===initialSourceFingerprint).map(x=>x.corpCode));
const limit=Number(process.env.BUSINESS_UI_LIMIT||all.length);
const queue=all.filter(x=>!done.has(x.corpCode)).slice(0,limit);
const required=['businessContent','understanding','factTrends','factPeriods'];
const clean=s=>s.replace(/\s|\(주\)|주식회사|㈜/g,'');
const tracked=['investment_ontology_serverpod_flutter/lib/features/company_detail/widgets/business_guide_panel.dart','investment_ontology_serverpod_flutter/lib/features/company_detail/widgets/business_table_insights_panel.dart','investment_ontology_serverpod_flutter/lib/features/company_detail/widgets/business_table_history.dart','investment_ontology_serverpod_server/lib/src/ontology/disclosure/business_table_insights.dart'];
fs.writeFileSync(output+'/run-manifest.json',JSON.stringify({startedAt:new Date().toISOString(),base,targetCount:all.length,excluded:inventory.unmatchedCompanies,head:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),harnessFingerprint,sourceTreeFingerprint:initialSourceFingerprint,sourceHashes:Object.fromEntries(tracked.map(p=>[p,crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')])),viewport:{width:1440,height:1600},requiredRoutes:required},null,2));
let next=0, completed=0, aborted=false, ownedBrowser=null;
process.on('SIGTERM',()=>{aborted=true;ownedBrowser?.close().catch(()=>{});});
(async()=>{
// App lifecycle is managed by the Serverpod MCP. Wait for its existing web
// listener before dispatching company visits; never count startup refusals.
const readyStart=Date.now();while(true){try{const r=await fetch(base+'/main.dart.js');const kind=r.headers.get('content-type')||'';if(r.ok&&/javascript/.test(kind))break;}catch{}if(Date.now()-readyStart>180000)throw Error('Flutter web listener not ready after 180 seconds');await new Promise(r=>setTimeout(r,500));}
const browser=await chromium.launch({headless:true});ownedBrowser=browser;
try {
await Promise.all(Array.from({length:Number(process.env.BUSINESS_UI_WORKERS||4)},async(_,worker)=>{
 const context=await browser.newContext({viewport:{width:1440,height:1600}});
 const page=await context.newPage();page.setDefaultTimeout(45000);
 let active=null;
 page.on('pageerror',e=>{if(active){active.pageErrors.push(e.message);(active.pageErrorStacks??=[]).push(e.stack??String(e));}});
 page.on('console',msg=>{if(active && (msg.type()==='error'||/FlutterError|EXCEPTION CAUGHT|RenderFlex|overflowed|Another exception|Unhandled exception/i.test(msg.text())))active.consoleErrors.push(msg.text())});
 page.on('requestfailed',r=>{if(active&&!r.failure()?.errorText?.includes('ERR_ABORTED'))active.networkErrors.push({url:r.url(),error:r.failure()?.errorText})});
 page.on('request',r=>{if(!active||!r.url().endsWith('/disclosure/businessContent'))return;try{const v=JSON.parse(r.postData()||'{}');if(v.corpCode===active.corpCode&&v.bsnsYear!=null)active.historyRequested.add(v.bsnsYear);}catch{}});
 page.on('response',async r=>{
  if(!active||!r.url().includes(':8080/'))return;
  const a=active;let payload;try{payload=JSON.parse(r.request().postData()||'{}')}catch{return}
  if(payload.corpCode!==a.corpCode)return;
  const route=r.url().split('/').pop(),method=new URL(r.url()).pathname.slice(1);
  const record={route,method,status:r.status(),period:payload.bsnsYear??null,tab:a.currentTab||'사업',timing:r.request().timing()};a.responses.push(record);
  if(r.status()>=400){try{record.errorBody=(await r.text()).slice(0,2000);}catch{}}
  const publicReads=new Set([...required.map(x=>'disclosure/'+x),'financial/summary','governance/summary','disclosure/shareholderReturn','disclosure/sections','disclosure/table','market/priceHistory']);
  if(publicReads.has(method)){
   try{const body=await r.json();record.bodyRead=true;
    if(method==='financial/summary')a.financialCurrencies=[...new Set((body.periods||[]).flatMap(p=>(p.lines||[]).map(l=>l.currency||'KRW')))];
    if(route==='businessContent'){for(const t of body?.tableInsights||[]){for(const c of t.columns||[])a.sourceHeaderNames.add(c);if(t.topic==='researchProjects')for(const row of t.rows||[])if(row.cells?.[0])a.recordRowLabels.add(row.cells[0]);}}
    if(route==='businessContent'&&payload.bsnsYear==null){a.liveSourceProvenance={rceptNo:body.rceptNo,bsnsYear:body.bsnsYear,sourceId:body.source?.id};a.sourceProvenanceMatched=JSON.stringify(a.liveSourceProvenance)===JSON.stringify(a.goldenSourceProvenance);a.contentLoaded=true;a.tableTitles=body?.tableInsights?.map(t=>t.title)||[];a.tableCount=body?.tableInsights?.length||0;a.contentChars=body?.charCount??null;}
    if(r.status()===200){a.ready.add(route);a.completedReads.add(method);if(route==='businessContent'&&payload.bsnsYear!=null)a.historyCompleted.add(payload.bsnsYear);}
   }catch(e){record.bodyError=String(e)}
  }
 });
 // Warm the existing debug app before assigning a company; startup failures
 // are infrastructure evidence and cannot become company audit rows.
 console.log(JSON.stringify({worker,startup:'warming'}));
 await page.goto(base+'/',{waitUntil:'domcontentloaded'});
 await page.locator('flutter-view').waitFor({timeout:480000});
 await page.locator('flt-semantics-placeholder').evaluateAll(es=>es.forEach(e=>e.click()));
 console.log(JSON.stringify({worker,startup:'flutter-view-loaded'}));
 let booted=true;
 while(next<queue.length&&!aborted){
  const company=queue[next++];const url=base+'/company/'+company.corpCode+'?tab=business';
  const a={harnessFingerprint,sourceTreeFingerprint:initialSourceFingerprint,worker,corpCode:company.corpCode,name:company.name,stockCode:company.stockCode,url,startedAt:new Date().toISOString(),pageErrors:[],consoleErrors:[],networkErrors:[],responses:[],ready:new Set(),completedReads:new Set(),tableTitles:[],tabs:[],historyRequested:new Set(),historyCompleted:new Set(),sourceHeaderNames:new Set(),recordRowLabels:new Set(),currentTab:'사업'};active=a;
  const golden=JSON.parse(fs.readFileSync(root+'/api-capture/'+company.corpCode+'/disclosure-businessContent.json'));a.goldenSourceProvenance={rceptNo:golden.rceptNo,bsnsYear:golden.bsnsYear,sourceId:golden.source?.id};
 let snapshots=[];const snapshotSet=new Set();function addSnapshot(t){if(!snapshotSet.has(t)){snapshotSet.add(t);snapshots.push(t);}}
  try{
   if(!booted){await page.goto(url,{waitUntil:'domcontentloaded'});await page.locator('flutter-view').waitFor({timeout:120000});await page.locator('flt-semantics-placeholder').evaluateAll(es=>es.forEach(e=>e.click()));booted=true;}
   else {await page.evaluate(path=>{history.pushState({},'',path);window.dispatchEvent(new PopStateEvent('popstate'));},'/company/'+company.corpCode+'?tab=business');}
   await page.waitForFunction(({name,stock})=>{
    const t=document.body.innerText;const c=s=>s.replace(/\s|\(주\)|주식회사|㈜/g,'');return (c(t).includes(c(name))||(stock&&t.includes(stock)))&&t.includes('사업 구조');
   },{name:company.name,stock:company.stockCode},{timeout:60000});
   const start=Date.now();while(!required.every(r=>a.ready.has(r))||!a.contentLoaded){if(Date.now()-start>90000)throw Error('business API load gate timeout: '+[...a.ready]);await page.waitForTimeout(100)}
   if(!a.sourceProvenanceMatched){a.dataVersionChanged=true;throw Error('data-version-change: live business source differs from final API golden');}
   await page.waitForTimeout(350);
   const historyStart=Date.now();while([...a.historyRequested].some(y=>!a.historyCompleted.has(y))){if(Date.now()-historyStart>90000)throw Error('older report history read gate timeout');await page.waitForTimeout(100);}
   await page.mouse.move(1400,1350);await page.mouse.wheel(0,-100000);await page.waitForTimeout(180);
   await page.mouse.move(1380,35);await page.waitForTimeout(70);
   addSnapshot(await page.locator('body').innerText());
   await page.screenshot({path:output+'/screenshots/'+a.corpCode+'-top.png'});
   await page.mouse.move(1400,1350);
   let unchanged=0, previous='';const expandedRows=new Set();
   async function nativeInventory(){return page.locator('flt-semantics[role="button"], flt-semantics[flt-tappable]').evaluateAll((es,{titles,headers,records})=>es.filter(e=>/^(항목별 정보 \d+개|연도별 수치와 원문 근거|과제 \d+개 보기)$/.test(e.textContent.trim())&&!e.querySelector('[role="button"],[flt-tappable]')).map(e=>{
      const label=e.textContent.trim(),prior=[];let branch=e;
      for(let depth=0;branch?.parentElement&&depth<8;depth++,branch=branch.parentElement){let n=branch.previousElementSibling;for(let i=0;n&&i<120;i++,n=n.previousElementSibling)prior.push(n.textContent.trim());}
      const scope=prior.find(t=>titles.includes(t))||prior.find(t=>/차트 \d+개 기간$/.test(t))||'';
      const next=e.nextElementSibling?.textContent.trim()||'';
      const open=label==='연도별 수치와 원문 근거'?/^\d{4}년 보고서 ·/.test(next):label.startsWith('과제 ')?records.some(t=>next===t||next.startsWith(t)):headers.some(t=>next===t||next.startsWith(t));
      const r=e.getBoundingClientRect();return{id:e.id,label,scope,localNext:next.slice(0,1200),open,top:r.top,bottom:r.bottom,visible:r.top>=220&&r.bottom<=innerHeight-300};
    }),{titles:a.tableTitles,headers:[...a.sourceHeaderNames],records:[...a.recordRowLabels]});}
   async function expandVisibleRows(){
    for(let clickRound=0;clickRound<100;clickRound++){
      const triggers=await nativeInventory();
      for(const t of triggers.filter(t=>t.visible&&t.open))(a.nativeOpenObservations??=[]).push({label:t.label,scope:t.scope,localNext:t.localNext});
      const trigger=triggers.find(t=>t.visible&&!t.open);if(!trigger)break;
      const point=await page.evaluate(id=>{const e=document.getElementById(id);if(!e)return null;const r=e.getBoundingClientRect();if(r.top<220||r.bottom>innerHeight-300)return null;return{x:r.left+r.width/2,y:r.top+r.height/2};},trigger.id);
      if(!point)continue;await page.mouse.click(point.x,point.y);await page.waitForTimeout(800);
      let after;const mountStart=Date.now();
      while(true){const current=await nativeInventory();after=current.find(t=>t.id===trigger.id)||current.find(t=>t.label===trigger.label&&t.top<=point.y&&t.bottom>=point.y)||current.filter(t=>t.label===trigger.label&&t.open&&Math.abs(t.top-trigger.top)<100).sort((a,b)=>Math.abs(a.top-trigger.top)-Math.abs(b.top-trigger.top))[0];if(after?.open||Date.now()-mountStart>5000)break;await page.waitForTimeout(100);}
      const contentMounted=!!after?.open;
      (a.sourceAccordionTrace??=[]).push({...trigger,localAfter:after?.localNext||'',resolvedAfterId:after?.id,afterTop:after?.top,contentMounted});
      if(!contentMounted)throw Error('native source accordion did not expose its own content: '+trigger.label+' '+trigger.scope.slice(0,100));
      expandedRows.add(trigger.label+'|'+trigger.scope);a.expandedSourceTables=(a.sourceAccordionTrace||[]).length;
    }
   }
   a.nativeTitleCaptionsSeen=new Set();
   async function viewportGeometry(){const v=await page.locator('flt-semantics').evaluateAll((es,titles)=>{const rows=es.filter(e=>!e.querySelector('flt-semantics')&&e.textContent.trim()).map(e=>{const r=e.getBoundingClientRect();return{text:e.textContent.trim(),x:Math.round(r.x),y:Math.round(r.y),height:Math.round(r.height),width:Math.round(r.width)};}).filter(r=>r.y+r.height>220&&r.y<innerHeight);return{signature:JSON.stringify(rows.map(r=>({...r,text:r.text.slice(0,160)}))),captions:rows.filter(r=>titles.includes(r.text)).map(r=>r.text)};},a.tableTitles);for(const t of v.captions)a.nativeTitleCaptionsSeen.add(t);return v.signature;}
   async function paintEndProof(scan,step){
    // Flutter clips a giant Text semantics rectangle to the viewport, so its
    // DOM geometry can stay constant while the painted original is scrolling.
    const before=crypto.createHash('sha256').update(await page.screenshot()).digest('hex');
    await page.mouse.move(1400,1350);await page.mouse.wheel(0,700);await page.waitForTimeout(100);await expandVisibleRows();
    const after=crypto.createHash('sha256').update(await page.screenshot()).digest('hex');
    if(before!==after){a.paintRecoveredScrollCount=(a.paintRecoveredScrollCount||0)+1;return false;}
    (a.physicalEndPaintProof||=[]).push({scan,step,before,after,point:[1400,1350]});return true;
   }
   async function scrollBusiness(scan){
    // Expanding a card moves the pointer into its nested scrollable. Restore
    // the outer gutter before EVERY wheel, not only before the initial scan.
    await page.mouse.move(1400,1350);
    const jump=await page.locator('flt-semantics').evaluateAll(es=>{
      const unsafe='[role="button"],[flt-tappable],[role="cell"],[role="table"],[role="row"],[role="columnheader"],[role="rowheader"],input,button,a';
      for(const e of es){
        const r=e.getBoundingClientRect();const text=e.textContent.trim();
        if(e.querySelector('flt-semantics')||e.matches(unsafe)||e.closest(unsafe)||e.querySelector(unsafe)||text.length<5000)continue;
        if(r.top>220||r.bottom<innerHeight+1000||r.width<300)continue;
        // Keep the final 300 pixels of this same plain text inside the viewport.
        // Following captions and actionable semantic nodes remain ahead of us.
        return {delta:Math.min(20000,r.bottom-(innerHeight-300)),textLength:text.length,textPrefix:text.slice(0,120),top:r.top,bottom:r.bottom};
      }
      return null;
    });
    if(jump){(a.plainTextScrollJumps||=[]).push({scan,...jump});await page.mouse.wheel(0,jump.delta);}else await page.mouse.wheel(0,700);
   }
   // Scroll in the outer gutter so nested chart/table scrollables cannot consume
   // the wheel and create a false end-of-page signal.
   for(let step=0;step<2000;step++){
    a.scrollSteps=step+1;if(step>0)await scrollBusiness('primary');await page.waitForTimeout(70);
    await expandVisibleRows();let text=await page.locator('body').innerText();
    if(text.includes('파생상품·위험관리 펼치기')){
      const expand=page.getByRole('button',{name:'파생상품·위험관리 펼치기',exact:true}).first();
      if(await expand.count()){const r=await expand.evaluate(e=>{const x=e.getBoundingClientRect();return{x:x.left+x.width/2,y:x.top+x.height/2,visible:x.top>=220&&x.bottom<=innerHeight-300};});if(r.visible){await page.mouse.click(r.x,r.y);await page.waitForTimeout(800);text=await page.locator('body').innerText();a.riskExpanded=!text.includes('파생상품·위험관리 펼치기');}}
    }
    addSnapshot(text);const geometry=await viewportGeometry();if(geometry===previous)unchanged++;else unchanged=0;previous=geometry;if(unchanged>=2){await page.mouse.move(90,1350);await page.mouse.wheel(0,700);await page.waitForTimeout(70);const alternate=await viewportGeometry();if(alternate!==geometry){(a.outerGutterRecoveries||=[]).push({scan:'primary',step,point:[90,1350]});await expandVisibleRows();previous=await viewportGeometry();unchanged=0;}else if(await paintEndProof('primary',step))break;else{previous=await viewportGeometry();unchanged=0;}}
   }
   a.scrollExhausted=unchanged>=2;
   // Verify the current native open state again throughout the page. No union
   // of transient ids/captions can masquerade as a permanent unvisited card.
   await page.mouse.move(1400,1350);await page.mouse.wheel(0,-1000000);await page.waitForTimeout(180);
   let verifyPrevious='',verifyUnchanged=0;a.nativeAccordionsUnopened=[];
   for(let step=0;step<2000;step++){
    if(step>0)await scrollBusiness('verification');await page.waitForTimeout(70);
    await expandVisibleRows();const current=await nativeInventory();a.nativeAccordionsUnopened.push(...current.filter(t=>t.visible&&!t.open));
    const text=await page.locator('body').innerText();addSnapshot(text);const geometry=await viewportGeometry();if(geometry===verifyPrevious)verifyUnchanged++;else verifyUnchanged=0;verifyPrevious=geometry;if(verifyUnchanged>=2){await page.mouse.move(90,1350);await page.mouse.wheel(0,700);await page.waitForTimeout(70);const alternate=await viewportGeometry();if(alternate!==geometry){(a.outerGutterRecoveries||=[]).push({scan:'verification',step,point:[90,1350]});await expandVisibleRows();verifyPrevious=await viewportGeometry();verifyUnchanged=0;}else if(await paintEndProof('verification',step))break;else{verifyPrevious=await viewportGeometry();verifyUnchanged=0;}}
   }
   a.nativeFinalScanExhausted=verifyUnchanged>=2;
   await page.mouse.move(1380,35);await page.waitForTimeout(70);
   await page.screenshot({path:output+'/screenshots/'+a.corpCode+'-bottom.png'});
   const text=[...new Set(snapshots)].join('\n\n--- SCROLL VIEW ---\n');
   a.nameVisible=clean(text).includes(clean(company.name));a.stockVisible=!!company.stockCode&&text.includes(company.stockCode);
   a.businessHeading=text.includes('사업 구조');a.revenueHeading=text.includes('매출 구성');
   a.sourceTableTitlesSeen=a.tableTitles.filter(t=>a.nativeTitleCaptionsSeen.has(t));
   a.sourceTableTitlesUnseen=a.tableTitles.filter(t=>!a.nativeTitleCaptionsSeen.has(t));
   a.errorText=text.match(/(?:불러오지 못했습니다|불러오지 못했어요|오류가 발생|RenderFlex|Exception|ErrorWidget|저장된 사업 원문이 없습니다)/g)||[];
   a.snapshot=output+'/snapshots/'+a.corpCode+'.txt';fs.writeFileSync(a.snapshot,text);
   a.visited=true;
   a.sourceCardsRendered=a.sourceTableTitlesUnseen.length===0;
   a.nativeSourceAccordionCount=(a.sourceAccordionTrace||[]).length;
   a.allNativeAccordionsExpanded=a.nativeAccordionsUnopened.length===0&&a.nativeFinalScanExhausted&&(a.sourceAccordionTrace||[]).every(t=>t.contentMounted);
   a.sourceAccordionScope='current native local open state scanned across all viewports; transient ids/captions are evidence only, not inventory';
   a.expandedSourceAccordionIds=[...expandedRows];
   // Visit every available native company tab. Overview is the current 사업
   // alias; unavailable source states are allowed, read failures are not.
   const definitions=[
    {name:'재무',urlValue:'financials',api:'financial/summary',heading:/매출액|손익|현금흐름|정기보고서 API 재무 데이터|아직 재무·시세|사업보고서 재무가 없습니다|공식 원문을 확인/},
    {name:'지배구조',urlValue:'governance',api:'governance/summary',heading:/정관은 어떻게 바뀌었나요|보유 현황|주주·출자 관계망|경영진 명단|정기보고서 주요정보를 받지 않았습니다/},
    {name:'주주환원',urlValue:'returns',api:'disclosure/shareholderReturn',heading:/배당|자기주식|주식 총수|주식 수량/},
    {name:'소식·공시',urlValue:'disclosures',api:null,heading:/관련 소식|정기보고서 · 연도별 공시|최근 소식/},
   ];
   for(const definition of definitions){
    await page.mouse.move(1400,1350);await page.mouse.wheel(0,-1000000);await page.waitForTimeout(120);
    const matches=await page.locator('flt-semantics[role="button"], flt-semantics[flt-tappable]').evaluateAll((es,name)=>es.filter(e=>e.textContent.trim()===name&&!e.querySelector('[role="button"],[flt-tappable]')).map(e=>e.id),definition.name);
    if(!matches.length){a.tabs.push({name:definition.name,present:false});continue;}
    a.currentTab=definition.name;
    const check={name:definition.name,present:true,startedAt:new Date().toISOString()};
    await page.locator('[id="'+matches[0]+'"]').evaluate(e=>e.click());
    await page.waitForFunction(tab=>new URL(location.href).searchParams.get('tab')===tab,definition.urlValue,{timeout:15000});
    const gateStart=Date.now();let tabText='';
    while(true){tabText=await page.locator('body').innerText();
      const currencyNotice=definition.api==='financial/summary'&&(a.financialCurrencies||[]).length>1&&tabText.includes(a.financialCurrencies.join('·')+' 표시 통화가 달라 추이를 합산하지 않습니다.');
      if((definition.heading.test(tabText)||currencyNotice)&&(!definition.api||a.completedReads.has(definition.api))){if(currencyNotice)check.currencyMismatchVerified=a.financialCurrencies;break;}
      if(/불러오지 못했|오류가 발생/.test(tabText))throw Error('tab '+definition.name+' read failure: '+tabText.slice(-800));
      if(Date.now()-gateStart>60000)throw Error('tab '+definition.name+' loaded/heading gate timeout');
      await page.waitForTimeout(100);
    }
    if(definition.name==='소식·공시'){
      const disclosureTrigger=page.getByRole('button',{name:'공시 항목과 연도별 원문 표 보기',exact:true}).first();
      if(await disclosureTrigger.count()){
        await disclosureTrigger.evaluate(e=>e.click());check.disclosureRawOpened=true;
        const waitStart=Date.now();while(!a.completedReads.has('disclosure/table')){if(Date.now()-waitStart>60000)throw Error('raw disclosure table load timeout');await page.waitForTimeout(100);}
      }
    }
    let previousTab='',stopped=0;
    const pieces=[tabText];
    for(let step=0;step<24;step++){
      await page.mouse.move(1400,1350);await page.mouse.wheel(0,1100);await page.waitForTimeout(70);
      const body=await page.locator('body').innerText();pieces.push(body);
      const geometry=await viewportGeometry();if(geometry===previousTab)stopped++;else stopped=0;previousTab=geometry;if(stopped>=2)break;
    }
    const union=[...new Set(pieces)].join('\n\n--- SCROLL VIEW ---\n');
    check.headingConfirmed=definition.heading.test(union)||(check.currencyMismatchVerified?.length>1&&union.includes(check.currencyMismatchVerified.join('·')+' 표시 통화가 달라 추이를 합산하지 않습니다.'));
    check.errors=union.match(/불러오지 못했(?:습니다|어요)|오류가 발생|RenderFlex|Exception|ErrorWidget/g)||[];
    check.status=check.headingConfirmed&&check.errors.length===0?'pass':'fail';
    check.snapshot=output+'/snapshots/'+a.corpCode+'-'+definition.urlValue+'.txt';fs.writeFileSync(check.snapshot,union);
    await page.mouse.move(1380,35);await page.waitForTimeout(70);
    await page.screenshot({path:output+'/screenshots/'+a.corpCode+'-'+definition.urlValue+'.png'});
    check.url=page.url();check.endedAt=new Date().toISOString();a.tabs.push(check);
   }
   a.allPresentTabsPassed=a.tabs.every(t=>!t.present||t.status==='pass');
   a.currentTab=null;
   a.frameworkErrors=a.consoleErrors.filter(e=>/FlutterError|EXCEPTION CAUGHT|RenderFlex|overflowed|Another exception|Unhandled exception/i.test(e));
   a.status=a.sourceProvenanceMatched&&(a.nameVisible||a.stockVisible)&&a.businessHeading&&a.pageErrors.length===0&&a.consoleErrors.length===0&&a.frameworkErrors.length===0&&a.errorText.length===0&&a.sourceCardsRendered&&a.scrollExhausted&&a.allPresentTabsPassed&&a.allNativeAccordionsExpanded?'pass':'fail';
  }catch(e){a.status='fail';a.failure=String(e);
   if(/Target crashed|Target page, context or browser has been closed|ERR_CONNECTION_REFUSED|ERR_EMPTY_RESPONSE/.test(a.failure)){a.status='infrastructure-error';a.visited=false;aborted=true;}
   else {a.visited=true;}try{await page.screenshot({path:output+'/screenshots/'+a.corpCode+'-failure.png'})}catch{}}
  finally {if(a.nativeTitleCaptionsSeen)a.nativeTitleCaptionsSeen=[...a.nativeTitleCaptionsSeen];delete a.sourceHeaderNames;delete a.recordRowLabels;a.historyRequested=[...a.historyRequested];a.historyCompleted=[...a.historyCompleted];a.ready=[...a.ready];a.completedReads=[...a.completedReads];a.endedAt=new Date().toISOString();fs.appendFileSync(ledger,JSON.stringify(a)+'\n');completed++;active=null;if(completed%5===0||a.status!=='pass')console.log(JSON.stringify({completed,planned:queue.length,worker,name:a.name,status:a.status,failure:a.failure,errors:a.consoleErrors.slice(0,1)}));}
 }
 await context.close();
}));
} finally {await browser.close();}
fs.writeFileSync(output+'/source-fingerprint-final.json',JSON.stringify({initial:initialSourceFingerprint,final:sourceFingerprint(),stable:initialSourceFingerprint===sourceFingerprint(),endedAt:new Date().toISOString()},null,2));
console.log(JSON.stringify({finished:!aborted,aborted,attempted:completed,excluded:excluded.size,totalTarget:all.length}));
})().catch(e=>{console.error(e);process.exitCode=1});
