import json,pathlib,hashlib,re,datetime,urllib.parse
src=pathlib.Path('/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/source-completeness-20261003/remaining_source_validation/ipo-history-nine')
root=pathlib.Path.cwd(); server=root/'investment_ontology_serverpod_server'; out=root/'outputs/own-audit-source-validation'
proofs=json.loads((src/'own-annual23-period-basis-original-proof.json').read_text())[:20]
old=json.loads((server/'assets/issuer_documents/verified_dart_documents.json').read_text()); docs=[]; ledger=[]
for r in proofs:
 folder=src/r['receipt']; body=(folder/'statement.txt').read_text(); opinion=(folder/'opinion.txt').read_text(); shell=(folder/'shell.html').read_text(); detail=json.loads((folder/'source-proof.json').read_text())
 ss={s['role']:s for s in r['sources']}
 for role,file in [('shell','shell.html'),('own-statement','statement.html'),('own-audit-opinion','opinion.html')]:
  assert hashlib.sha256((folder/file).read_bytes()).hexdigest()==ss[role]['sha256']; assert ss[role]['URI']==ss[role]['responseURI']; assert ss[role]['httpStatus']==200
 assert set(re.findall(r"openCorpInfo(?:New)?\('(\d{8})'",shell))=={r['corpCode']}
 current=body[:500]; dates=re.findall(r'(20\d{2})년\s*(\d{1,2})월\s*(\d{1,2})일',current)
 assert ['%s-%02d-%02d'%(y,int(m),int(d)) for y,m,d in dates[:2]]==[r['periodStart'],r['periodEnd']]
 assert ('연 결 재 무 제 표' in current)==(r['basis']=='CFS'); assert str(r['year']) in opinion[:1600]
 issuer=re.search(r'표\s+(.+?)\s+제\s*\d',current).group(1).strip(); issuer=issuer.split(' (구,')[0]
 period=re.search(r'20\d{2}년.*?까 지|20\d{2}년.*?까지',current).group(0)
 pub=re.search(r'(20\d{2})\.(\d{2})\.(\d{2})\s*$',detail['originalListRow']); assert pub
 node=dict(urllib.parse.parse_qsl(urllib.parse.urlparse(ss['own-statement']['URI']).query))
 saved=datetime.datetime.fromtimestamp((folder/'statement.html').stat().st_mtime,datetime.UTC).isoformat()
 m={'corpCode':r['corpCode'],'title':f'{issuer} {r["year"]}년 {"연결" if r["basis"]=="CFS" else "별도"} 감사보고서 재무제표 첨부(일부)','documentType':'auditReport','provider':'DART','providerReceipt':r['receipt'],'providerDocumentId':None,'periodStart':r['periodStart'],'periodEnd':r['periodEnd'],'publishedAt':'-'.join(pub.groups()),'officialUrl':ss['own-statement']['URI'],'sha256':ss['own-statement']['sha256'],'issuerQuote':issuer,'periodQuote':period,'numericState':'notExtracted','financialValues':None,'publicContent':'linkOnly'}
 p={'fileSavedAt':saved,'timestampEvidence':'local retrieved statement file mtime; exact GET completion time not captured','readScope':'printed own issuer, current annual cover dates and independent audit opinion; full notes not reviewed','periodProof':'printed body dates and issuer; no receipt-date or filename inference','collectorScope':'exact financial statement appendix and official issuer shell; not whole original or separate audit-opinion node','shellUrl':ss['shell']['URI'],'shellSha256':ss['shell']['sha256'],'shellCorpCode':r['corpCode'],'node':node}
 docs.append({'metadata':m,'proof':p}); ledger.append({**r,'verifiedSourceSHA':True,'timestampEvidence':p['timestampEvidence'],'ingested':False})
(out/'verified-own20-ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n')
print('SHA / issuer / period / basis verified',len(docs),'own sources; no source or database mutation')
