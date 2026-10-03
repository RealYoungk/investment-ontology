#!/usr/bin/env python3
"""Local source sidecars/pins from exact dual OCR. Profiles contain no amounts."""
import argparse,json,hashlib,shutil
from pathlib import Path
from scanned_fund_proof import proof,GRAMMAR

def sha(raw):return hashlib.sha256(raw).hexdigest()
def build(root,repository):
    fixtures=repository/'investment_ontology_serverpod_server/test/fixtures/issuer_documents/scanned_fund';fixtures.mkdir(parents=True,exist_ok=True)
    cache=root/'private-cache';cache.mkdir(exist_ok=True)
    profiles=[];independent=[]
    scripts={k:sha((repository/'tool/issuer_funds'/v).read_bytes()) for k,v in [('koScriptSHA256','scanned_recognize_page.swift'),('enScriptSHA256','scanned_recognize_numbers.swift')]}
    labels=['자산 총계','부채 총계','자본 총계','운용수익','당기순이익','자산운용활동으로 인한 현금유입액','대출금의 취득','지분증권의 취득']
    for year in (2021,2022):
        p=proof(root,year);m=p['metadata'];pages=[];pagepins=[]
        pipeline={'renderer':'pdftoppm 26.02.0','rendererArguments':['-f','{physicalPage}','-l','{physicalPage}','-singlefile','-scale-to','{renderScale}','-png','{exactPDF}','{prefix}'],'platform':'macOS 26.5.2 build25F84','swift':'Apple Swift6.3.3 arm64-apple-macosx26.0','ocr':'Apple Vision accurate; usesLanguageCorrection=false; topCandidates=1','koLanguages':['ko-KR','en-US'],'enLanguages':['en-US'],**scripts}
        for source in p['sourcePages']:
            pin={k:source[k] for k in ('pageOrdinal','renderScale','imageSha256','koSha256','enSha256')};pagepins.append(pin)
            pages.append({**pin,'koJson':Path(source['koFile']).read_text(),'enJson':Path(source['enFile']).read_text()})
            target=cache/f"{m['sha256']}.p{source['pageOrdinal']:02}.png";raw=Path(source['imageFile']).read_bytes()
            if target.exists() and target.read_bytes()!=raw:raise ValueError('Immutable image collision')
            if not target.exists():target.write_bytes(raw)
            target.chmod(0o600)
        sidecar={'schemaVersion':1,'metadata':m,'pipeline':pipeline,'pages':pages,'acceptedSeparatorGrammar':GRAMMAR,'rawOcrRewritten':False,'regularApiOrXbrl':False,'notesVerified':False,'wholeStatementVerified':False}
        raw=(json.dumps(sidecar,ensure_ascii=False,indent=2)+'\n').encode();target=cache/f"{m['sha256']}.scanned-ocr.json"
        if target.exists() and target.read_bytes()!=raw:raise ValueError('Immutable OCR sidecar collision')
        if not target.exists():target.write_bytes(raw)
        target.chmod(0o600)
        (fixtures/f'{year}.scanned-ocr.json').write_bytes(raw)
        pdf=root.parent.parent/'unidentified-periodic-readonly-20261002/alternative-reports-and-listing-review/history'/f'mkif-{year}.pdf'
        original=pdf.read_bytes()
        if sha(original)!=m['sha256']:raise ValueError('Original PDF binding mismatch')
        pdfTarget=cache/f"{m['sha256']}.pdf"
        if pdfTarget.exists() and pdfTarget.read_bytes()!=original:raise ValueError('Immutable PDF collision')
        if not pdfTarget.exists():pdfTarget.write_bytes(original)
        pdfTarget.chmod(0o600)
        cells={}
        for k,c in p['cells'].items():
            cells[k]={q:c[q] for q in ('pageOrdinal','koRowIndex','enRowIndex','normalizationRole')}
            cells[k]['koTokenSha256']=sha(c['ko']['text'].encode())
            cells[k]['enTokenSha256']=None if c['en'] is None else sha(c['en']['text'].encode())
            cells[k]['koBox']={q:c['ko'][q] for q in ('x','y','width','height')}
            cells[k]['enBox']=None if c['en'] is None else {q:c['en'][q] for q in ('x','y','width','height')}
        observations=[{'cellKey':c['key'],'metric':c['key'],'accountLabel':labels[i],'statement':['재무상태표','손익계산서','현금흐름표'][0 if i<3 else 1 if i<5 else 2],'amountScope':'stockAtPeriodEnd' if i<3 else 'ownFiscalDuration','cashDirection':'outflow' if i>=6 else None} for i,c in enumerate(p['observations'])]
        profiles.append({'metadata':m,'sidecarSha256':sha(raw),'pipeline':pipeline,'sourcePages':pagepins,'cells':cells,'checks':[{k:c[k] for k in ('name','left','terms')} for c in p['checks']],'observations':observations,'printedMissingCEComponents':p['printedMissingCEComponents'],'visualReadScope':{'pages':list(range(8,14)),'scope':'current own numeric witnesses and selected categories; comparative/notes/whole report not verified'}})
        independent.append(p)
    (repository/'investment_ontology_serverpod_server/lib/src/ontology/research/scanned_fund_profiles.dart').write_text('/// Exact source/image/OCR/pipeline/coordinate pins. No monetary literals.\nabstract final class ScannedFundProfiles {\nstatic const rows=<Map<String,dynamic>>'+json.dumps(profiles,ensure_ascii=False,indent=2)+';\n}\n')
    (fixtures/'independent-current-proof.json').write_text(json.dumps(independent,ensure_ascii=False,indent=2)+'\n')
    (root/'private-cache-manifest.json').write_text(json.dumps([{'file':f.name,'bytes':f.stat().st_size,'sha256':sha(f.read_bytes()),'mode':oct(f.stat().st_mode&0o777)} for f in sorted(cache.iterdir())],indent=2)+'\n')
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('root',type=Path);a.add_argument('--repository',type=Path,required=True);p=a.parse_args();build(p.root,p.repository)
