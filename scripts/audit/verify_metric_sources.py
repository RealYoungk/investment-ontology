"""Independent DB-to-API reconciliation. No application selection code imported."""
import json,pathlib,re,collections
ROOT=pathlib.Path('outputs/metric-source-audit'); API=ROOT/'api'
PL=['incomeStatement','comprehensiveIncome'];BS=['balanceSheet'];CF=['cashFlow']
C={
'revenue':('ifrs-full_Revenue',PL,['매출액']),
'operatingIncome':('dart_OperatingIncomeLoss',PL,['영업이익(손실)','영업이익']),
'netIncome':('ifrs-full_ProfitLoss',PL,['당기순이익(손실)','반기순이익(손실)','분기순이익(손실)','당기순이익','반기순이익','분기순이익']),
'netIncomeOwners':('ifrs-full_ProfitLossAttributableToOwnersOfParent',PL,[]),
'cash':('ifrs-full_CashAndCashEquivalents',BS,['현금및현금성자산']),
'assets':('ifrs-full_Assets',BS,[]),'liabilities':('ifrs-full_Liabilities',BS,[]),'equity':('ifrs-full_Equity',BS,['자본총계']),'equityOwners':('ifrs-full_EquityAttributableToOwnersOfParent',BS,[]),
'operatingCashFlow':('ifrs-full_CashFlowsFromUsedInOperatingActivities',CF,['영업활동현금흐름']),
'capex':('ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities',CF,['유형자산의취득','유형자산취득']),
'noncontrollingInterest':('ifrs-full_NoncontrollingInterests',BS,[]),
'depreciationAmortisation':('ifrs-full_AdjustmentsForDepreciationAndAmortisationExpense',CF,[]),
'depreciation':('ifrs-full_AdjustmentsForDepreciationExpense',CF,['감가상각비']),
'amortisation':('ifrs-full_AdjustmentsForAmortisationExpense',CF,['무형자산상각비']),
'interestDebtIncludingLeases':(None,BS,['총차입금(리스부채포함)','차입금및사채및리스부채합계'])}
def norm(x):return re.sub(r'\s+','',x)
actual={}; faults=[]; bases=0
for p in API.glob('*_*.json'):
 if p.stem.split('_')[-1] not in ('consolidated','separate'):continue
 d=json.loads(p.read_text());bases+=1
 for r in d['periods']:
  if r['reportId'] in actual:faults.append(['duplicate report',r['reportId']])
  actual[r['reportId']]=(d['corpCode'],d['fsDiv'],r)
checked=lines=0;unmatched=[]
for raw in open(ROOT/'raw.jsonl'):
 d=json.loads(raw);r=d['report'];rid=r['id'];facts=d['facts']
 if rid not in actual:
  unmatched.append(rid);continue
 corp,basis,a=actual.pop(rid);checked+=1
 for key in ['bsnsYear','reportCode','rceptNo']:
  if str(r[key])!=str(a[key]):faults.append([rid,key,r[key],a[key]])
 if corp!=d['corpCode'] or basis!=r['fsDiv']:faults.append([rid,'basis/company'])
 expected={}
 for key,(identifier,statements,names) in C.items():
  ids=[identifier]+({'revenue':['ifrs-full_RevenueFromContractsWithCustomers'],'operatingIncome':['ifrs-full_ProfitLossFromOperatingActivities']}.get(key,[]))
  candidates=[f for f in facts if f['accountId'] is not None and f['accountId'] in ids and f['statement'] in statements]
  if candidates:
   candidates.sort(key=lambda f:(ids.index(f['accountId']),statements.index(f['statement']),f['id']));chosen=candidates[0]
  else:
   candidates=[f for f in facts if f['accountId'] is None and f['statement'] in statements and norm(f['accountName']) in names]
   chosen=candidates[0] if len(candidates)==1 else None
  if chosen:expected[key]=chosen
 got={l['key']:l for l in a['lines']}
 totals=[expected.get(k) for k in ('assets','liabilities','equity')]
 invalid=False
 if all(t and t['amount'] is not None for t in totals) and len({t.get('currency') or 'KRW' for t in totals})==1:
  av,lv,ev=[int(t['amount']) for t in totals]
  invalid=abs(av-lv-ev)>max(1000,abs(av)//1000000)
 for key,l in got.items():
  should_block=invalid and key in ('assets','liabilities','equity','equityOwners')
  if bool(l.get('unavailableReason'))!=should_block:faults.append([rid,key,'integrity reason mismatch'])
 if set(got)!=set(expected):faults.append([rid,'account coverage',sorted(set(expected)-set(got)),sorted(set(got)-set(expected))])
 for key in set(got)&set(expected):
  x,y=got[key],expected[key];lines+=1
  for field,rawfield in [('factId','id'),('statement','statement'),('accountId','accountId'),('accountName','accountName'),('amount','amount'),('cumulativeAmount','cumulativeAmount'),('currency','currency')]:
   if str(x.get(field))!=str(y.get(rawfield)):faults.append([rid,key,field,x.get(field),y.get(rawfield)])
result={'bases':bases,'canonicalReports':checked,'selectedLines':lines,'sourceReportsAbsentFromApi':unmatched,'apiReportsAbsentFromSource':list(actual),'mismatches':faults}
(ROOT/'reconciliation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print({k:len(v) if isinstance(v,list) else v for k,v in result.items()})
if faults or actual or unmatched:raise SystemExit(1)
