import json,pathlib
root=pathlib.Path('outputs/metric-source-audit'); errors=[];checked=0;quotes=0
for line in open(root/'market.jsonl'):
 r=json.loads(line); a=json.loads((root/'api'/(r['corpCode']+'.json')).read_text())['market'];checked+=1
 if a['baseDate'][:10]!=r['date'][:10] or str(a.get('marketCap'))!=str(r.get('marketCap')):errors.append([r['corpCode'],'market total/date'])
 expected={x['securityId']:x for x in r['quotes']};actual={x['securityId']:x for x in a['securities']}
 if set(expected)!=set(actual):errors.append([r['corpCode'],'security coverage'])
 for sid in set(expected)&set(actual):
  for k in ['marketCap','closePrice','listedShares']:
   quotes+=1
   if str(expected[sid].get(k))!=str(actual[sid].get(k)):errors.append([r['corpCode'],sid,k])
(root/'market-check.json').write_text(json.dumps({'companies':checked,'quoteFields':quotes,'mismatches':errors},indent=2));print(checked,quotes,len(errors));print(errors[:5])
if errors:raise SystemExit(1)
