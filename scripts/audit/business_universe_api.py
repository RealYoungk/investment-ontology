#!/usr/bin/env python3
"""Explicit stored-original cohort, read-only public API capture and source checks."""
import argparse, concurrent.futures, json, math, pathlib, re, time, urllib.request, urllib.error
ROUTES=['financial/summary','governance/summary','disclosure/shareholderReturn','disclosure/sections','disclosure/factTrends','disclosure/factPeriods','disclosure/understanding','disclosure/businessContent']

def call(base, route, payload):
    request=urllib.request.Request(base.rstrip('/')+'/'+route,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=90) as response:return json.load(response)

def error_details(error, seconds):
    details={'error':str(error),'seconds':round(seconds,3)}
    if isinstance(error, urllib.error.HTTPError):
        details['httpStatus']=error.code
        body=error.read(4097)
        details['responseBody']=body[:4096].decode('utf-8',errors='replace')
        details['responseBodyTruncated']=len(body)>4096
    return details

def main():
    p=argparse.ArgumentParser();p.add_argument('--root',type=pathlib.Path,default=pathlib.Path('tmp/business-universe-audit-2026-10-13'));p.add_argument('--api',default='http://localhost:8080');p.add_argument('--workers',type=int,default=6);p.add_argument('--resume',action='store_true');p.add_argument('--verify-captured',action='store_true');p.add_argument('--refresh-findings',action='store_true');p.add_argument('--selection',type=pathlib.Path);p.add_argument('--refresh-route',action='append',choices=ROUTES,default=[]);args=p.parse_args()
    if not 1<=args.workers<=6:p.error('workers must be 1..6')
    output=args.root/'api-capture';output.mkdir(parents=True,exist_ok=True)
    inventory=json.loads((args.root/'inventory.json').read_text());excluded={d['corpCode'] for d in inventory['unmatchedCompanies']}
    selection=[d for d in json.loads((args.root/'universe.json').read_text()) if d['corpCode'] not in excluded]
    if args.selection:
        codes={d['corpCode'] if isinstance(d,dict) else d for d in json.loads(args.selection.read_text())}
        selection=[d for d in selection if d['corpCode'] in codes]
    if args.verify_captured:selection=[d for d in selection if (output/d['corpCode']/'snapshot.json').exists()]
    if args.refresh_findings:
        filtered=[]
        for d in selection:
            path=output/d['corpCode']/'snapshot.json'
            if path.exists():
                prior=json.loads(path.read_text())
                if prior.get('errors') or (prior.get('disclosure/understanding') or {}).get('status')=='no_document':filtered.append(d)
        selection=filtered
    if not selection:
        print(json.dumps({'companies':0,'status':'no_selected_companies','note':'existing audit artifacts preserved'}));return
    corpus=args.root/'capture/corpus.jsonl';offsets={}
    with corpus.open('rb') as f:
        while True:
            offset=f.tell();line=f.readline()
            if not line:break
            d=json.loads(line);offsets.setdefault(d['corpCode'],[]).append(offset)
    missing=[d['corpCode'] for d in selection if d['corpCode'] not in offsets]
    if missing:raise RuntimeError(f'No stored originals for selected cohort: {missing}')
    def fetch(company):
        code=company['corpCode'];directory=output/code;directory.mkdir(exist_ok=True)
        prior=json.loads((directory/'snapshot.json').read_text()) if (args.refresh_findings or args.verify_captured) else {}
        force_routes={e['route'] for e in prior.get('errors',[])} | set(args.refresh_route)
        if (prior.get('disclosure/understanding') or {}).get('status')=='no_document':force_routes.add('disclosure/understanding')
        snapshot={'company':company,'errors':[],'checks':[],'routeStates':{},'sourceCheckStates':{'exact':0,'composed_source_lines':0,'mismatch':0,'legacy_annual_period_confirmed':0,'derived_inventory_count_confirmed':0}}
        with corpus.open('rb') as f:
            originals=[]
            for offset in offsets[code]:f.seek(offset);originals.append(json.loads(f.readline()))
        original_texts=[d['text'] for d in originals];document_map={d['documentId']:d for d in originals}
        for route in ROUTES:
            path=directory/(route.replace('/','-')+'.json');started=time.monotonic()
            try:
                if args.verify_captured and (not path.exists() or any(e['route']==route for e in prior.get('errors',[]))):
                    prior=json.loads((directory/'snapshot.json').read_text())
                    snapshot['errors'].extend(e for e in prior.get('errors',[]) if e['route']==route)
                    snapshot['routeStates'][route]={'state':'api_error' if any(e['route']==route for e in snapshot['errors']) else 'not_captured'}
                    continue
                use_cache=(args.resume or args.verify_captured or args.refresh_findings or bool(args.refresh_route)) and path.exists() and route not in force_routes
                data=json.loads(path.read_text()) if use_cache else call(args.api,route,{'corpCode':code})
                path.write_text(json.dumps(data,ensure_ascii=False));snapshot[route]=data
                state='null' if data is None else 'empty' if data==[] or data=={} else 'response'
                snapshot['routeStates'][route]={'state':state,'seconds':round(time.monotonic()-started,3),'source':'cache' if use_cache else 'public_api'}
            except Exception as error:
                snapshot['errors'].append({'route':route,**error_details(error,time.monotonic()-started)});snapshot['routeStates'][route]={'state':'api_error','seconds':round(time.monotonic()-started,3),'source':'public_api'}
        def issue(kind,path,detail):snapshot['checks'].append({'kind':kind,'path':path,'detail':detail})
        validated_counts=set();numeric_source_cache={}
        def walk(value,path,source=None):
            if isinstance(value,dict):
                document=document_map.get(value.get('documentId'));source=document['text'] if document else source
                evidence=value.get('evidence')
                if isinstance(evidence,str) and evidence and path.startswith(('disclosure/understanding','disclosure/factTrends','disclosure/businessContent')):
                    texts=[source] if source else original_texts
                    if any(evidence in text for text in texts): snapshot['sourceCheckStates']['exact']+=1
                    elif any(all(line in text for line in evidence.splitlines() if line.strip()) for text in texts):snapshot['sourceCheckStates']['composed_source_lines']+=1
                    else:
                        snapshot['sourceCheckStates']['mismatch']+=1
                        issue('evidence_mismatch',path,evidence[:240])
                if value.get('__className__')=='BusinessTableInsight':
                    source=evidence if isinstance(evidence,str) else source
                    if value.get('topic')=='intellectualPropertySource':
                        categories=[]
                        for row in value.get('rows',[]):
                            raw=row.get('cells',[])
                            parts=raw[0].split('|') if len(raw)==1 else raw
                            if len(parts)>1:categories.append(re.sub(r'\s+','',parts[1]))
                        for measure in value.get('measures',[]):
                            if measure.get('metric')=='공시 목록 건수' and measure.get('unit')=='건':
                                count=categories.count(re.sub(r'\s+','',measure.get('label','')))
                                if count==measure.get('value'):
                                    validated_counts.add(id(measure));snapshot['sourceCheckStates']['derived_inventory_count_confirmed']+=1
                                else:issue('derived_inventory_count_mismatch',path,{'label':measure.get('label'),'rows':count,'value':measure.get('value')})
                    columns=value.get('columns',[])
                    for row in value.get('rows',[]):
                        if len(row.get('cells',[]))!=len(columns):issue('ragged_row',path,{'columns':len(columns),'cells':len(row.get('cells',[]))})
                if value.get('__className__')=='BusinessTableMeasure':
                    for key in ['label','metric','period','unit']:
                        if not value.get(key):issue('missing_measure_field',path,key)
                    if not isinstance(value.get('value'),(int,float)):issue('non_numeric_measure',path,str(value.get('value')))
                    elif source and id(value) not in validated_counts:
                        if source not in numeric_source_cache:
                            tokens=re.findall(r'[-+△−]?\d[\d,]*(?:\.\d+)?',source)
                            numeric_grammar=r'[-+△−]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?'
                            valid_tokens=[t.rstrip(',') for t in tokens if re.fullmatch(numeric_grammar,t.rstrip(','))]
                            vals={abs(float(t.replace(',','').replace('△','-').replace('−','-'))) for t in valid_tokens}
                            vals={v for v in vals if math.isfinite(v)}
                            malformed=[t for t in tokens if not re.fullmatch(numeric_grammar,t.rstrip(','))]
                            bad_values={}
                            for t in malformed:bad_values.setdefault(abs(float(t.replace(',','').replace('△','-').replace('−','-'))),[]).append(t)
                            numeric_source_cache[source]=(vals,bad_values)
                        vals,bad_values=numeric_source_cache[source]
                        target=abs(value['value'])
                        valid_match=target in vals or any(abs(v-target)<=1e-8*max(1,abs(v)) for v in vals)
                        if not valid_match:
                            merged_matches=bad_values.get(target,[])
                            if not merged_matches:
                                merged_matches=[t for v,raw in bad_values.items() if abs(v-target)<=1e-8*max(1,target) for t in raw]
                            if merged_matches:issue('merged_source_number_measure',path,{'value':value['value'],'tokens':merged_matches[:3]})
                            issue('measure_value_absent_from_evidence',path,value['value'])
                if value.get('__className__')=='DocumentFact':
                    if not value.get('asOf'):
                        legacy=(value.get('id') in [13,14,15] and value.get('documentId')==26 and value.get('sourceId')==52639 and document and document.get('receipt')=='20260312000217' and document.get('reportCode')=='annual' and document.get('year')==2025 and re.search(r'제6기.*시장점유율은.*2025년',document['text']))
                        if legacy:snapshot['sourceCheckStates']['legacy_annual_period_confirmed']+=1
                        else:issue('missing_fact_period',path,value.get('id'))
                    if not value.get('unit'):issue('missing_fact_unit',path,value.get('id'))
                    if document is None:issue('fact_source_not_in_active_corpus',path,value.get('documentId'))
                for key,item in value.items():walk(item,path+'/'+key,source)
            elif isinstance(value,list):
                for index,item in enumerate(value):walk(item,f'{path}/{index}',source)
            elif isinstance(value,float) and not math.isfinite(value):issue('nonfinite',path,str(value))
        for route in ROUTES:
            if route in snapshot:walk(snapshot[route],route)
        understanding=snapshot.get('disclosure/understanding');content=snapshot.get('disclosure/businessContent')
        if isinstance(understanding,dict):
            snapshot['understandingStatus']=understanding.get('status','unknown')
            snapshot['fallbackOrPending']=understanding.get('status')!='ready'
            if understanding.get('status')=='no_document' and isinstance(content,dict) and content.get('sections'):issue('no_document_status_with_stored_content','understanding',content.get('rceptNo'))
            if isinstance(content,dict) and understanding.get('rceptNo') and content.get('rceptNo')!=understanding['rceptNo']:issue('report_receipt_mismatch','understanding',{'content':content.get('rceptNo'),'understanding':understanding['rceptNo']})
        if content is None:issue('latest_content_null','businessContent','stored original exists; null is not treated as no disclosure')
        (directory/'snapshot.json').write_text(json.dumps(snapshot,ensure_ascii=False))
        return {key:snapshot[key] for key in ['company','errors','checks','routeStates','sourceCheckStates']} | {'understandingStatus':snapshot.get('understandingStatus','unknown'),'snapshot':str(directory/'snapshot.json')}
    ledger=[]
    suffix='verification-' if args.verify_captured else 'retry-' if args.refresh_findings else 'refresh-' if args.refresh_route else ''
    with (output/(suffix+'ledger.jsonl')).open('w') as stream, concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        jobs={pool.submit(fetch,c):c for c in selection}
        for n,job in enumerate(concurrent.futures.as_completed(jobs),1):
            result=job.result();ledger.append(result);stream.write(json.dumps(result,ensure_ascii=False)+'\n');stream.flush()
            if n%50==0 or result['errors']:print(f"{n}/{len(selection)} {result['company']['name']} errors={len(result['errors'])} checks={len(result['checks'])}",flush=True)
    failures=[d for d in ledger if d['errors'] or d['checks']]
    (output/(suffix+'failures.json')).write_text(json.dumps(failures,ensure_ascii=False,indent=2))
    counts={};source_counts={};statuses={}
    for d in ledger:
        statuses[d['understandingStatus']]=statuses.get(d['understandingStatus'],0)+1
        for kind,count in d['sourceCheckStates'].items():source_counts[kind]=source_counts.get(kind,0)+count
        for c in d['checks']:counts[c['kind']]=counts.get(c['kind'],0)+1
    summary={'companies':len(ledger),'selected':len(selection),'excluded':len(excluded),'endpointSnapshots':len(ledger)*len(ROUTES),'apiCalls':sum(s.get('source')=='public_api' for d in ledger for s in d['routeStates'].values()),'sourceCheckStates':source_counts,'understandingStates':statuses,'apiErrors':sum(len(d['errors']) for d in ledger),'checkCounts':counts,'companiesWithFindings':len(failures),'nullStates':sum(s['state']=='null' for d in ledger for s in d['routeStates'].values()),'emptyStates':sum(s['state']=='empty' for d in ledger for s in d['routeStates'].values()),'note':'null/empty recorded separately; evidence checks use active stored originals; no source re-collection or DB mutation'}
    (output/(suffix+'capture-summary.json')).write_text(json.dumps(summary,ensure_ascii=False,indent=2));print(json.dumps(summary,ensure_ascii=False),flush=True)
if __name__=='__main__':main()
