"""Compile direct printed tokens/coordinates from one immutable corrected PDF text.

No optical correction, guessed values, fiscal aggregation, or report substitution.
Run from repository root. Independent ledger is an audit output, not parser input.
"""
from pathlib import Path
import hashlib
import json
import re
from datetime import datetime, timezone

root = Path(__file__).resolve().parents[2]
fixture = root / 'investment_ontology_serverpod_server/test/fixtures/issuer_documents/kbif_retrospective'
pdf = (fixture / 'corrected-20241115.pdf').read_bytes()
text_bytes = (fixture / 'corrected-20241115.txt').read_bytes()
assert hashlib.sha256(pdf).hexdigest() == 'f156281de6902b32ca7773eaad4cb5ba3b03869cffea9edba81371cb7f9f7e8a'
pages = text_bytes.decode().split('\f')
assert '2024년 11월 15일' in pages[0]
assert '케이비발해인프라투융자회사' in pages[265]
source = {}
for page in range(265, 270):
    for line_no, line in enumerate(pages[page-1].splitlines(), 1):
        matches = list(re.finditer(r'\(?\d{1,3}(?:,\d{3})+\)?|(?<!\S)-(?!\S)', line))
        if len(matches) != 5:
            continue
        label = line[:matches[0].start()].strip()
        source[(page, label)] = {'pageOrdinal': page, 'lineOrdinal': line_no,
            'accountLabel': label, 'rawLine': line,
            'tokens': [m.group() for m in matches],
            'characterSpans': [[m.start(), m.end()] for m in matches]}

def cell(page, label, column):
    r = source[(page, label)]
    return {'pageOrdinal': page, 'lineOrdinal': r['lineOrdinal'],
        'accountLabel': label, 'rawLine': r['rawLine'], 'tokenOrdinal': column,
        'characterSpan': r['characterSpans'][column], 'printedAmount': r['tokens'][column]}

specs = []
def group(name, page, lhs, labels, coefficient=1):
    specs.append((name, (page, lhs), [(coefficient, (page, l)) for l in labels]))
def cross(name, lhs, terms): specs.append((name, lhs, terms))
group('BS operating assets',266,'I. 운용자산',['(1) 현금및예치금','(2) 유가증권','(3) 대출채권'])
group('BS other assets',266,'II. 기타자산',['1. 미수이자','2. 선급이자'])
group('BS assets',266,'자산총계',['I. 운용자산','II. 기타자산'])
group('BS loan liabilities',266,'I. 차입부채',['1. 사채','2. 차입금'])
group('BS other liabilities',266,'II. 기타부채',['1. 자산보관보수미지급금','2. 자산운용보수미지급금','3. 일반사무보수미지급금','4. 미지급이익분배금','5. 미지급이자','6. 기타미지급금'])
group('BS liabilities',266,'부채총계',['I. 차입부채','II. 기타부채'])
group('BS equity',266,'자본총계',['I. 자본금','II. 이익잉여금'])
group('BS identity',266,'자산총계',['부채총계','자본총계'])
group('PL income',267,'I. 운용수익',['1. 이자수익','2. 대출채권평가이익'])
group('PL expenses',267,'II. 운용비용',['1. 이자비용','2. 자산보관보수','3. 자산운용보수','4. 일반사무보수','5. 기타비용','6. 유가증권평가손실'])
cross('PL NI',(267,'III. 당기순이익'),[(1,(267,'I. 운용수익')),(-1,(267,'II. 운용비용'))])
group('CF management inflows',268,'1. 자산운용활동 현금유입액',['가. 이자수입 유입액','나. 장기대여금의 회수'])
cross('CF management outflows',(268,'2. 자산운용활동 현금유출액'),[(-1,(p,l)) for p,l in [(268,'가. 자산운용보수 유출액'),(268,'나. 자산보관보수 유출액'),(268,'다. 일반사무보수 유출액'),(269,'라. 이자비용 유출액'),(269,'마. 기타비용 유출액')]])
group('CF management total',268,'I. 자산운용활동으로 인한 현금흐름',['1. 자산운용활동 현금유입액','2. 자산운용활동 현금유출액'])
group('CF financing inflows',269,'1. 재무활동 현금유입액',['가. 사채의 발행','나. 차입금 유입액'])
group('CF financing outflows',269,'2. 재무활동 현금유출액',['가. 분배금 유출액','나. 초과이익분배금 지급','다. 사채의 상환액','라. 차입금 상환액'],-1)
group('CF financing total',269,'II. 재무활동으로 인한 현금흐름',['1. 재무활동 현금유입액','2. 재무활동 현금유출액'])
cross('CF cash change',(269,'III. 현금의 증가 ( I + II )'),[(1,(268,'I. 자산운용활동으로 인한 현금흐름')),(1,(269,'II. 재무활동으로 인한 현금흐름'))])
group('CF cash roll',269,'V. 기말의 현금',['IV. 기초의 현금','III. 현금의 증가 ( I + II )'])
cross('CF BS cash numeric crosscheck',(269,'V. 기말의 현금'),[(1,(266,'1. 현금및현금성자산'))])

ce = []
for line_no, line in enumerate(pages[267].splitlines(),1):
    if not any(line.strip().startswith(l) for l in ['2022.07.01','2022.12.31','2023.01.01','2023.12.31','당기순이익','현금분배금']): continue
    matches = list(re.finditer(r'\(?\d{1,3}(?:,\d{3})+\)?',line))
    if len(matches)==2:
        matches = [None,*matches] if line.strip().startswith('당기순이익') else [matches[0],None,matches[1]]
    assert len(matches)==3
    ce.append([{'pageOrdinal':268,'lineOrdinal':line_no,'accountLabel':line.strip().split('  ')[0],
        'rawLine':line,'componentOrdinal':j,'characterSpan':None if m is None else [m.start(),m.end()],
        'printedAmount':None if m is None else m.group(),'missingRole':'printedBlankNotAmountFact' if m is None else None} for j,m in enumerate(matches)])
assert len(ce)==8
profiles=[]
for col,period,start,end,offset in [(1,'2023','2023-01-01','2023-12-31',4),(2,'2022H2','2022-07-01','2022-12-31',0)]:
    cells={};equations=[]
    def pin(pair):
        page,label=pair;k=f'{page}:{source[pair]["lineOrdinal"]}:{col}'
        cells[k]=cell(page,label,col);return k
    for name,lhs,terms in specs:equations.append({'name':name,'lhs':pin(lhs),'terms':[{'coefficient':s,'cellKey':pin(x)} for s,x in terms]})
    for j,row in enumerate(ce[offset:offset+4]):
        for component,v in enumerate(row):cells[f'CE:{j}:{component}']=v
        equations.append({'name':f'CE component sum {j}','lhs':f'CE:{j}:2','terms':[{'coefficient':1,'cellKey':f'CE:{j}:0'},{'coefficient':1,'cellKey':f'CE:{j}:1'}]})
    for component in range(3):equations.append({'name':f'CE roll {component}','lhs':f'CE:3:{component}','terms':[{'coefficient':1,'cellKey':f'CE:{j}:{component}'} for j in range(3)]})
    # Direct cross-statement checks, not a derived metric.
    for component,label in [(0,'I. 자본금'),(1,'II. 이익잉여금'),(2,'자본총계')]:equations.append({'name':f'CE BS close {component}','lhs':f'CE:3:{component}','terms':[{'coefficient':1,'cellKey':pin((266,label))}]})
    equations.append({'name':'CE PL profit','lhs':'CE:1:1','terms':[{'coefficient':1,'cellKey':pin((267,'III. 당기순이익'))}]})
    accounts=[]
    for metric,page,label in [('assets',266,'자산총계'),('liabilities',266,'부채총계'),('equity',266,'자본총계'),('fundOperatingIncome',267,'I. 운용수익'),('netProfit',267,'III. 당기순이익'),('assetManagementCashFlow',268,'I. 자산운용활동으로 인한 현금흐름')]:
        accounts.append({'metric':metric,'cellKey':pin((page,label)),'amountScope':'stockAtPeriodEnd' if page==266 else 'ownFiscalDuration','cashDirection':None})
    profiles.append({'periodStart':start,'periodEnd':end,'periodKind':'ownTwelveMonthFiscalYear' if col==1 else 'ownSixMonthFiscalYear','fiscalTerm':35 if col==1 else 34,'printedColumnOrdinal':col,'cells':cells,'equations':equations,'accounts':accounts})

ledger=json.loads((fixture/'independent-ledger.json').read_text())
conflicts=[]
for conflict in ledger['summaryDetailedConflicts']:
    col=['2023','2022H2','2022H1','2021H2'].index(conflict['period'])+1
    summary_label=conflict['label'];detail_label={'운용수익':'I. 운용수익','운용비용':'II. 운용비용'}.get(summary_label,summary_label)
    # Summary current 2024 income has a malformed token; bind each historical raw token explicitly.
    line_no,line=next((i,l) for i,l in enumerate(pages[264].splitlines(),1) if l.strip().startswith(summary_label))
    token=re.findall(r'\d{1,3}(?:,\d{3})+',line)[-4:][col-1]
    detail=cell(267 if summary_label in ['운용수익','운용비용'] else 266,detail_label,col)
    conflicts.append({'period':conflict['period'],'accountLabel':summary_label,
        'summary':{'pageOrdinal':265,'lineOrdinal':line_no,'rawLine':line,'printedAmount':token},'detailed':detail})
metadata={'corpCode':'01880801','title':'[정정]투자설명서(집합투자증권-회사형)','documentType':'prospectus','provider':'officialIR','providerReceipt':None,'providerDocumentId':None,'periodStart':'2021-07-01','periodEnd':'2023-12-31','publishedAt':'2024-11-15','officialUrl':'https://kbif.co.kr/upload/2024/11/20241115105341013630.pdf','sha256':hashlib.sha256(pdf).hexdigest(),'issuerQuote':'케이비발해인프라투융자회사','periodQuote':'제35기(2023.01.01~2023.12.31) / 제34기(2022.07.01~2022.12.31) / 제33기(2022.01.01~2022.06.30) / 제32기(2021.07.01~2021.12.31)','numericState':'notExtracted','financialValues':None,'publicContent':'linkOnly'}
proof={'downloadedAt':None,'verifiedAt':datetime.now(timezone.utc).isoformat(),'evidenceOrigin':'exact-local-original-from-official-source;downloadTimestampNotClaimed','readScope':'text and visual physical pages 265-269; correction date p1','periodProof':'printed audited fiscal terms 35/34/33/32; source range not fiscal duration'}
def signed(token):
    return None if token=='-' else int(token.strip('()').replace(',','')) * (-1 if token.startswith('(') else 1)
failure_total=cell(269,'2. 재무활동 현금유출액',4)
failure_components=[cell(269,l,4) for l in ['가. 분배금 유출액','나. 초과이익분배금 지급','다. 사채의 상환액','라. 차입금 상환액']]
failure_delta=signed(failure_total['printedAmount'])+sum(signed(c['printedAmount']) or 0 for c in failure_components)
assert failure_delta==3672767716
existing_manifest=json.loads((root/'investment_ontology_serverpod_server/assets/issuer_documents/verified_fund_documents.json').read_text())
existing=next((d for d in existing_manifest['documents'] if d['metadata']==metadata and d['proof'].get('verifiedAt')),None)
if existing:proof=existing['proof']
data={'metadata':metadata,'documentProof':proof,'textSha256':hashlib.sha256(text_bytes).hexdigest(),'sourceConflicts':conflicts,'profiles':profiles,
    'excludedFiscalPeriods':[{'periodStart':'2022-01-01','periodEnd':'2022-06-30','periodKind':'ownSixMonthFiscalYear','reason':'detailedCEAbsentInReviewedSection','accounts':[]},{'periodStart':'2021-07-01','periodEnd':'2021-12-31','periodKind':'ownSixMonthFiscalYear','reason':'CFfinancingOutflowComponentMismatchAndDetailedCEAbsent','quarantinedStatement':'CF','failurePrintedTotal':failure_total['printedAmount'],'failurePrintedComponents':[c['printedAmount'] for c in failure_components],'failureDifferenceInteger':str(failure_delta),'failureSourceCells':{'total':failure_total,'components':failure_components},'accounts':[]}]}
# Data here is direct source literals, never manually supplied accounting amounts.
body='// Direct printed-source coordinates compiled by tool/issuer_funds/compile_kbif_retrospective.py.\nabstract final class RetrospectiveFundProfiles {\n static const data = <String, dynamic>'+json.dumps(data,ensure_ascii=False,indent=2)+';\n}\n'
for target in ['investment_ontology_serverpod_server/lib/src/ontology/research/retrospective_fund_profiles.dart','investment_ontology_serverpod_flutter/lib/features/financials/retrospective_fund_profiles.dart']:(root/target).write_text(body)
manifest=root/'investment_ontology_serverpod_server/assets/issuer_documents/verified_fund_documents.json'
raw=json.loads(manifest.read_text());raw['documents']=[d for d in raw['documents'] if d['metadata']['officialUrl']!=metadata['officialUrl']]+[{'metadata':metadata,'proof':proof}];manifest.write_text(json.dumps(raw,ensure_ascii=False,indent=2)+'\n')
print('bound original PDF/text; profiles2; source conflicts',len(conflicts),'checks/profile',[len(p['equations']) for p in profiles])
