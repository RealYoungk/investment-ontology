#!/usr/bin/env node
// Render trusted local TSX with static, keyboard-accessible glossary disclosures.
// The source repository is never modified, and its app shell/auth code is not run.
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const source = path.resolve(process.argv[2], 'apps/research');
const dest = path.resolve(process.argv[3]);
const localRequire = Module.createRequire(path.join(source,'package.json'));
const ts = localRequire('typescript');
const React = localRequire('react');
const {renderToStaticMarkup} = localRequire('react-dom/server');
const originalLoad = Module._load;
const originalResolve = Module._resolveFilename;
Module._resolveFilename = function(request,parent,...args) {
  if(request.startsWith('@/')) request=path.join(source,request.slice(2));
  return originalResolve.call(this,request,parent,...args);
};
Module._load = function(request,parent,isMain) {
  if(request==='@/components/report/report-article') return {ReportArticle:({children})=>React.createElement('article',null,children)};
  if(request==='@/components/tooltip') return {Tooltip:({desc,img,children})=>React.createElement('details',{className:'report-glossary'},React.createElement('summary',null,children),React.createElement('span',{className:'report-glossary-body'},img?React.createElement('img',{src:img,alt:''}):null,desc))};
  if(request==='@/components/charts/pie-chart') return {PieChart:({slices})=>React.createElement('div',{className:'report-composition',role:'img','aria-label':slices.map(s=>`${s.label} ${s.value}%`).join(', ')},slices.map((s,i)=>React.createElement('div',{key:i,className:'report-composition-row'},React.createElement('div',null,React.createElement('span',null,s.label),React.createElement('strong',null,`${s.value}%${s.amount ? ' · '+s.amount : ''}`)),React.createElement('div',{className:'report-composition-track'},React.createElement('div',{style:{width:Math.max(0,Math.min(100,s.value))+'%',background:'#537898',height:'8px',borderRadius:'4px'}})))))};
  if(request==='next/link') return {__esModule:true,default:({children,href,...props})=>React.createElement('a',{...props,href},children)};
  if(request==='next/image') return {__esModule:true,default:({src,alt,...props})=>React.createElement('img',{src,alt})};
  return originalLoad.call(this,request,parent,isMain);
};
for(const ext of ['.ts','.tsx']) require.extensions[ext]=function(module,filename){
  const code=fs.readFileSync(filename,'utf8');
  const result=ts.transpileModule(code,{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,esModuleInterop:true,target:ts.ScriptTarget.ES2022}});
  module._compile(result.outputText,filename);
};
fs.mkdirSync(dest,{recursive:true});
let count=0;
for(const slug of fs.readdirSync(path.join(source,'app/reports'))){
  const file=path.join(source,'app/reports',slug,'page.tsx');
  if(!fs.existsSync(file))continue;
  try{
    const Page=require(file).default;
    fs.writeFileSync(path.join(dest,slug+'.html'),renderToStaticMarkup(React.createElement(Page)));
    count++;
  }catch(error){console.error(slug,error.message);process.exitCode=1;}
}
console.log(`Rendered ${count} report bodies with static glossary.`);
