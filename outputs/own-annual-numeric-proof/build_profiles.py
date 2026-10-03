import json,pathlib,re,shutil,hashlib
root=pathlib.Path.cwd();s=root/'investment_ontology_serverpod_server';out=root/'outputs/own-annual-numeric-proof';src=pathlib.Path('/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/source-completeness-20261003/remaining_source_validation/ipo-history-nine')
rows=json.load(open(root/'outputs/own-audit-source-validation/verified-own20-ledger.json'));profiles=[];cells=[]
metrics=['assets','liabilities','equity','revenue','operatingProfit','netProfit','operatingCashFlow','propertyPlantEquipmentAcquisitions']
for d in rows:
 receipt=d['receipt'];ts=json.load(open(out/(receipt+'-tables.json')));tis=[7,10,16] if receipt=='20240328001877' else [6,9,15]
 for ti in tis:
  assert '(단위:원)' in re.sub(r'\s','',str(ts[ti-1])),(receipt,ti,'unit not printed')
 source={v['role']:v for v in d['sources']}; p={'corpCode':d['corpCode'],'providerReceipt':receipt,'basis':d['basis'],'periodKind':'ownAnnual','auditStatus':'audited','auditProof':'해당 연도의 자체 감사보고서 · 비교기간은 미추출','accountingStandard':d['accountingStandard'],'auditOpinionUrl':source['own-audit-opinion']['URI'],'auditOpinionSha256':source['own-audit-opinion']['sha256'],'contextTables':[{'tableOrdinal':i,'rows':ts[i]} for i in [0,1,tis[0]-1,tis[1]-1,tis[2]-1]],'accounts':[],'unextractedMetrics':[],'auditCell':None}
 for n,ti in enumerate(tis):
  chosen = [r for r,cs in enumerate(ts[ti]) if cs and re.sub(r'\s','',cs[0]) in ['자산총계','부채총계','자본총계']] if n==0 else [1,5, next(r for r,cs in enumerate(ts[ti]) if re.search('당기순(이익|손실)',re.sub(r'\s','',cs[0])))] if n==1 else [1]+[r for r,cs in enumerate(ts[ti]) if re.sub(r'\s','',cs[0])=='유형자산의취득']
  assert len(chosen)==(2 if n==2 and d['accountingStandard']=='Korean-GAAP' else [3,3,2][n]) if d['accountingStandard']!='Korean-GAAP' else True
  if n==1 and d['corpCode']=='01564514' and d['accountingStandard']=='Korean-GAAP': chosen[1]=28
  if n==1 and d['corpCode']=='01867688': chosen=[1,3,10]
  if n==1 and d['corpCode']=='01876251': chosen=[1,3,10] if d['year']==2025 else [1,31,47]
  if n==2 and d['accountingStandard']=='Korean-GAAP':chosen=[1,None]
  for pos,ri in enumerate(chosen):
   metric=metrics[[0,3,6][n]+pos]
   if ri is None:p['unextractedMetrics'].append({'metric':metric,'reason':'noPrimaryPrintedTotalCell; component acquisitions not summed'});continue
   cs=ts[ti][ri]; ci=3 if n==0 and d['corpCode']=='01586923' else 1 if n==1 and d['corpCode']=='01867688' or n==2 and pos==1 and d['corpCode']=='01867688' else 3 if n==2 and pos==0 and d['corpCode']=='01876251' and d['year']==2025 else 2
   raw=cs[ci];compact=re.sub(r'\s','',raw); assert re.fullmatch(r'\(?-?[\d,]+\)?',compact),(receipt,metric,cs,ci)
   value=int(compact.replace(',','').strip('()'))*(-1 if compact.startswith('(') else 1)
   a={'metric':metric,'statement':['BS','IS','CF'][n],'amountScope':'instant' if n==0 else 'cumulative','cashDirection':'outflow' if pos==1 and n==2 else None,'incomeDirection':'printedSigned' if n==1 and pos>0 else None,'tableOrdinal':ti,'rowOrdinal':ri,'cellOrdinal':ci,'accountLabel':cs[0],'headerCells':ts[ti][0],'rowLength':len(cs),'printedSignConvention':'positiveOutflowMagnitude' if n==2 and pos==1 and value>0 else 'signedAmount'}
   p['accounts'].append(a);cells.append({'corpCode':d['corpCode'],'providerReceipt':receipt,'basis':d['basis'],'periodStart':d['periodStart'],'periodEnd':d['periodEnd'],'accountingStandard':d['accountingStandard'],'officialUrl':d['statementURI'],'sha256':d['statementSHA256'],**a,'printedAmount':raw,'amountInteger':str(value),'rowCells':cs})
 values={r['metric']:int(r['amountInteger']) for r in cells if r['providerReceipt']==receipt};assert values['assets']==values['liabilities']+values['equity'],receipt
 profiles.append(p)
 for role,name in [('shell','shell.html'),('own-statement','statement.html')]:
  raw=(src/receipt/name).read_bytes();assert hashlib.sha256(raw).hexdigest()==source[role]['sha256'];shutil.copyfile(src/receipt/name,s/'test/fixtures/issuer_documents/dart'/f'{receipt}-own-{name}')
(s/'lib/src/ontology/research/own_annual_financials_profiles.dart').write_text('/// Exact current annual statement locations; no monetary literal values.\nabstract final class OwnAnnualFinancialsProfiles {\nstatic const rows = <Map<String,dynamic>>'+json.dumps(profiles,ensure_ascii=False,indent=2)+';\n}\n')
(s/'test/fixtures/issuer_documents/dart/own-annual-direct-current-cells.json').write_text(json.dumps(cells,ensure_ascii=False,indent=2));(out/'profiles-reviewed.json').write_text(json.dumps(profiles,ensure_ascii=False,indent=2));print(len(profiles),'own annual groups',len(cells),'direct cells')
