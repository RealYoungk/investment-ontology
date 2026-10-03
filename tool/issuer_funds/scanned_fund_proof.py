#!/usr/bin/env python3
"""Exact MKIF2021/2022 scan candidates; immutable dual OCR, explicit separators.
No database, posting, guessed digits, whole-font or note certification.
"""
import hashlib,json,re
from pathlib import Path
from extract_mapps import MANIFEST
GRAMMAR='grouped-integer-comma-or-dot-v1'
def integer(text):
    raw=text.strip()
    if raw=='-':return None
    if not re.fullmatch(r'(?:-?\d{1,3}(?:[.,]\s*\d{3})+|\(\d{1,3}(?:[.,]\s*\d{3})+\)|-?\d+)',raw):raise ValueError('invalidSeparatorGrammarOrDigitLetter: '+text)
    n=re.sub(r'[.,\s]','',raw)
    return -int(n[1:-1]) if n.startswith('(') else int(n)
def sign_form(text):return 'parentheses' if text.strip().startswith('(') else 'minus' if text.strip().startswith('-') else 'unsigned'

def proof(root,year):
    metadata=next(d['metadata'] for d in json.loads(MANIFEST.read_text())['documents'] if d['metadata']['corpCode']=='00435297' and d['metadata']['periodEnd']==f'{year}-12-31')
    pages={};source=[]
    for page in range(8,14):
        prefix=root/'rerender4400'/f'mkif{year}-{page:02}'
        scale=4400
        if year==2021 and page==11:prefix=root/'ce-page11-candidates'/'mkif2021-11-6600';scale=6600
        ko=Path(str(prefix)+'.ko-en.json');en=Path(str(prefix)+'.en.json');image=prefix.with_suffix('.png')
        pages[page]={'ko':json.loads(ko.read_text()),'en':json.loads(en.read_text())}
        source.append({'pageOrdinal':page,'renderScale':scale,'imageSha256':hashlib.sha256(image.read_bytes()).hexdigest(),'koSha256':hashlib.sha256(ko.read_bytes()).hexdigest(),'enSha256':hashlib.sha256(en.read_bytes()).hexdigest(),'imageFile':str(image),'koFile':str(ko),'enFile':str(en)})
    cells={}
    def cell(key,page,idx):
        ko=pages[page]['ko']['rows'][idx]
        matches=[(i,e) for i,e in enumerate(pages[page]['en']['rows']) if abs(e['y']-ko['y'])<.007 and abs(e['x']-ko['x'])<.035]
        if ko['text'].strip()=='-':
            cells[key]={'key':key,'pageOrdinal':page,'koRowIndex':idx,'enRowIndex':None,'ko':ko,'en':None,'enCandidates':[e for _,e in matches],'amountInteger':None,'acceptedSeparatorGrammar':GRAMMAR,'normalizationRole':'missingDashWitness;notAmountFact;rawOCRUnchanged'}
            return key
        if len(matches)!=1:raise ValueError(f'{key}: ambiguous independent number bbox')
        ei,en=matches[0]; a,b=integer(ko['text']),integer(en['text'])
        if a!=b or sign_form(ko['text'])!=sign_form(en['text']):raise ValueError(f'{key}: digitSequenceOrSignDisagreement')
        cells[key]={'key':key,'pageOrdinal':page,'koRowIndex':idx,'enRowIndex':ei,'ko':ko,'en':en,'amountInteger':None if a is None else str(a),'acceptedSeparatorGrammar':GRAMMAR,'normalizationRole':'derivedInteger;rawOCRUnchanged'}
        return key
    bs21={'operatingAssets':(8,32),'cash':(8,33),'loan':(8,34),'equityInvestment':(8,35),'otherAssets':(8,36),'interestReceivable':(8,37),'receivable':(8,38),'prepaid':(8,39),'prepaidExpense':(8,40),'assets':(8,52),'operatingLiabilities':(8,54),'longLoan':(8,56),'bond':(8,57),'otherLiabilities':(8,62),'feePayable':(8,58),'accrued':(8,59),'unearned':(8,60),'otherPayable':(8,61),'liabilities':(9,6),'capital':(9,20),'retained':(9,21),'equity':(9,24),'liabilityEquityTotal':(9,25)}
    bs22={'operatingAssets':(8,32),'cash':(8,36),'loan':(8,37),'equityInvestment':(8,38),'otherAssets':(8,43),'interestReceivable':(8,39),'receivable':(8,40),'prepaid':(8,41),'prepaidExpense':(8,42),'assets':(8,52),'operatingLiabilities':(8,53),'longLoan':(8,57),'bond':(8,56),'otherLiabilities':(8,62),'feePayable':(8,58),'accrued':(8,59),'unearned':(8,60),'otherPayable':(8,61),'liabilities':(9,5),'capital':(9,19),'retained':(9,21),'equity':(9,23),'liabilityEquityTotal':(9,24)}
    pl21={'fundOperatingIncome':29,'plInterest':21,'plDividend':22,'plOtherIncome':23,'plExpenses':30,'plManagement':24,'plCustody':25,'plAdmin':26,'plInterestExpense':27,'plOtherExpense':28,'plPretax':31,'netProfit':32}
    pl22={'fundOperatingIncome':21,'plInterest':22,'plDividend':23,'plOtherIncome':24,'plExpenses':28,'plManagement':29,'plCustody':30,'plAdmin':31,'plInterestExpense':35,'plOtherExpense':36,'plPretax':39,'netProfit':45}
    cf21={'assetIn':(12,29),'cfInterest':(12,31),'cfDividend':(12,32),'loanRecovery':(12,33),'cfOtherIncome':(12,34),'cfUnearned':(12,35),'assetOut':(12,50),'fundEquityAcquisition':(12,36),'fundLoanAcquisition':(12,37),'interestAcquisition':(12,38),'prepaidPayment':(12,39),'prepaidExpensePayment':(12,40),'managementPayment':(12,41),'custodyPayment':(12,42),'adminPayment':(12,43),'otherPayment':(12,44),'assetManagementCashFlow':(12,61),'financeIn':(12,63),'borrowings':(13,17),'bondIssue':(13,18),'shareIssue':(13,19),'financeOut':(13,23),'loanRepay':(13,25),'bondRepay':(13,26),'distribution':(13,27),'interestPayment':(13,28),'stockIssueCost':(13,29),'borrowingCost':(13,30),'financeNet':(13,36),'cashChange':(13,37),'openingCash':(13,38),'closingCash':(13,39)}
    cf22={'assetIn':(12,37),'cfInterest':(12,13),'cfDividend':(12,14),'loanRecovery':(12,15),'cfOtherIncome':(12,16),'assetOut':(12,42),'fundEquityAcquisition':(12,26),'fundLoanAcquisition':(12,27),'prepaidPayment':(12,28),'prepaidExpensePayment':(12,29),'managementPayment':(12,30),'custodyPayment':(12,31),'adminPayment':(12,32),'otherPayment':(12,33),'assetManagementCashFlow':(12,51),'financeIn':(12,52),'borrowings':(12,55),'bondIssue':(12,56),'financeOut':(13,17),'loanRepay':(13,19),'bondRepay':(13,20),'distribution':(13,21),'interestPayment':(13,22),'stockIssueCost':(13,23),'borrowingCost':(13,24),'financeNet':(13,31),'cashChange':(13,32),'openingCash':(13,33),'closingCash':(13,34)}
    for k,(pg,idx) in (bs21 if year==2021 else bs22).items():cell(k,pg,idx)
    for k,idx in (pl21 if year==2021 else pl22).items():cell(k,10,idx)
    cf=cf21 if year==2021 else cf22
    for k,(pg,idx) in cf.items():cell(k,pg,idx)
    checks=[]
    def eq(name,left,terms):
        a=integer(cells[left]['ko']['text']); seen=[];total=0
        for key,mul in terms:
            n=integer(cells[key]['ko']['text']);seen.append({'key':key,'coefficient':mul,'missing':n is None})
            if n is not None:total+=n*mul
        if a is None or a!=total:raise ValueError(f'{name}: equation mismatch {a} {total}')
        checks.append({'name':name,'left':left,'terms':seen,'difference':'0','missingTerms':sum(t['missing'] for t in seen)})
    def add(name,left,keys,coefficient=1):eq(name,left,[(k,coefficient) for k in keys])
    add('BS_operating_assets','operatingAssets',['cash','loan','equityInvestment'])
    add('BS_other_assets','otherAssets',['interestReceivable','receivable','prepaid','prepaidExpense'])
    add('BS_asset_total','assets',['operatingAssets','otherAssets'])
    add('BS_operating_liabilities','operatingLiabilities',['longLoan','bond'])
    add('BS_other_liabilities','otherLiabilities',['feePayable','accrued','unearned','otherPayable'])
    add('BS_liability_total','liabilities',['operatingLiabilities','otherLiabilities'])
    add('BS_equity_total','equity',['capital','retained'])
    add('BS_liability_equity_total','liabilityEquityTotal',['liabilities','equity'])
    add('BS_identity','assets',['liabilityEquityTotal'])
    add('PL_income','fundOperatingIncome',['plInterest','plDividend','plOtherIncome'])
    add('PL_expenses','plExpenses',['plManagement','plCustody','plAdmin','plInterestExpense','plOtherExpense'])
    eq('PL_pretax','plPretax',[('fundOperatingIncome',1),('plExpenses',-1)])
    add('PL_printed_pretax_equals_net_no_tax_amount_fact','netProfit',['plPretax'])
    add('CF_asset_in','assetIn',['cfInterest','cfDividend','loanRecovery','cfOtherIncome']+(['cfUnearned'] if year==2021 else []))
    add('CF_asset_out','assetOut',['fundEquityAcquisition','fundLoanAcquisition']+(['interestAcquisition'] if year==2021 else [])+['prepaidPayment','prepaidExpensePayment','managementPayment','custodyPayment','adminPayment','otherPayment'],-1)
    add('CF_asset_net','assetManagementCashFlow',['assetIn','assetOut'])
    add('CF_finance_in','financeIn',['borrowings','bondIssue']+(['shareIssue'] if year==2021 else []))
    add('CF_finance_out','financeOut',['loanRepay','bondRepay','distribution','interestPayment','stockIssueCost','borrowingCost'],-1)
    add('CF_finance_net','financeNet',['financeIn','financeOut'])
    add('CF_activities','cashChange',['assetManagementCashFlow','financeNet'])
    add('CF_roll','closingCash',['openingCash','cashChange'])
    add('CF_printed_BS_cash_number_only_not_equivalence','cash',['closingCash'])
    ce21=[[41,44,48],[42,None,49],[43,None,50],[None,46,51],[None,47,52],[53,54,55]]
    ce22=[[33,35,50],[None,36,51],[None,37,52],[38,39,53]]
    ce=ce21 if year==2021 else ce22
    for r,indices in enumerate(ce):
        for c,idx in enumerate(indices):
            if idx is not None:cell(f'CE_{r}_{c}',11,idx)
        add(f'CE_component_{r}',f'CE_{r}_2',[f'CE_{r}_{c}' for c in (0,1) if indices[c] is not None])
    for c in range(3):
        add(f'CE_component_roll_{c}',f'CE_{len(ce)-1}_{c}',[f'CE_{r}_{c}' for r in range(len(ce)-1) if ce[r][c] is not None])
        add(f'CE_component_BS_{c}',['capital','retained','equity'][c],[f'CE_{len(ce)-1}_{c}'])
    add('CE_printed_profit_equals_PL','netProfit',[f'CE_{3 if year==2021 else 1}_2'])
    keys=['assets','liabilities','equity','fundOperatingIncome','netProfit','assetManagementCashFlow','fundLoanAcquisition','fundEquityAcquisition']
    return {'metadata':metadata,'acceptedSeparatorGrammar':GRAMMAR,'sourcePages':source,'cells':cells,'checks':checks,'observations':[cells[k] for k in keys],'CE_current_components':ce,'printedMissingCEComponents':sum(i is None for row in ce for i in row),'fullStatementCollected':False,'notesVerified':False,'automaticPosting':False}
