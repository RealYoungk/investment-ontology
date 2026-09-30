"""Independent Decimal oracle for all 23 header metrics; consumes reconciled inputs."""
import json,pathlib,decimal,math
D=decimal.Decimal;ROOT=pathlib.Path('outputs/metric-source-audit');fail=[];checked=0
actual=json.loads((ROOT/'derived.json').read_text())
def compute(data):
 ps=data['periods']; periods={(p['bsnsYear'],p['reportCode']):p for p in ps};last=ps[-1] if ps else None
 def line(p,k):return next((x for x in p['lines'] if x['key']==k),None) if p else None
 def val(p,k,cum=False):
  l=line(p,k)
  if not l or l.get('unavailableReason'):return None
  a=l.get('amount')
  if cum:
   if p['reportCode'] in ('annual','q1') or l['statement']=='cashFlow':a=l.get('cumulativeAmount',a)
   else:a=l.get('cumulativeAmount')
  return (D(a),l.get('currency') or 'KRW') if a is not None else None
 def same(vs):return all(x is not None for x in vs) and len({x[1] for x in vs})==1
 def ttm(k,p=last):
  if not p:return None
  if p['reportCode']=='annual':return val(p,k)
  y=p['bsnsYear'];code=p['reportCode'];vs=[val(periods.get((y-1,'annual')),k),val(p,k,True),val(periods.get((y-1,code)),k,True)]
  if not same(vs):return None
  ns=[abs(x[0]) if k=='capex' else x[0] for x in vs];n=ns[0]+ns[1]-ns[2]
  return None if k=='capex' and n<0 else (n,vs[0][1])
 def ratio(a,b):return a[0]/b[0] if same([a,b]) and b[0]>0 else None
 def add(vs,signs):return (sum(x[0]*s for x,s in zip(vs,signs)),vs[0][1]) if same(vs) else None
 def number(v):return v[0] if v else None
 cap=data.get('market',{}).get('marketCap');cap=(D(cap),'KRW') if cap is not None and D(cap)>0 else None
 niKey='netIncomeOwners' if data.get('fsDiv')=='consolidated' and (ttm('netIncomeOwners') is not None or ttm('netIncome') is None) else 'netIncome'
 eqKey='equityOwners' if data.get('fsDiv')=='consolidated' and val(last,'equityOwners') is not None else 'equity'
 ni=ttm(niKey);eq=val(last,eqKey);sales=ttm('revenue');op=ttm('operatingIncome');cash=val(last,'cash');ocf=ttm('operatingCashFlow');capex=ttm('capex');assets=val(last,'assets');totalEq=val(last,'equity')
 scale=assets is not None and assets[0]>=100000000
 owners=niKey=='netIncomeOwners' and eqKey=='equityOwners'
 fcf=add([ocf,(abs(capex[0]),capex[1]) if capex else None],[1,-1])
 da=ttm('depreciationAmortisation') or add([ttm('depreciation'),ttm('amortisation')],[1,1]);ebitda=add([op,da],[1,1])
 debt=val(last,'interestDebtIncludingLeases');minority=val(last,'noncontrollingInterest') if data.get('fsDiv')=='consolidated' else (D(0),'KRW')
 ev=add([cap,debt,minority,cash],[1,1,1,-1]) if scale else None
 def growth(k):
  before=periods.get((last['bsnsYear']-1,last['reportCode'])) if last else None
  r=ratio(ttm(k),ttm(k,before))
  return r-1 if r is not None else None
 mask=0
 for k,bit in [('revenue',1),('operatingIncome',2),('netIncome',4),('operatingCashFlow',8),('capex',16)]:
  if ttm(k) is not None:mask |= bit
 if data.get('fsDiv')=='consolidated' and ttm('netIncomeOwners') is not None:mask |= 4
 for k,bit in [('assets',32),('liabilities',64),('equity',384)]:
  if val(last,k) is not None:mask |= bit
 if data.get('fsDiv')=='consolidated' and val(last,'equityOwners') is not None:mask |= 128
 if (data.get('fsDiv')=='consolidated' and ttm('netIncomeOwners') is not None and val(last,'equityOwners') is not None) or (ttm('netIncome') is not None and val(last,'equity') is not None):mask|=512
 return {'_coverage':mask,'marketCap':number(cap),'per':ratio(cap,ni) if scale else None,'pbr':ratio(cap,eq) if scale else None,'psr':ratio(cap,sales) if scale else None,'por':ratio(cap,op) if scale else None,'pcf':ratio(cap,ocf) if scale else None,'roe':ratio(ni if owners else ttm('netIncome'),eq if owners else totalEq),'roa':ratio(ttm('netIncome'),assets),'operatingMargin':ratio(op,sales),'debtRatio':ratio(val(last,'liabilities'),totalEq),'revenueGrowth':growth('revenue'),'profitGrowth':growth(niKey),'cash':number(cash),'ocfMargin':ratio(ocf,sales),'capexRatio':ratio((abs(capex[0]),capex[1]) if capex else None,sales),'freeCashFlow':number(fcf),'fcfYield':ratio(fcf,cap) if scale else None,'ebitda':number(ebitda),'ebitdaMargin':ratio(ebitda,sales),'evEbitda':ratio(ev,ebitda),'evOperating':ratio(ev,op),'evSales':ratio(ev,sales),'peg':None}
for filename,metrics in actual.items():
 data=json.loads((ROOT/'api'/filename).read_text());expected=compute(data)
 for key,n in expected.items():
  if key.startswith('_'):continue
  checked+=1;m=metrics[key];v=m['value']
  okay=(v is None and n is None) or (v is not None and n is not None and math.isclose(v,float(n),rel_tol=1e-12,abs_tol=1e-9))
  if not okay:fail.append({'file':filename,'metric':key,'expected':str(n),'actual':v,'reason':m['missing']})
 # Missing reasons are a contract too: balance integrity failures must not
 # be collapsed into a generic unit warning even when the raw amount is zero.
 latest=data['periods'][-1] if data['periods'] else None
 assets=next((x for x in latest['lines'] if x['key']=='assets'),None) if latest else None
 if assets and assets.get('unavailableReason') and all((x.get('currency') or 'KRW')=='KRW' for p in data['periods'] for x in p['lines']):
  for key in ['per','por','pbr','psr','pcf','fcfYield']:
   if metrics[key]['missing']!=assets['unavailableReason']:
    fail.append({'file':filename,'metric':key,'expectedReason':assets['unavailableReason'],'actualReason':metrics[key]['missing']})
selection_errors=[]
rank={'q1':1,'halfYear':2,'q3':3,'annual':4}
for f in (ROOT/'api').glob('*.json'):
 if not f.stem.isdigit():continue
 a=json.loads(f.read_text());bases={}
 for basis in a['availableFsDivs']:
  b=json.loads((ROOT/'api'/(f.stem+'_'+basis+'.json')).read_text());p=b['periods'][-1]
  bases[basis]=((p['bsnsYear'],rank[p['reportCode']]),compute(b)['_coverage'])
 if not bases:chosen=None
 elif len(bases)==1:chosen=next(iter(bases))
 else:
  cp,cm=bases['consolidated'];sp,sm=bases['separate']
  chosen='separate' if sp>cp or (sp==cp and sm!=cm and (sm|cm)==sm) else 'consolidated'
 if chosen!=a.get('fsDiv'):selection_errors.append({'corpCode':f.stem,'expected':chosen,'actual':a.get('fsDiv')})
(ROOT/'selection.json').write_text(json.dumps(selection_errors,ensure_ascii=False,indent=2))
print('basis selection errors',len(selection_errors));print(selection_errors[:5])
(ROOT/'arithmetic.json').write_text(json.dumps({'bases':len(actual),'checked':checked,'mismatches':fail},ensure_ascii=False,indent=2))
print('bases',len(actual),'checks',checked,'mismatches',len(fail));print(fail[:8])
if fail or selection_errors:raise SystemExit(1)
