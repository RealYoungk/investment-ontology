#!/usr/bin/env python3
"""Local offline source-profile compiler. No amount literals or posting.
Accept the six exact own PDF paths; write profiles and full server test text.
"""
import argparse, hashlib, json, re, subprocess
from pathlib import Path
from extract_mapps import ROOT, MANIFEST, extract_pdf

def compile_profiles(paths, output):
    documents = json.loads(MANIFEST.read_text())['documents']
    profiles = []
    for path in paths:
        proof = extract_pdf(path)
        text = subprocess.check_output(['pdftotext','-layout','-enc','UTF-8',str(path),'-'])
        metadata = next(d['metadata'] for d in documents if d['metadata']['sha256'] == proof['sha256'])
        def coords(row):
            return {k: row[k] for k in ('pageOrdinal','lineOrdinal','accountLabel') if k in row}
        equity = []
        for row in proof['validation']['equityWitnesses']:
            c = coords(row)
            if 'marker' in row:
                c['markerLabel'] = re.match(r'^.*?\((?:당기초|당기말)\)', row['marker'])[0]
                matches = [(pi,li) for pi,page in enumerate(text.decode().split('\f'),1)
                           for li,line in enumerate(page.splitlines(),1) if line == row['marker']]
                if len(matches) != 1:
                    raise ValueError('Unique CE date marker required')
                c['markerPageOrdinal'], c['markerLineOrdinal'] = matches[0]
            equity.append(c)
        profiles.append({'metadata':metadata, 'extractedTextSha256':hashlib.sha256(text).hexdigest(),
                         'extractionTool':'pdftotext 26.02.0 -layout -enc UTF-8',
                         'observations':[{**coords(r), **{k:r[k] for k in ('metric','statement','periodStart','periodEnd','amountScope','cashDirection')},
                                          'printedSign':'negative' if int(r['amountInteger']) < 0 else 'zero' if int(r['amountInteger']) == 0 else 'positive'} for r in proof['observations']],
                         'cashWitnesses':[coords(r) for r in proof['validation']['cashWitnesses']],
                         'equityWitnesses':equity})
    if len(profiles) != 6 or len({p['metadata']['sha256'] for p in profiles}) != 6:
        raise ValueError('Exact six distinct source PDFs required')
    profiles.sort(key=lambda p:p['metadata']['periodEnd'])
    output.write_text('/// Exact own PDF and complete private extracted-text pins. No amount literals.\nabstract final class FundFinancialProfiles {\n  static const rows = <Map<String,dynamic>>' + json.dumps(profiles,ensure_ascii=False,indent=2) + ';\n}\n')

if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('pdf',type=Path,nargs=6)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args()
    compile_profiles(a.pdf,a.output)
