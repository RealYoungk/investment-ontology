const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../../web/membership_policy_status.js'),'utf8');
async function run(offer,ok=true){const node={textContent:'출시 준비 중'};let request;vm.runInNewContext(source,{document:{querySelector:()=>node},fetch:async(url,options)=>{request={url,options};return{ok,json:async()=>offer};}});await new Promise(setImmediate);return{node,request};}
test('policy changes only for a successful live server offer',async()=>{
 for(const offer of [null,{}, {paymentAvailable:false,isTest:false},{paymentAvailable:true,isTest:true}])assert.equal((await run(offer)).node.textContent,'출시 준비 중');
 assert.equal((await run({paymentAvailable:true,isTest:false},false)).node.textContent,'출시 준비 중');
 const result=await run({paymentAvailable:true,isTest:false});assert.match(result.node.textContent,/유료 멤버십/);assert.equal(result.request.options.credentials,'omit');assert.equal(result.request.options.cache,'no-store');
});
