# Read-only local API snapshot; uses existing public endpoints, never bypasses auth.
import urllib.request,json,concurrent.futures,pathlib
out=pathlib.Path('outputs/metric-audit');out.mkdir(exist_ok=True)
def call(route,payload):
 req=urllib.request.Request('http://localhost:8080/'+route,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=90) as r:return json.load(r)
rows=[]
for offset in range(0,10000,200):
 page=call('company/list',{'limit':200,'offset':offset});rows+=page['items']
 if len(rows)>=page['total']:break
(out/'companies.json').write_text(json.dumps(rows,ensure_ascii=False))
def run(row):
 code=row['corpCode'];p=out/(code+'.json')
 try:
  x=call('financial/summary',{'corpCode':code});tmp=p.with_suffix('.tmp');tmp.write_text(json.dumps(x,ensure_ascii=False));tmp.replace(p);return None
 except Exception as e:return {'corpCode':code,'error':str(e)}
errors=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 for i,result in enumerate(pool.map(run,rows),1):
  if result:errors.append(result)
  if i%200==0:print(i,'/',len(rows),flush=True)
(out/'errors.json').write_text(json.dumps(errors));print('done',len(rows),'errors',len(errors),flush=True)
