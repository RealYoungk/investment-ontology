#!/usr/bin/env python3
"""Offline issuer-logo acquisition and local SVG tracing; no paid API.
Official-homepage img elements explicitly labelled logo/CI only. Never uses
search thumbnails, generic OG hero photos or third-party logo services.
Run with requirements-company-icons.txt in an isolated venv.
"""
import argparse, concurrent.futures, hashlib, io, ipaddress, json, pathlib, re, socket, time
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup
from PIL import Image, ImageChops
import cairosvg, vtracer

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT/'output/company-branding'
ASSETS = ROOT/'investment_ontology_serverpod_flutter/assets/company_icons'
MANIFEST = OUT/'company-icon-catalog.json'
OVERRIDES = {x['stockCode']: x for x in json.loads((ROOT/'investment_ontology_serverpod_flutter/assets/company_logos/PROVENANCE.json').read_text())}
OVERRIDES.update(json.loads((ROOT/'scripts/branding/reviewed_sources.json').read_text()) if (ROOT/'scripts/branding/reviewed_sources.json').exists() else {})
PAGE_SOURCES = json.loads((ROOT/'scripts/branding/source_pages.json').read_text()) if (ROOT/'scripts/branding/source_pages.json').exists() else {}
PAGE_IDENTITY_CHECKS = set(json.loads((ROOT/'scripts/branding/source_domains_require_identity.json').read_text())) if (ROOT/'scripts/branding/source_domains_require_identity.json').exists() else set()
OVERRIDES['0007C0'] = dict(pageUrl='https://acryl.ai/', imageUrl='https://acryl.ai/assets/images/meta/%EB%A1%9C%EA%B3%A0%20%EC%BB%AC%EB%9F%AC.png')


def public_url(url):
    p=urlparse(url)
    if p.scheme not in ('http','https') or not p.hostname or p.username or p.password:
        raise ValueError('Invalid public URL')
    for entry in socket.getaddrinfo(p.hostname, p.port or (443 if p.scheme=='https' else 80)):
        if not ipaddress.ip_address(entry[4][0]).is_global:
            raise ValueError('Non-public address')
    return url


def fetch(url, limit=2_000_000):
    for _ in range(5):
        public_url(url)
        with requests.get(url, timeout=(4,7), allow_redirects=False, stream=True,
                headers={'User-Agent':'AlfinderCompanyIdentity/1.0 (official company logo cache)'}) as r:
            if r.is_redirect:
                url=urljoin(url,r.headers['Location']);continue
            r.raise_for_status()
            parts=[];n=0
            for chunk in r.iter_content(65536):
                n+=len(chunk)
                if n>limit:raise ValueError('Response too large')
                parts.append(chunk)
            return b''.join(parts),url
    raise ValueError('Too many redirects')


def rpc(base,method,args):
    r=requests.post(base+'/'+method,json=args,timeout=30);r.raise_for_status();return r.json()


def acquire(item,base):
    result={k:v for k,v in item.items() if not k.startswith('_')}
    result.update(status='missing',checkedAt=time.strftime('%Y-%m-%d'))
    try:
        detail=rpc(base,'company/detail',{'corpCode':item['corpCode']})['company']
        home=(detail.get('homepageUrl') or '').strip()
        if item['stockCode'] in PAGE_SOURCES:home=PAGE_SOURCES[item['stockCode']][item.get('_pageIndex',0)]
        if not home:raise ValueError('No official homepage in company master')
        if not re.match(r'^https?://',home):home='https://'+home
        result['homepageUrl']=home
        if item['stockCode'] in OVERRIDES:
            html,page=b'',OVERRIDES[item['stockCode']]['pageUrl']
        else:
            try:html,page=fetch(home)
            except Exception:
                if home.startswith('https:'):html,page=fetch('http:'+home[6:])
                else:raise
        if re.search(r'(?:^|\.)(?:digitaltoday\.co\.kr|atsview\.com|tradingview\.com|financialreports\.eu|stockevents\.app|brandb\.co\.kr)$',urlparse(page).hostname or '',re.I):
            raise ValueError('Publisher or market portal cannot establish official issuer artwork')
        soup=BeautifulSoup(html,'html.parser')
        if item['stockCode'] in PAGE_IDENTITY_CHECKS and item['stockCode'] not in OVERRIDES:
            normalize=lambda value: re.sub(r'[^a-zA-Z0-9가-힣]', '', value).lower().replace('주식회사','')
            title=normalize((soup.title.get_text() if soup.title else '')+' '+soup.get_text(' ',strip=True)[:6000])
            names=[normalize(detail.get(k) or '') for k in ('stockName','name','nameEng')]
            if not any(len(name)>=3 and name in title for name in names):raise ValueError('New source domain issuer identity not confirmed')
        # Financial sites may publish a frameset around their actual company page.
        frames=[f.get('src') for f in soup.find_all('frame') if f.get('src') and not re.search(r'blank|session',f.get('src'),re.I)]
        if frames:
            try:
                html,page=fetch(urljoin(page,frames[0]));soup=BeautifulSoup(html,'html.parser')
            except Exception:pass
        inline_sources={}
        candidates=[(100,OVERRIDES[item['stockCode']]['imageUrl'])] if item['stockCode'] in OVERRIDES else []
        for script in soup.find_all('script',type='application/ld+json'):
            try:
                payload=json.loads(script.string or script.get_text())
                nodes=payload if isinstance(payload,list) else payload.get('@graph',[payload])
                for node in nodes:
                    if not isinstance(node,dict):continue
                    if not any(kind in str(node.get('@type','')) for kind in ('Organization','Corporation','Brand','WebSite')):continue
                    logo=node.get('logo')
                    if isinstance(logo,dict):logo=logo.get('url') or logo.get('contentUrl')
                    if isinstance(logo,str):candidates.append((25,urljoin(page,logo)))
            except Exception:pass
        for svg in soup.find_all('svg'):
            marker=' '.join([str(svg.get('class','')),str(svg.get('id','')),str(svg.get('aria-label',''))])
            parents=' '.join(str(p.get('class',''))+' '+str(p.get('id','')) for p in list(svg.parents)[:2] if getattr(p,'attrs',None))
            if not re.search(r'logo|로고',marker+' '+parents,re.I):continue
            if not svg.find(['path','polygon','rect','circle','use']):continue
            if svg.get('viewbox'):svg['viewBox']=svg.attrs.pop('viewbox')
            svg['xmlns']='http://www.w3.org/2000/svg'
            svg['xmlns:xlink']='http://www.w3.org/1999/xlink'
            for use in svg.find_all('use'):
                target=use.get('href') or use.get('xlink:href') or ''
                if target.startswith('#'):
                    symbol=soup.find(id=target[1:])
                    if symbol and symbol is not svg:
                        defs=soup.new_tag('defs');defs.append(BeautifulSoup(str(symbol),'html.parser'));svg.append(defs)
            data=str(svg).encode()
            key='inline:'+hashlib.sha256(data).hexdigest()
            inline_sources[key]=data
            candidates.append((15,key))
        for img in soup.find_all('img'):
            src=img.get('src') or img.get('data-src') or img.get('data-original')
            if not src or src.startswith('data:'):continue
            marker=' '.join([str(src),str(img.get('alt','')),str(img.get('class','')),str(img.get('id',''))])
            ancestors=' '.join(str(parent.get('class',''))+' '+str(parent.get('id','')) for parent in list(img.parents)[:3] if getattr(parent,'attrs',None))
            if not re.search(r'logo|로고|(?:^|[/_-])ci(?:[._/-]|$)',str(src)+' '+str(img.get('class',''))+' '+str(img.get('id','')),re.I) and not re.search(r'logo|로고',ancestors,re.I) and not (re.search(r'/ci[./]|brand|identity',page,re.I) and re.search(r'symbol|심볼|로고|logotype',str(img.get('alt','')),re.I)):continue
            if not re.search(r'header|gnb|footer|head|logo|nav',ancestors+' '+str(img.get('class',''))+' '+str(img.get('id','')),re.I) and not re.search(r'/ci[./]|brand|identity',page,re.I):continue
            if re.search(r'arrow|btn[_-]|button|download|close|banner|(?:partner|client|customer)[_-]?(?:logo|list)|certi|sns|youtube|facebook|instagram|web.?access|logo[_-]wa|wa[_.]|award|brand.?site|family|affiliate|case.?study|success.?story|reference|customer.?story|계열|관계사|웹어워드|수상|배너',marker+' '+ancestors,re.I):continue
            if re.search(r'footer|foot|white|_wh|_w\.',marker+' '+ancestors,re.I):score=1
            else:score=0
            score+=5 if re.search(r'logo',marker,re.I) else 1
            if re.search(r'symbol|심볼',marker,re.I):score+=20
            score+=3 if re.search(r'header|gnb|top|head',ancestors,re.I) else 0
            candidates.append((score,urljoin(page,src)))
        for icon in soup.find_all('link'):
            if 'icon' in ' '.join(icon.get('rel',[])).lower() and icon.get('href'):
                candidates.append((0,urljoin(page,icon['href'])))
        if item['stockCode'] not in OVERRIDES:
            for css in [link for link in soup.find_all('link') if 'stylesheet' in link.get('rel',[]) and link.get('href') and not re.search(r'font|swiper|bootstrap|animate|jquery|slick',link['href'],re.I)][:8]:
                try:
                    css_data,css_url=fetch(urljoin(page,css['href']),limit=1_000_000)
                    for value in re.findall(r'url\(\s*[\"\']?([^\)\"\']+)',css_data.decode('utf-8','replace')):
                        if re.search(r'logo|(?:^|[/_-])ci(?:[._/-]|$)',value,re.I) and not re.search(r'arrow|btn[_-]|button|download|close|sns|youtube|facebook|instagram|award|banner|wa[_-]',value,re.I):
                            score=7 if not re.search(r'white|_wh|_w[._]',value,re.I) else 4
                            candidates.append((score,urljoin(css_url,value.strip())))
                except Exception:pass
        candidates.append((0,urljoin(page,'/favicon.ico')))
        errors=[]
        for score,url in sorted(set(candidates),reverse=True)[:12]:
            if score<0:continue
            try:
                data,image_url=(inline_sources[url],page+'#'+url) if url in inline_sources else fetch(url)
                download_sha=hashlib.sha256(data).hexdigest()
                if b'<svg' in data[:10000]:
                    # Do not resolve foreign files or script-bearing SVG content.
                    if re.search(rb'<!DOCTYPE|<!ENTITY|<script|(?:href|url)\s*[=(]\s*["\']?(?:https?:|file:)',data,re.I):
                        raise ValueError('External SVG resource')
                    data=cairosvg.svg2png(bytestring=data,output_width=384)
                image=Image.open(io.BytesIO(data)).convert('RGBA')
                if not image.getbbox():raise ValueError('Empty transparent image')
                if image.width<24 or image.height<10 or image.width>10000 or image.height>10000:
                    raise ValueError('Invalid logo dimensions')
                if item['stockCode']=='0007C0':
                    image=image.crop((0,0,min(int(image.height*1.1),image.width),image.height))
                bbox=image.getbbox()
                if bbox:image=image.crop(bbox)
                if image.getextrema()[3]==(255,255):
                    corner=image.getpixel((0,0))
                    diff=ImageChops.difference(image.convert('RGB'),Image.new('RGB',image.size,corner[:3]))
                    bbox=diff.point(lambda value:255 if value>20 else 0).getbbox()
                    if bbox:image=image.crop(bbox)
                if score==0 and (image.width<32 or image.height<32):raise ValueError('Site icon below display quality threshold')
                visible=[pixel for pixel in image.getdata() if pixel[3]>200]
                on_dark=bool(visible) and sum(min(p[:3])>220 for p in visible)/len(visible)>.55
                image.thumbnail((384,384))
                source=OUT/'raw'/f"{item['stockCode']}.png"
                image.save(source)
                (ASSETS/f"{item['stockCode']}.png").write_bytes(source.read_bytes())
                dest=ASSETS/f"{item['stockCode']}.svg"
                svg=b''
                try:
                    vtracer.convert_image_to_svg_py(str(source),str(dest),colormode='color',hierarchical='stacked',mode='spline',filter_speckle=4,color_precision=6,layer_difference=16,corner_threshold=60,length_threshold=4.0,max_iterations=10,splice_threshold=45,path_precision=3)
                    svg=dest.read_bytes()
                    if len(svg)>250_000:dest.unlink();svg=b''
                except Exception:pass  # Optional trace never blocks an original logo.

                result.update(status='ready',pageUrl=page,imageUrl=image_url,sourceSha256=download_sha,sourceHashKind='downloaded-bytes',originalSha256=hashlib.sha256(source.read_bytes()).hexdigest(),originalFilename=item['stockCode']+'.png',vectorSha256=hashlib.sha256(svg).hexdigest() if svg else None,bytes=source.stat().st_size,filename=dest.name,width=image.width,height=image.height,onDark=on_dark,method='official-homepage-logo-bundled-original')
                return result
            except Exception as error:errors.append(str(error)[:120])
        raise ValueError('No eligible homepage logo: '+'; '.join(errors))
    except Exception as error:
        pages=PAGE_SOURCES.get(item['stockCode'],[])
        index=item.get('_pageIndex',0)
        if item['stockCode'] not in OVERRIDES and index+1<min(len(pages),3) and re.search(r'No eligible|404|identity not confirmed',str(error),re.I):
            return acquire(dict(item,_pageIndex=index+1),base)
        result['reason']=str(error)[:240]
        return result


def publish(records):
    OUT.mkdir(parents=True,exist_ok=True)
    tmp=MANIFEST.with_suffix('.tmp');tmp.write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n');tmp.replace(MANIFEST)
    ready={x['stockCode']:x for x in records if x['status']=='ready'}
    dart=ROOT/'investment_ontology_serverpod_flutter/lib/design/components/company_icon_catalog.dart'
    text='// Offline build artifact. Regenerate with scripts/branding/collect_company_icons.py.\nconst companyVectorIcons = <String, String>{\n'
    for code in sorted(ready):text+=f"  '{code}': 'assets/company_icons/{code}.svg',\n"
    text+='};\nconst companyVectorCodesByCorp = <String, String>{\n'
    for x in sorted(ready.values(),key=lambda x:x['corpCode']):text+=f"  '{x['corpCode']}': '{x['stockCode']}',\n"
    text+='};\nconst companyVectorDarkBackground = <String>{\n'
    for code,x in sorted(ready.items()):
        if x.get('onDark'):text+=f"  '{code}',\n"
    text+='};\nconst companyServiceVectorCodes = <String>{\n'
    for code,x in sorted(ready.items()):
        if x.get('method','').startswith('service-'):text+=f"  '{code}',\n"
    text+='};\n';dart.write_text(text)
    provenance=[]
    for code,row in sorted(ready.items()):
        asset=ASSETS/(code+('.svg' if row.get('method','').startswith('service-') else '.png'))
        provenance.append({k:row[k] for k in ('stockCode','corpCode','name','pageUrl','imageUrl','method','sourceSha256','sourceHashKind','checkedAt','identitySourceUrl','designConcept','officialArtwork','acquisitionFailure') if k in row} | {'asset':asset.name,'assetSha256':hashlib.sha256(asset.read_bytes()).hexdigest(),'manuallyVerified':False})
    (ASSETS/'PROVENANCE.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
    summary={'total':len(records),'ready':len(ready),'missing':sum(x['status']=='missing' for x in records),'pending':sum(x['status']=='pending' for x in records),'authored':sum(x.get('method')=='service-authored-vector-identity' for x in records),'sourceDerived':sum(x['status']=='ready' and x.get('method')!='service-authored-vector-identity' for x in records),'bytes':sum(x.get('bytes',0) for x in records)}
    (OUT/'company-icon-coverage.json').write_text(json.dumps(summary,indent=2)+'\n')
    return summary


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--base',default='http://localhost:8080');parser.add_argument('--workers',type=int,default=10);parser.add_argument('--retry-missing',action='store_true');parser.add_argument('--retry-authored',action='store_true');parser.add_argument('--refresh',action='store_true');parser.add_argument('--recheck-codes',default='');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'raw').mkdir(exist_ok=True);ASSETS.mkdir(parents=True,exist_ok=True)
    first=rpc(args.base,'company/list',{'limit':200,'offset':0});items=first['items']
    for offset in range(200,first['total'],200):items+=rpc(args.base,'company/list',{'limit':200,'offset':offset})['items']
    items=[x for x in items if x.get('stockCode')]
    priority={'420770','0007C0','059090','005930','000660','005380','035420'}
    items.sort(key=lambda x:(x['stockCode'] not in priority,-int(x.get('marketCap') or 0)))
    old={x['corpCode']:x for x in json.loads(MANIFEST.read_text())} if MANIFEST.exists() else {}
    records=[dict(x,status='pending') if args.refresh else old.get(x['corpCode'],dict(x,status='pending')) for x in items]
    recheck=set(args.recheck_codes.split(','))
    todo=[x for x in items if args.retry_authored and old.get(x['corpCode'],{}).get('method')=='service-authored-vector-identity' or x['stockCode'] in recheck or args.refresh or x['corpCode'] not in old or old[x['corpCode']]['status']=='pending' or args.retry_missing and old[x['corpCode']]['status']=='missing']
    positions={x['corpCode']:i for i,x in enumerate(records)}
    publish(records)
    print(json.dumps(dict(universe=len(items),todo=len(todo))),flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures=[pool.submit(acquire,x,args.base) for x in todo]
        for n,future in enumerate(concurrent.futures.as_completed(futures),1):
            result=future.result()
            previous=records[positions[result['corpCode']]]
            if result['status']=='missing' and previous.get('method')=='service-authored-vector-identity':
                previous['lastOriginalRetryReason']=result.get('reason');result=previous
            records[positions[result['corpCode']]]=result
            if n%100==0 or n==len(todo):print(json.dumps(publish(records)),flush=True)
    print(json.dumps(publish(records)),flush=True)
if __name__=='__main__':main()
