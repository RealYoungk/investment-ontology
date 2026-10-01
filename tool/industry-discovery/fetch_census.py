"""Read every listed issuer through existing public Serverpod endpoints.
No DART requests, paid AI, database writes, or credentials. Two requests at once.
Use a fresh output directory for a new snapshot; --resume retries missing files.
"""
import argparse, concurrent.futures, json, pathlib, urllib.request
p=argparse.ArgumentParser()
p.add_argument('--api',default='http://localhost:8080')
p.add_argument('--output',required=True)
p.add_argument('--resume',action='store_true')
a=p.parse_args();base=pathlib.Path(a.output);base.mkdir(parents=True,exist_ok=True)
def rpc(method,args):
 req=urllib.request.Request(a.api.rstrip('/')+'/'+method,data=json.dumps(args).encode(),headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=60) as r:return json.load(r)
snapshot=base/'snapshot.json'
if a.resume and snapshot.exists():data=json.loads(snapshot.read_text())
else:
 if any(base.iterdir()):raise SystemExit('Use an empty directory or --resume')
 data=rpc('industry/browse',{});snapshot.write_text(json.dumps(data,ensure_ascii=False))
companies={c['corpCode']:c for c in data['activities'] if c.get('classificationBasis') in ['ksic','unclassified']}
assert len(companies)==data['listedCompanyCount']
docs=base/'documents';docs.mkdir(exist_ok=True)
def fetch(item):
 code,c=item;path=docs/(code+'.json')
 if a.resume and path.exists():return
 doc=rpc('disclosure/businessContent',{'corpCode':code})
 row={'corpCode':code,'name':c['companyName'],'industryCode':c.get('industryCode'),'documentAvailable':doc is not None,'text':''}
 if doc:row.update(year=doc['bsnsYear'],receipt=doc['rceptNo'],title=doc['title'],text='\n'.join('## '+s['title']+'\n'+s['text'] for s in doc['sections']))
 path.write_text(json.dumps(row,ensure_ascii=False))
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for i,_ in enumerate(pool.map(fetch,companies.items()),1):
  if i%250==0:print(f'{i}/{len(companies)}',flush=True)
rows=[json.loads((docs/(code+'.json')).read_text()) for code in companies]
(base/'corpus.json').write_text(json.dumps(rows,ensure_ascii=False))
print(f'Complete: {len(rows)} issuer fetch results')
