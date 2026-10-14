#!/usr/bin/env python3
"""Read-only public API corpus capture. Selection is explicit, reproducible JSON.
No collection/import/admin endpoint, database connection or paid model call.
"""
import argparse, concurrent.futures, json, pathlib, urllib.request

def call(base, route, payload):
    req = urllib.request.Request(base.rstrip('/')+'/'+route, data=json.dumps(payload).encode(), headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=90) as response:
        return json.load(response)

def main():
    p=argparse.ArgumentParser();p.add_argument('selection',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);p.add_argument('--api',default='http://localhost:8080');args=p.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    selection=json.loads(args.selection.read_text()); ledger=[]
    routes=['financial/summary','governance/summary','disclosure/shareholderReturn','disclosure/sections','disclosure/factTrends','disclosure/factPeriods','disclosure/understanding','disclosure/businessContent']
    def fetch(company):
        code=company['corpCode'];directory=args.output/code;directory.mkdir(exist_ok=True);result={'company':company,'errors':[]}
        for route in routes:
            path=directory/(route.replace('/','-')+'.json')
            try:
                data=json.loads(path.read_text()) if path.exists() else call(args.api,route,{'corpCode':code})
                path.write_text(json.dumps(data,ensure_ascii=False));result[route]=data
            except Exception as error:result['errors'].append({'route':route,'error':str(error)})
        current=result.get('disclosure/businessContent');periods=result.get('disclosure/factPeriods') or []
        annuals=[x['bsnsYear'] for x in periods if x['reportCode']=='annual']
        if annuals:
            year=max(annuals);path=directory/f'annual-{year}.json'
            try:
                data=json.loads(path.read_text()) if path.exists() else call(args.api,'disclosure/businessContent',{'corpCode':code,'bsnsYear':year})
                path.write_text(json.dumps(data,ensure_ascii=False));result['annual']=data
            except Exception as error:result['errors'].append({'route':'annual','error':str(error)})
        (directory/'snapshot.json').write_text(json.dumps(result,ensure_ascii=False));return result
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for i,result in enumerate(pool.map(fetch,selection),1):
            ledger.append(result);print(f"{i}/{len(selection)} {result['company']['name']} errors={len(result['errors'])}",flush=True)
    corpus=[]
    for snapshot in ledger:
        seen=set()
        for role in ['disclosure/businessContent','annual']:
            doc=snapshot.get(role)
            if not doc or doc['rceptNo'] in seen:continue
            seen.add(doc['rceptNo'])
            report_name=(snapshot.get('disclosure/understanding') or {}).get('reportName','') if role!='annual' else f"사업보고서 ({doc['bsnsYear']}.12)"
            report_code=(snapshot.get('disclosure/understanding') or {}).get('reportCode','annual') if role!='annual' else 'annual'
            text='\n'.join('## '+s['title']+'\n'+s['text'] for s in doc['sections'])
            corpus.append({'corpCode':snapshot['company']['corpCode'],'name':snapshot['company']['name'],'industryCode':snapshot['company'].get('industryCode'),'year':doc['bsnsYear'],'receipt':doc['rceptNo'],'role':role,'reportCode':report_code,'reportPeriod':report_name,'text':text,'storedFacts':snapshot.get('disclosure/factTrends') or [],'source':doc['source']})
    (args.output/'corpus.jsonl').write_text('\n'.join(json.dumps(d,ensure_ascii=False) for d in corpus)+'\n')
    (args.output/'capture-summary.json').write_text(json.dumps({'companies':len(ledger),'documents':len(corpus),'errors':[{'corpCode':s['company']['corpCode'],**e} for s in ledger for e in s['errors']]},ensure_ascii=False,indent=2))
    print(f"Captured {len(ledger)} companies, {len(corpus)} distinct documents",flush=True)
if __name__=='__main__':main()
