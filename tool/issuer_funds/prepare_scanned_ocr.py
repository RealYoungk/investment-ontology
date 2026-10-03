#!/usr/bin/env python3
"""Local only, exact two PDFs -> unchanged page PNGs + independent raw OCR JSON.
No cropping, image editing, number substitution, database or network operation.
Cloud consumes prepared immutable sidecars and never runs this tool.
"""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
from extract_mapps import MANIFEST

def prepare(pdfroot,out,repository):
    version=subprocess.run(['pdftoppm','-v'],capture_output=True,check=True).stderr.decode().splitlines()[0]
    if version!='pdftoppm version 26.02.0':raise ValueError('Pinned renderer required')
    if subprocess.check_output(['sw_vers','-productVersion'],text=True).strip()!='26.5.2':raise ValueError('Pinned local OCR platform required')
    if subprocess.check_output(['sw_vers','-buildVersion'],text=True).strip()!='25F84':raise ValueError('Pinned local OCR platform build required')
    if 'Apple Swift version 6.3.3' not in subprocess.check_output(['xcrun','swift','--version'],text=True):raise ValueError('Pinned local Swift compiler required')
    out.mkdir(parents=True,exist_ok=True)
    documents=json.loads(MANIFEST.read_text())['documents'];ledger=[]
    with tempfile.TemporaryDirectory(prefix='scanned-fund-ocr-') as temp:
        binaries={}
        for lang,script in [('ko-en','scanned_recognize_page.swift'),('en','scanned_recognize_numbers.swift')]:
            source=repository/'tool/issuer_funds'/script; binary=Path(temp)/lang
            subprocess.run(['xcrun','swiftc',str(source),'-o',str(binary)],check=True);binaries[lang]=binary
        for year in (2021,2022):
            pdf=pdfroot/f'mkif-{year}.pdf';metadata=next(d['metadata'] for d in documents if d['metadata']['corpCode']=='00435297' and d['metadata']['periodEnd']==f'{year}-12-31')
            if hashlib.sha256(pdf.read_bytes()).hexdigest()!=metadata['sha256']:raise ValueError('Exact scanned original required')
            for page in range(8,14):
                scale=6600 if year==2021 and page==11 else 4400
                folder=out/'ce-page11-candidates' if scale==6600 else out/'rerender4400';folder.mkdir(exist_ok=True)
                prefix=folder/(f'mkif{year}-{page:02}-{scale}' if scale==6600 else f'mkif{year}-{page:02}')
                image=prefix.with_suffix('.png')
                command=['pdftoppm','-f',str(page),'-l',str(page),'-singlefile','-scale-to',str(scale),'-png',str(pdf),str(prefix)]
                if image.exists():raise ValueError('Existing immutable render; use new output directory')
                subprocess.run(command,check=True)
                for lang,binary in binaries.items():
                    target=Path(str(prefix)+'.'+lang+'.json');raw=subprocess.check_output([str(binary),str(image)]);target.write_bytes(raw)
                ledger.append({'year':year,'pageOrdinal':page,'pdfSHA256':metadata['sha256'],'imageSHA256':hashlib.sha256(image.read_bytes()).hexdigest(),'command':command,'renderVersion':version,'scale':scale})
    (out/'render-manifest.json').write_text(json.dumps(ledger,indent=2)+'\n')
if __name__=='__main__':
    a=argparse.ArgumentParser(description=__doc__);a.add_argument('pdfroot',type=Path);a.add_argument('--out',type=Path,required=True);a.add_argument('--repository',type=Path,required=True);p=a.parse_args();prepare(p.pdfroot,p.out,p.repository)
