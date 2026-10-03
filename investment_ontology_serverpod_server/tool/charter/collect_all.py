"""All locally listed issuers, latest corrected AGM notices in the last year.
No key/AI/DB mutation. Resume source-bound DART bodies, shared Dart parser next.
"""
import argparse, concurrent.futures, datetime, gzip, html, json, pathlib, re, threading, time, urllib.parse, urllib.request, urllib.error
parser=argparse.ArgumentParser();parser.add_argument('--output',required=True);parser.add_argument('--base',default='http://localhost:8080');parser.add_argument('--workers',type=int,default=2);args=parser.parse_args()
out=pathlib.Path(args.output);out.mkdir(parents=True,exist_ok=True);(out/'bodies').mkdir(exist_ok=True)
lock=threading.Lock();next_request=0
blocked=threading.Event();consecutive_network_failures=0

def get(url):
 global next_request
 if url.startswith('https://dart.fss.or.kr/'):
  with lock:
   delay=max(0,next_request-time.monotonic());next_request=max(next_request,time.monotonic())+1.2
  time.sleep(delay)
 req=urllib.request.Request(url,headers={'User-Agent':'InvestmentOntology/1.0'})
 with urllib.request.urlopen(req,timeout=25) as r:
  if urllib.parse.urlparse(r.url).hostname!=urllib.parse.urlparse(url).hostname:raise ValueError('redirect host mismatch')
  b=r.read(8*1024*1024+1)
  if len(b)>8*1024*1024:raise ValueError('oversized source')
  return b.decode('utf-8')

def rpc(method,values):
 req=urllib.request.Request(args.base+'/'+method,data=json.dumps(values).encode(),headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=30) as r:return json.load(r)
companies=[];offset=0
while True:
 page=rpc('company/list',{'offset':offset,'limit':200})
 companies+=page['items'];offset+=len(page['items'])
 if offset>=page['total']:break
codes={c['corpCode'] for c in companies}
(out/'companies.json').write_text(json.dumps(companies,ensure_ascii=False))
today=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).date();start=today.replace(year=today.year-1)
q=dict(reportName='주주총회소집공고',startDate=start.strftime('%Y%m%d'),endDate=today.strftime('%Y%m%d'),maxResults='100',sort='date',series='desc',finalReport='recent')
notices={};page=1
while True:
 url='https://dart.fss.or.kr/dsab007/detailSearch.ax?'+urllib.parse.urlencode(dict(q,currentPage=str(page)))
 s=get(url);(out/f'listing_{page}.html.gz').write_bytes(gzip.compress(s.encode()))
 for row in re.findall(r'<tr\b[^>]*>.*?</tr>',s,re.S|re.I):
  corp=re.search(r"openCorpInfoNew\('(\d{8})'",row)
  link=re.search(r'''openReportViewer\(['"](\d{14})['"],['"]['"]\).*?>(.*?)</a>''',row,re.S)
  if not corp or not link or corp[1] not in codes:continue
  name=re.sub(r'\s+','',re.sub('<[^>]+>','',html.unescape(link[2])))
  if not re.fullmatch(r'(?:\[(?:기재|첨부)정정\])?주주총회소집공고',name):continue
  notices[link[1]]=dict(corpCode=corp[1],receipt=link[1],reportName=name)
 pages=re.search(r'\[\d+/(\d+)\]',s)
 if not pages:raise ValueError('pagination unavailable')
 print(f'discovery {page}/{pages[1]} notices={len(notices)}',flush=True)
 if page>=int(pages[1]):break
 page+=1
# Keep all meetings from the bounded year; do not confuse latest no-change with absence.
manifest=dict(fromDate=str(start),toDate=str(today),companies=len(codes),notices=list(notices.values()))
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False))

def fetch(n):
 path=out/'bodies'/f"{n['receipt']}.json.gz"
 if path.exists():return 'cached'
 if blocked.is_set():return dict(n,error='public source stopped after repeated connection failures')
 try:
  shell=get('https://dart.fss.or.kr/dsaf001/main.do?rcpNo='+n['receipt'])
  issuers=set(re.findall(r"openCorpInfoNew\('(\d{8})'",shell))
  if issuers!={n['corpCode']}:raise ValueError('issuer mismatch')
  sources=[]
  for title,block in re.findall(r'''node\d+\[['"]text['"]\]\s*=\s*['"]([^'"]+)['"];(.*?)(?:cnt\+\+)''',shell,re.S):
   if not re.fullmatch(r'(?:\d+\.)?주주총회목적사항별기재사항',re.sub(r'\s+','',title)):continue
   fields=dict(re.findall(r'''\[['"](rcpNo|dcmNo|eleId|offset|length|dtd)['"]\]\s*=\s*['"]([^'"]+)['"]''',block))
   if len(fields)!=6 or fields['rcpNo']!=n['receipt']:raise ValueError('unbound body')
   if not all(re.fullmatch(r'\d+',fields[k]) for k in ['dcmNo','eleId','offset','length']):raise ValueError('invalid coordinates')
   sources.append('https://dart.fss.or.kr/report/viewer.do?'+urllib.parse.urlencode(fields))
  if len(sources)!=1:raise ValueError('comparison section absent or ambiguous')
  body=get(sources[0])
  if not re.search(r'<TABLE\b',body,re.I):raise ValueError('actual table body absent')
  value=dict(n,body=body,sourceUrl=sources[0],retrievedAt=datetime.datetime.now(datetime.timezone.utc).isoformat())
  path.write_bytes(gzip.compress(json.dumps(value,ensure_ascii=False).encode()))
  return 'fetched'
 except Exception as e:
  global consecutive_network_failures
  if isinstance(e,(urllib.error.URLError,ConnectionError,TimeoutError)):
   with lock:
    consecutive_network_failures+=1
    if consecutive_network_failures>=3:blocked.set()
  return dict(n,error=type(e).__name__)
failures=[];done=0
with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
 for result in pool.map(fetch,notices.values()):
  done+=1
  if isinstance(result,dict):failures.append(result)
  if done%50==0:
   (out/'failures.json').write_text(json.dumps(failures,ensure_ascii=False))
   print(f'bodies {done}/{len(notices)} failed={len(failures)}',flush=True)
(out/'failures.json').write_text(json.dumps(failures,ensure_ascii=False))
print(json.dumps(dict(companies=len(codes),notices=len(notices),bodies=done-len(failures),failed=len(failures))),flush=True)
