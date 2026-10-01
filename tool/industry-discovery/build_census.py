"""Full-universe ledger. Presence/evidence checks are not semantic accuracy."""
import argparse, collections, csv, json, pathlib
p=argparse.ArgumentParser()
p.add_argument('--snapshot',required=True)
p.add_argument('--corpus',required=True)
p.add_argument('--output',required=True)
a=p.parse_args();out=pathlib.Path(a.output);out.mkdir(parents=True,exist_ok=True)
snapshot=json.load(open(a.snapshot));corpus={c['corpCode']:c for c in json.load(open(a.corpus))}
registered={c['corpCode']:c for c in snapshot['activities'] if c.get('classificationBasis') in ('ksic','unclassified')}
filing=collections.defaultdict(list)
for item in snapshot['activities']:
 if item.get('classificationBasis')=='filing':filing[item['corpCode']].append(item)
assert len(registered)==snapshot['listedCompanyCount']
assert set(registered)==set(corpus), 'Every listed issuer must have a fetch result'
rows=[];sources=[];sectors=collections.defaultdict(lambda:collections.Counter())
for code,c in sorted(registered.items(),key=lambda r:r[1]['companyName']):
 d=corpus[code];items=filing[code]
 if not d['documentAvailable']:state='공시 본문 미확보'
 elif items:state='사업 분류 일부 있음'
 elif c.get('industryCode')=='64992':state='지주회사 직접 사업 분류 제외'
 else:state='본문 있으나 사업 분류 없음'
 for item in items:
  same_receipt=d.get('receipt')==item['rceptNo']
  exact=same_receipt and item['evidence'] in d['text']
  sources.append({'기업코드':code,'기업명':c['companyName'],'분야':item['industryName'],'세부사업':item['productName'],'공시접수번호':item['rceptNo'],'원문일치':exact,'근거':item['evidence']})
 rows.append({'기업코드':code,'기업명':c['companyName'],'등록분야':c['industryName'],'등록업종':c['productName'],'점검상태':state,'사업분야':' / '.join(sorted({i['industryName'] for i in items})),'세부사업':' / '.join(sorted({i['productName'] for i in items})),'회계연도':d.get('year',''),'공시접수번호':d.get('receipt',''),'공시링크':('https://dart.fss.or.kr/dsaf001/main.do?rcpNo='+d['receipt']) if d.get('receipt') else '', '의미검증':'전수 의미 검증 미완료'})
 sectors[c['industryName']]['등록 기업']+=1
 sectors[c['industryName']][state]+=1
for name,records in [('companies.csv',rows),('evidence.csv',sources)]:
 with (out/name).open('w',encoding='utf-8-sig',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(records[0]));w.writeheader();w.writerows(records)
summary={'listed':len(rows),'with_document':sum(c['documentAvailable'] for c in corpus.values()),'with_activity':len([v for v in filing.values() if v]),'without_activity':len(rows)-len([v for v in filing.values() if v]),'evidence_rows':len(sources),'evidence_verbatim':sum(s['원문일치'] for s in sources),'computed_at':snapshot['computedAt'],'rule_version':snapshot['ruleVersion'],'states':dict(collections.Counter(r['점검상태'] for r in rows)),'semantic_review_complete':False}
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
lines=['# 상장사 사업 분류 전수 점검', '',f"조회 시점: {snapshot['computedAt']} / 규칙 버전 {snapshot['ruleVersion']}", '',f"상장사 {summary['listed']:,}곳 전부를 명단 대조하고 각 기업의 저장 공시를 조회했다. 본문 확보 {summary['with_document']:,}곳, 사업 분류가 하나 이상 있는 기업 {summary['with_activity']:,}곳, 사업 분류가 없는 기업 {summary['without_activity']:,}곳이다.", '', '**전수 조회와 분류의 완성은 다르다.** 사업이 하나라도 잡힌 기업도 주력 사업·복수 사업 전체를 검증한 상태는 아니다. 원문 일치는 출처 검증이며 의미상 정확도 지표가 아니다. 모든 기업을 사람이 정독했다는 뜻이 아니다.', '',f"API 분류 근거 {summary['evidence_rows']}건 중 동일 접수번호 원문과 일치한 근거 {summary['evidence_verbatim']}건.", '', '## 등록 분야별 누락', '', '| 등록 분야 | 전체 | 사업 분류 일부 있음 | 사업 분류 없음 |', '|---|---:|---:|---:|']
for name,n in sorted(sectors.items()):
 count=n['등록 기업'];done=n['사업 분류 일부 있음'];lines.append(f'| {name} | {count} | {done} | {count-done} |')
lines+=['','`companies.csv`는 모든 상장사의 누락 없는 점검표, `evidence.csv`는 현재 화면에 노출하는 공시 기반 사업 근거다. 등록 분야별 수치는 해당 기업에 어느 분야든 사업 분류가 존재하는지 집계한다. 공시 수집 시점과 운영 DB의 최신 상장사 변경은 별도로 갱신해야 한다.']
(out/'README.md').write_text('\n'.join(lines)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
