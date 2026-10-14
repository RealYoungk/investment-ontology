#!/usr/bin/env python3
"""Retrieve actual DART business-section HTML for a captured public corpus.
A shell or search snippet never counts as a retrieved primary body.
"""
import argparse, concurrent.futures, html, json, pathlib, re, time, urllib.parse, urllib.request
from html.parser import HTMLParser
class VisibleText(HTMLParser):
    def __init__(self):super().__init__();self.parts=[]
    def handle_data(self,data):self.parts.append(data)
def fetch(url):
    for attempt in range(3):
        try:
            time.sleep(.3)
            with urllib.request.urlopen(url,timeout=35) as r:return r.read().decode('utf-8')
        except Exception:
            if attempt==2:raise
            time.sleep(1+attempt)
def main():
    p=argparse.ArgumentParser();p.add_argument('corpus',type=pathlib.Path);p.add_argument('output',type=pathlib.Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    docs=[json.loads(line) for line in a.corpus.read_text().splitlines()];results=[]
    def run(doc):
        receipt=doc['receipt'];path=a.output/(receipt+'.html');result={k:doc[k] for k in ['corpCode','name','receipt','role']}
        try:
            url='https://dart.fss.or.kr/dsaf001/main.do?rcpNo='+receipt
            shell=fetch(url);start=shell.index("['text'] = \"II. 사업의 내용\"");block=shell[start:start+650]
            args={k:re.search(r"\['"+k+r"'\]\s*=\s*\"([^\"]+)\"",block).group(1) for k in ['rcpNo','dcmNo','eleId','offset','length','dtd']}
            viewer='https://dart.fss.or.kr/report/viewer.do?'+urllib.parse.urlencode(args)
            raw=path.read_text() if path.exists() else fetch(viewer);path.write_text(raw);parser=VisibleText();parser.feed(raw);visible=' '.join(parser.parts);clean=re.sub(r'\s+','',html.unescape(visible))
            tokens=list(dict.fromkeys(re.findall(r'\d{1,3}(?:,\d{3})+(?:\.\d+)?',doc['text'])))[:40]
            missing=[t for t in tokens if t not in clean]
            result.update({'status':'bodyRetrieved' if len(clean)>500 else 'bodyIncomplete','viewerUrl':viewer,'chars':len(clean),'numericTokensChecked':len(tokens),'missingNumericTokens':missing})
        except Exception as error:result.update({'status':'failed','error':str(error)})
        return result
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        for i,r in enumerate(pool.map(run,docs),1):
            results.append(r)
            if i%10==0:print(f'{i}/{len(docs)} primary bodies',flush=True)
    (a.output/'ledger.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print('done',len(results),flush=True)
if __name__=='__main__':main()
