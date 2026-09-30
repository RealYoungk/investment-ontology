#!/usr/bin/env python3
"""Build deterministic, source-bound overview assets; never writes the database.
Input: one JSON object per listed company (see export.sql). No network or AI calls.
"""
import argparse, collections, hashlib, json, pathlib, re
from datetime import datetime
from zoneinfo import ZoneInfo
from catalog import MODELS
from curated import NOTES
ROOT = pathlib.Path(__file__).resolve().parents[2]

# Explicit exceptions are company identifiers, not matches against competitor names.
# Every exception is restricted to a matching phrase in that issuer's opening overview.
OVERRIDES = {
 '00877059': ('cdmo', '위탁생산'),
 '00989619': ('biotech', '플랫폼 기술'),
 '00688996': ('financial_holding', '금융업'),
}
DIVISIONS = {
 '01':'primary','03':'primary','10':'food','11':'food','12':'consumer',
 '13':'consumer','14':'consumer','15':'consumer','16':'materials','17':'materials',
 '18':'manufacturing','19':'chemicals','20':'chemicals','21':'pharma',
 '22':'materials','23':'materials','24':'metals','25':'metals','26':'electronics',
 '27':'medical','28':'electrical','29':'equipment','30':'auto','31':'manufacturing',
 '32':'consumer','33':'manufacturing','35':'utilities','38':'services',
 '41':'construction','42':'construction','45':'retail','46':'wholesale','47':'retail',
 '49':'transport','50':'transport','51':'transport','52':'transport','55':'services',
 '58':'software','59':'content','60':'content','61':'telecom','62':'software',
 '63':'platform','64':'investment','65':'insurance','66':'investment','68':'realestate',
 '70':'services','71':'services','72':'services','73':'services','74':'services',
 '75':'services','76':'services','85':'services','90':'content','91':'services',
 '95':'services','96':'services',
}

def opening(text):
    # Do not scan risk/industry outlook/subsidiary tables for the issuer's business.
    return re.split(r'(?m)^##\s*2\.', text or '')[0][:10000]

def classify(row):
    code=str(row.get('industryCode') or '')
    name=row['name']; intro=opening(row.get('text'))
    own=sentence(row, max_length=1000)
    first=intro[:2000]
    if '기업인수목적' in name: return 'spac','name'
    if re.search('인프라투융자', name): return 'infrastructure','name'
    if re.search('부동산투자|리츠|리얼티',name): return 'reit','name'
    if (code.startswith('64') and '홀딩스' in name) or code=='64992' or re.search(r'당사는.{0,80}(?:순수지주|지주회사로)', first):
        return ('financial_holding' if re.search('금융지주', name) or re.search(r'(?<!비)금융지주회사법', first) else 'holding'),'industry'
    if row['corpCode'] in OVERRIDES:
        model,phrase=OVERRIDES[row['corpCode']]
        if phrase in intro: return model,'overview'
    if code.startswith('641'): return 'bank','industry'
    if code=='64913': return 'card','industry'
    if code=='64911': return 'credit','industry'
    if code.startswith('64') and '신탁' in name: return 'trust','name'
    if code.startswith('64') and re.search('송금',first): return 'payment','overview'
    if code.startswith('662'): return 'insurance_agency','industry'
    if code.startswith('661') and '증권' in name: return 'securities','name'
    if code.startswith('66') and re.search('결제|송금|페이', first+name): return 'payment','overview'
    if code.startswith('6612'): return 'securities','industry'
    if code.startswith(('70','21')):
        if re.search('진단|검사 서비스|유전자 분석', own): return 'diagnostics','overview'
        if re.search('임상시험수탁|CRO|시험대행',own): return 'research_service','overview'
        if re.search('위탁생산|CDMO|CMO',own) and not re.search('신약.*개발',own): return 'cdmo','overview'
        if re.search('신약개발|신약 개발|신약연구|ADC|기술이전|치료제.{0,40}개발|백신.{0,100}개발',own): return 'biotech','overview'
        if code.startswith('70'): return 'bio_research','industry'
    if code.startswith('261'):
        if re.search('태양광',own): return 'electrical','overview'
        if re.search('PSU|전원공급',own): return 'electrical','overview'
        if re.search('설계 자산|설계자산|Silicon Intellectual|반도체 IP',own): return 'semiconductor_ip','overview'
        if re.search('소재|코팅|부품|히터블럭',own): return 'industrial_parts','overview'
        if re.search('장비.{0,50}(판매|제조|사업)',own): return 'equipment','overview'
        if re.search('패키징|테스트|설계자산|설계 지원|디자인하우스|IP 사업',own): return 'semiconductor_services','overview'
        if re.search('LED|발광|광반도체',own): return 'electronics','overview'
        return ('semiconductor' if re.search('반도체|DRAM|NAND|팹리스|파운드리|MCU',own) else 'electronics'),'industry'
    if code.startswith('282'): return 'battery','industry'
    if code in ('31114','311'): return 'industrial_parts','industry'
    if code.startswith('311'): return 'shipbuilding','industry'
    if code.startswith('313') or code=='31910': return 'aerospace','industry'
    if code.startswith('5821'): return 'game','industry'
    if code.startswith('581'): return 'content','industry'
    if code.startswith('20423'): return 'cosmetics','industry'
    if code.startswith(('272','273')):
        if re.search('의료|세포|진단',own): return 'medical','overview'
        return 'optical','industry'
    if code.startswith('85'): return 'education','industry'
    if code.startswith('713'): return 'advertising','industry'
    if code.startswith('72'): return 'engineering','industry'
    if code.startswith('63'):
        if re.search('콘텐츠|웹툰|웹소설|음악',own): return 'content','overview'
        if re.search('솔루션|소프트웨어|IT 서비스',own): return 'software','overview'
        if re.search('상담|콜센터',own): return 'services','overview'
    return DIVISIONS.get(code[:2], 'unknown'),'industry'

def sentence(row, max_length=200):
    # Only the issuer's FIRST self-description. Searching later to find a short
    # quote accidentally selected a subsidiary's '당사' (e.g. Orion film business).
    text=opening(row.get('text'))
    text=re.split(r'\[주요 종속회사\]|\[주요 자회사\]',text)[0]
    for para in text.splitlines():
        if '|' in para or para.startswith(('#','[')): continue
        match=re.search(r'당사(?:는|의| 및|와)|당 그룹|본 회사',para)
        if not match or match.start()>60: continue
        para=para[match.start():]
        s=re.split(r'(?<=다\.)\s*',para)[0].strip()
        if not 35 <= len(s) <= max_length: return ''
        if not re.search('제조|생산|판매|개발|공급|서비스|영위|운영',s): return ''
        if re.search(r'수립|가능합니다|추진|기재|다음과|상기|이러한|아래와|용어|기술 우위|최초|최고|최대|선도|전망|예상|계획|목표|경쟁사|산업은|시장[은의]|설립|취득|인수|분할|중단|철수|수 있을|기대',s): return ''
        if re.search(r'\d[\d,.]*\s*(?:억|조|%|백만|천원)',s): return ''
        return s
    return ''

def products(row):
    result=[]
    for p in row.get('products') or []:
        name=p.get('name','').strip(); evidence=p.get('evidence','')
        if name and evidence and evidence in (row.get('text') or ''):
            result.append({'name':name,'evidence':evidence})
    return result[:8]

def build(rows):
    companies={}; counts=collections.Counter()
    for row in rows:
        key,basis=classify(row)
        quote=sentence(row) if key not in ('holding','financial_holding') else ''
        ps=products(row)
        record={'name':row['name'],'model':key,'basis':basis,'summary':quote,
                'models':[key], 'products':ps,'year':row.get('year'),'receipt':row.get('receipt'),
                'documentId':row.get('documentId'),'hasDocument':bool(row.get('text'))}
        note=NOTES.get(row['corpCode'])
        if note:
            for phrase in note['evidence']:
                assert phrase in (row.get('text') or ''), (row['corpCode'], phrase)
            record.update(summary=note['summary'],models=note['models'],model=note['models'][0],basis='reviewed',evidence=note['evidence'])
            if note.get('labels'): record['products']=[{'name':v,'evidence':note['evidence'][0]} for v in note['labels']]
            key=record['model']
        companies[row['corpCode']]=record
        counts[key]+=1
        if quote: assert quote in row['text'], row['corpCode']
        assert key in MODELS
    return {'schema':1,'asOf':datetime.now(ZoneInfo('Asia/Seoul')).date().isoformat(),'models':MODELS,'companies':companies},counts

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--output',default=str(ROOT/'investment_ontology_serverpod_flutter/assets/overview/companies.json'))
    args=parser.parse_args();rows=[json.loads(l) for l in open(args.input)]
    data,counts=build(rows); out=pathlib.Path(args.output);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
    report={'companies':len(rows),'models':dict(sorted(counts.items())),
      'withDocument':sum(bool(r.get('text')) for r in rows),
      'withVerbatimSummary':sum(bool(r['summary']) and r['basis']!='reviewed' for r in data['companies'].values()),
      'withReviewedSummary':sum(r['basis']=='reviewed' for r in data['companies'].values()),
      'withSourceMatchedProducts':sum(bool(r['products']) for r in data['companies'].values()),
      'withCompanyFacts':sum(bool(r['summary'] or r['products']) for r in data['companies'].values()),
      'industryExplanationOnly':sum(not (r['summary'] or r['products']) for r in data['companies'].values()),
      'assetBytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}
    audit=ROOT/'outputs/overview-rollout';audit.mkdir(parents=True,exist_ok=True)
    (audit/'coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    (audit/'classification.tsv').write_text('corpCode\tname\tmodel\tbasis\tsummary\n'+'\n'.join('\t'.join([code,r['name'],r['model'],r['basis'],r['summary']]) for code,r in data['companies'].items())+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
