"""Audit every listed issuer and every visible classification, never a sample."""
import argparse,collections,csv,json,pathlib
p=argparse.ArgumentParser();p.add_argument('--snapshot',required=True);p.add_argument('--corpus',required=True);p.add_argument('--output',required=True);p.add_argument('--kind-source');p.add_argument('--companies');p.add_argument('--issuer-source');a=p.parse_args()
x=json.load(open(a.snapshot));corpus={r['corpCode']:r for r in json.load(open(a.corpus))};out=pathlib.Path(a.output);out.mkdir(parents=True,exist_ok=True)
raw={r['corpCode']:r for r in x['activities'] if r['classificationBasis'] in ['ksic','unclassified']};visible=collections.defaultdict(list);issues=[];source_rows=[]
for r in x['activities']:
 if r['classificationBasis'] in ['ksic','unclassified']:continue
 visible[r['corpCode']].append(r)
 if r['role'].startswith(('ksic:','registered:')):issues.append(['raw_navigation',r['corpCode'],r['role']])
 if r['classificationBasis'] in ['filing','filing_activity']:
  c=corpus[r['corpCode']];exact=c.get('receipt')==r['rceptNo'] and r['evidence'] in c['text']
  if not exact:issues.append(['evidence_mismatch',r['corpCode'],r['productKey']])
  source_rows.append(dict(기업코드=r['corpCode'],기업명=r['companyName'],분야=r['industryName'],사업군=r['groupName'],제품=r['productName'],근거종류=r['classificationBasis'],원문일치=exact,근거=r['evidence'],공시='https://dart.fss.or.kr/dsaf001/main.do?rcpNo='+r['rceptNo']))
kind_rows=[];kind_products=set();kind_all=set();kind_source=json.load(open(a.kind_source)) if a.kind_source else None
company_codes={r['corpCode']:r['stockCode'] for r in json.load(open(a.companies))} if a.companies else {}
kind_by={r['stockCode']:r for r in kind_source['rows']} if kind_source else {}
for code,items in visible.items():
 for r in items:
  if not r['classificationBasis'].startswith('kind_'):continue
  src=kind_by.get(company_codes.get(code));exact=bool(src and ('주요제품: '+src['products']+'\n') in r['evidence'] and (src['name']+' ('+src['stockCode']+')') in r['evidence'])
  if not exact:issues.append(['kind_evidence_mismatch',code,r['productKey']])
  kind_all.add(code)
  if r['classificationBasis']=='kind_product':kind_products.add(code)
  kind_rows.append(dict(기업코드=code,기업명=r['companyName'],분야=r['industryName'],사업군=r['groupName'],제품=r['productName'],근거종류=r['classificationBasis'],원문일치=exact,근거=r['evidence'],원문=kind_source['sourceUrl']))
issuer_rows=[];issuer_codes=set()
issuer_by={r['corpCode']:r for r in json.load(open(a.issuer_source))} if a.issuer_source else {}
for code,items in visible.items():
 for r in items:
  if r['classificationBasis']!='issuer_source':continue
  src=issuer_by.get(code);exact=bool(src and src['evidence'] in r['evidence'] and src['sourceUrl'] in r['evidence'])
  if not exact:issues.append(['issuer_evidence_mismatch',code,r['productKey']])
  issuer_codes.add(code)
  issuer_rows.append(dict(기업코드=code,기업명=r['companyName'],사업군=r['groupName'],원문일치=exact,근거=r['evidence'],원문=src['sourceUrl'] if src else ''))
rows=[];sectors=collections.defaultdict(set);groups=set();detailed=set();broad=set()
for code,r in raw.items():
 items=visible[code]
 if not items:issues.append(['missing',code,''])
 for i in items:
  sectors[i['industryKey']].add(code);groups.add((i['industryKey'],i['role']))
  if i['classificationBasis']=='filing':detailed.add(code)
  if i['classificationBasis'] in ['filing','filing_activity']:broad.add(code)
 status='발행사·운용사 원문 근거' if code in issuer_codes else '거래소 제품 연결' if code in kind_products and code not in detailed else '거래소 제품 원문 및 등록 업종' if code in kind_all and code not in broad else '제품·서비스 공시 근거' if code in detailed else '사업군 공시 근거' if code in broad else '공식 등록 근거'
 rows.append(dict(기업코드=code,기업명=r['companyName'],등록코드=r.get('industryCode'),분야=' / '.join(sorted({i['industryName'] for i in items})),사업군=' / '.join(sorted({i['groupName'] for i in items})),분류근거=status,세부제품=' / '.join(sorted({i['productName'] for i in items if i['classificationBasis']=='filing'})),등록근거=r['evidence'],거래소주요제품=kind_by.get(company_codes.get(code),{}).get('products',''),근거종류=' / '.join(sorted({i['classificationBasis'] for i in items}))))
assert len(raw)==x['listedCompanyCount']
for name,data in [('all-companies.csv',rows),('all-filing-evidence.csv',source_rows),('all-kind-evidence.csv',kind_rows),('all-issuer-evidence.csv',issuer_rows)]:
 with (out/name).open('w',encoding='utf-8-sig',newline='') as f:
  if not data:continue
  w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
summary=dict(rule_version=x['ruleVersion'],listed=len(raw),classified=len([v for v in visible.values() if v]),business_groups=len(groups),registered_code_count=len({r['productKey'] for r in raw.values()}),product_evidence_companies=len(detailed),activity_or_product_evidence_companies=len(broad),no_filing_evidence_companies=len(raw)-len(broad),registration_only_companies=sum(all(i['classificationBasis']=='registered_activity' for i in visible[code]) for code in raw),offering_source_companies=len(broad | kind_all | issuer_codes),product_mapped_companies=len(detailed | kind_products | issuer_codes),kind_source_matched=sum(v in kind_by for v in company_codes.values()),kind_source_products_available=sum(bool(kind_by.get(v,{}).get('products','').strip()) for v in company_codes.values()),kind_product_mapped_companies=len(kind_products),kind_visible_companies=len(kind_all),kind_rows=len(kind_rows),kind_source_verbatim=sum(r['원문일치'] for r in kind_rows),source_rows=len(source_rows),source_verbatim=sum(r['원문일치'] for r in source_rows),issuer_source_companies=len(issuer_codes),issuer_rows=len(issuer_rows),issuer_verbatim=sum(r['원문일치'] for r in issuer_rows),issues=issues,all_company_semantic_review_complete=False)
(out/'universe-audit.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
(out/'universe-audit.md').write_text('# 전 상장사 분류 검증\n\n'+ '\n'.join(f'- {k}: {v}' for k,v in summary.items() if k!='issues')+'\n\n전체 기업과 원문 일치를 자동 대조했다. 전사 사업내용 정독과 의미상 완전성 검증을 대신하지 않는다. 세부 제품, 공시로 확인된 사업군, 공식 등록 근거를 구분한다. all-companies.csv에 모든 기업의 결과, all-filing-evidence.csv에 모든 공시 근거를 기록했다.\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
if issues:raise SystemExit(1)
