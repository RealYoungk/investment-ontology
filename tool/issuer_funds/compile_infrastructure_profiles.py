#!/usr/bin/env python3
"""Compile source coordinates/equations only, no amount literals or posting."""
import argparse,json
from pathlib import Path
from infrastructure_proof import proof

def compile_profiles(paths,output,fixtures):
    profiles=[];independent=[]
    fixtures.mkdir(parents=True,exist_ok=True)
    for pdf in paths:
        p=proof(pdf);m=p['metadata'];cells={}
        def key(c):return f"{c['statement']}:{c['pageOrdinal']}:{c['lineOrdinal']}"
        def add(c):
            k=key(c)
            cells[k]={q:c[q] for q in ('statement','pageOrdinal','lineOrdinal','accountLabel','normalizedLabel','labelCoordinates','tokenCount','currentTokenIndex','comparativeTokenIndex')}
            return k
        observations=[{'cellKey':add(c),'metric':c['metric'],'cashDirection':c['cashDirection'],'amountScope':c['amountScope'],
                       'printedSign':'negative' if c['amountInteger'].startswith('-') else 'zero' if c['amountInteger']=='0' else 'positive'} for c in p['observations']]
        checks=[{'name':c['name'],'left':add(c['left']),'terms':[{'cellKey':add(t['cell']),'coefficient':t['coefficient']} for t in c['terms']]} for c in p['checks']]
        equity=[{k:c[k] for k in ('statement','pageOrdinal','lineOrdinal','tokenCount','componentTokenIndices')} for c in p['equityWitnesses']]
        profiles.append({**{k:p[k] for k in ('metadata','rawTextSha256','decodedTextSha256','decodedPages','textTransformation','cashScope')},
                         'extractionTool':'pdftotext 26.02.0 -layout -enc UTF-8','headers':[{'pageOrdinal':h['pageOrdinal'],'statement':h['statement']} for h in p['headers']],
                         'cells':cells,'observations':observations,'checks':checks,'equityWitnesses':equity})
        prefix=f"{m['corpCode']}-{m['periodEnd']}"
        (fixtures/(prefix+'.raw.txt')).write_bytes(p['rawText'])
        independent.append({k:v for k,v in p.items() if k not in ('rawText','decodedText')})
    if len(profiles)!=5 or len({p['metadata']['sha256'] for p in profiles})!=5:raise ValueError('Five distinct approved originals required')
    output.write_text('/// Exact five infrastructure PDFs, raw text and font transforms. No amounts.\nabstract final class InfrastructureFundProfiles {\n static const rows = <Map<String,dynamic>>'+json.dumps(profiles,ensure_ascii=False,indent=2)+';\n}\n')
    (fixtures/'independent-current-proof.json').write_text(json.dumps(independent,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__':
    a=argparse.ArgumentParser(description=__doc__);a.add_argument('pdf',type=Path,nargs=5);a.add_argument('--output',type=Path,required=True);a.add_argument('--fixtures',type=Path,required=True);p=a.parse_args();compile_profiles(p.pdf,p.output,p.fixtures)
