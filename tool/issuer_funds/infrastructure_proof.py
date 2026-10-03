#!/usr/bin/env python3
"""Offline exact-source infrastructure fund current-cell proof. No posting.
Only bound finance pages have their fixed font encoding recovered; notes unchanged.
"""
import hashlib,json,re,subprocess
from pathlib import Path
from extract_mapps import MANIFEST,integer,compact
NUM=re.compile(r'(?<![\w\d])(?:\(?-?\d{1,3}(?:,\d{3})+\)?|\(?-?\d+\)?|[-–])(?![\d\w.])')
VERSION='infrastructure-fixed-finance-glyphs-v1'
def transform(raw,pages):
    parts=raw.decode().split('\f')
    def decode(c):
        n=ord(c)
        if 0x351<=n<=0x371:return chr(n-0x331)
        if 71<=n<=126:return chr(n-39)
        if 0xAC00<=n+0x8ECC<=0xD7A3:return chr(n+0x8ECC)
        return c
    for p in pages:parts[p-1]=''.join(map(decode,parts[p-1]))
    return '\f'.join(parts).encode()
def normalize(label):
    s=compact(label);s=re.sub(r'\(주석[^)]*\)','',s);s=re.sub(r'^(?:[IVXivxⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]+[.．]?|\d+[.．]|\(\d+\)|[가나다라마바사아자차카타파하][.．])','',s)
    return s.replace('ଝ','')
def proof(pdf):
    version=subprocess.run(['pdftotext','-v'],capture_output=True,check=True).stderr.decode().splitlines()[0]
    if version!='pdftotext version 26.02.0':raise ValueError('Pinned extraction tool required')
    digest=hashlib.sha256(pdf.read_bytes()).hexdigest()
    docs=json.loads(MANIFEST.read_text())['documents'];matched=[d for d in docs if d['metadata']['sha256']==digest and d['metadata']['corpCode'] in ('00435297','01880801') and d['metadata']['documentType']=='auditReport']
    if len(matched)!=1:raise ValueError('Exact bound infrastructure audit required')
    doc=matched[0];m=doc['metadata'];year=int(m['periodEnd'][:4]);corp=m['corpCode']
    if corp=='00435297' and year not in (2023,2024,2025) or corp=='01880801' and year not in (2024,2025):raise ValueError('Unsupported source year')
    raw=subprocess.check_output(['pdftotext','-layout','-enc','UTF-8',str(pdf),'-']);decodepages=list(range(8,14)) if corp=='00435297' else list(range(9,13)) if year==2025 else []
    decoded=transform(raw,decodepages);pages=decoded.decode().split('\f');sections={};active=None;headers=[]
    for pi,page in enumerate(pages,1):
        lines=page.splitlines();first=compact(next((x for x in lines if x.strip()),''))
        if first in ('재무상태표','손익계산서','자본변동표','현금흐름표'):
            if first in sections:raise ValueError('Repeated primary statement')
            active=first;sections[first]=[];header=compact('\n'.join(lines[:8]))
            if compact(m['issuerQuote']) not in header or '(단위:원)' not in header:raise ValueError('Issuer/unit header mismatch')
            if str(year)+'년' not in header:raise ValueError('Current year header mismatch')
            headers.append({'pageOrdinal':pi,'printedHeader':'\n'.join(lines[:8]),'statement':first})
        elif first=='주석' or '재무제표에대한주석' in first:active=None
        if active:sections[active].extend((pi,i,line) for i,line in enumerate(lines,1))
    if set(sections)!=set(('재무상태표','손익계산서','자본변동표','현금흐름표')):raise ValueError('Four source statements required')
    rows={};allcells=[]
    for section,lines in sections.items():
        if section=='자본변동표':continue
        cells=[]
        for index,(pi,li,line) in enumerate(lines):
            if any(s in line for s in ['총주식수','기준가격']) or re.search(r'\d{4}\s*년\s*:',line):continue
            matches=list(NUM.finditer(line))
            if len(matches)<2:continue
            tokens=[x.group() for x in matches];current,prior=tokens[-2:];head=line[:matches[-2].start()].strip();labelcoords=[{'pageOrdinal':pi,'lineOrdinal':li}]
            norm=normalize(head)
            if not norm:
                before=[];after=[]
                for j in range(index-1,max(-1,index-8),-1):
                    if lines[j][2].strip():before=[lines[j]];break
                for j in range(index+1,min(len(lines),index+4)):
                    if lines[j][2].strip():after=[lines[j]];break
                joined=(before+after)
                label=''.join(x[2].strip() for x in joined)
                if normalize(label).startswith(('자산운용활동으로인한현금','재무활동으로인한현금')):
                    head=label;norm=normalize(head);labelcoords=[{'pageOrdinal':x[0],'lineOrdinal':x[1]} for x in joined]
                else:
                    retained=[x for x in lines[max(0,index-10):index] if normalize(x[2]).startswith('이익잉여금')]
                    if retained:
                        x=retained[-1];head=x[2].strip();norm=normalize(head);labelcoords=[{'pageOrdinal':x[0],'lineOrdinal':x[1]}]
            if not norm or any(x in norm for x in ['과목','단위','총주식수','기준가격','제27','제26','제25','제36','제37']):continue
            if section=='손익계산서' and norm.startswith('주당'):continue
            if not re.search('[가-힣]',norm):continue
            cells.append({'statement':section,'pageOrdinal':pi,'lineOrdinal':li,'accountLabel':head,'normalizedLabel':norm,'labelCoordinates':labelcoords,'tokenCount':len(tokens),'currentTokenIndex':len(tokens)-2,'comparativeTokenIndex':len(tokens)-1,'printedAmount':current,'comparativePrintedAmount':prior,'amountInteger':None if integer(current) is None else str(integer(current)),'rawLine':line,'rawGlyphLine':raw.decode().split('\f')[pi-1].splitlines()[li-1]})
        rows[section]=cells;allcells.extend(cells)
    def cell(section,label,prefix=False):
        matches=[r for r in rows[section] if r['normalizedLabel']==label or prefix and r['normalizedLabel'].startswith(label)]
        if len(matches)!=1:raise ValueError(f'Unique {section}/{label} required found{len(matches)}')
        return matches[0]
    checks=[]
    def calc(name,left,right):
        # Dashes remain unprinted. Numeric self-check is not zero imputation.
        lv=integer(left['printedAmount']) if isinstance(left,dict) else left
        vals=[(integer(c['printedAmount']),coef) for c,coef in right];difference=lv-sum(v*coef for v,coef in vals if v is not None)
        if difference:raise ValueError(f'{name} difference {difference}')
        checks.append({'name':name,'left':left if isinstance(left,dict) else {'literalValidationTarget':str(left)},'terms':[{'cell':c,'coefficient':coef} for c,coef in right],'difference':str(difference),'unprintedTermCount':sum(v is None for v,coef in vals)})
    bs=rows['재무상태표'];assets=cell('재무상태표','자산총계');liab=cell('재무상태표','부채총계');equity=cell('재무상태표','자본총계')
    calc('BS assets',assets,[(cell('재무상태표','운용자산'),1),(cell('재무상태표','기타자산'),1)])
    groups=[('운용자산',['현금및예치금','대출금','지분증권'])] if corp=='00435297' else [('운용자산',['현금및예치금','유가증권','대출채권']),('현금및예치금',['현금및현금성자산']),('유가증권',['지분증권']),('대출채권',['대출금'])]
    for label,children in groups:calc('BS '+label,cell('재무상태표',label),[(cell('재무상태표',s),1) for s in children])
    debt='운용부채' if corp=='00435297' and year==2023 else '차입부채'
    for label,end in [('기타자산','자산총계'),(debt,'기타부채'),('기타부채','부채총계')]:
        p=cell('재무상태표',label);i=bs.index(p);e=bs.index(cell('재무상태표',end));calc('BS '+label,p,[(c,1) for c in bs[i+1:e]])
    calc('BS liabilities',liab,[(cell('재무상태표',debt),1),(cell('재무상태표','기타부채'),1)])
    calc('BS equity',equity,[(cell('재무상태표','자본금'),1),(cell('재무상태표','이익잉여금'),1)])
    calc('BS balance',assets,[(liab,1),(equity,1)])
    pl=rows['손익계산서'];income=cell('손익계산서','운용수익');expense=cell('손익계산서','운용비용');net=cell('손익계산서','당기순이익')
    calc('PL income',income,[(c,1) for c in pl[pl.index(income)+1:pl.index(expense)]])
    subtotal=cell('손익계산서','법인세비용차감전당기순이익') if corp=='00435297' else net
    calc('PL expense',expense,[(c,1) for c in pl[pl.index(expense)+1:pl.index(subtotal)]])
    calc('PL income less expense',subtotal,[(income,1),(expense,-1)])
    if corp=='00435297':calc('PL profit',net,[(subtotal,1),(cell('손익계산서','법인세비용'),-1)])
    cf=rows['현금흐름표'];groups=[cell('현금흐름표',s) for s in ['자산운용활동현금유입액','자산운용활동현금유출액','재무활동현금유입액','재무활동현금유출액']]
    management=cell('현금흐름표','자산운용활동으로인한현금',True);financing=cell('현금흐름표','재무활동으로인한현금',True)
    increase=cell('현금흐름표','현금의',True)
    for i,g in enumerate(groups):
        ending=groups[i+1] if i in (0,2) else management if i==1 else financing
        if cf.index(ending)<cf.index(g):ending=financing if i==1 else increase
        calc('CF '+g['normalizedLabel'],g,[(c,1 if i in(0,2) else -1) for c in cf[cf.index(g)+1:cf.index(ending)]])
    calc('CF asset management',management,[(groups[0],1),(groups[1],1)]);calc('CF financing',financing,[(groups[2],1),(groups[3],1)])
    increase=cell('현금흐름표','현금의',True);opening=cell('현금흐름표','기초의현금',True);closing=cell('현금흐름표','기말의현금',True)
    calc('CF activities',increase,[(management,1),(financing,1)]);calc('CF cash roll',closing,[(opening,1),(increase,1)])
    # Source labels differ for MKIF cash; equality is a numerical witness only.
    bscash=cell('재무상태표','현금및예치금' if corp=='00435297' else '현금및현금성자산')
    calc('BS CF cash printed values',closing,[(bscash,1)])
    ce=sections['자본변동표'];start=next(i for i,x in enumerate(ce) if (f'{year}년1월1일(당기초)' in compact(x[2]) or f'{year}.01.01(당기초)' in compact(x[2])));end=next(i for i,x in enumerate(ce) if (f'{year}년12월31일(당기말)' in compact(x[2]) or f'{year}.12.31(당기말)' in compact(x[2])))
    def equityrow(index):
        for j in range(index,min(index+5,len(ce))):
            pi,li,line=ce[j];t=[m.group() for m in NUM.finditer(line)]
            if len(t)>=3 and any(',' in v for v in t[-3:]):
                # Date/stock count tokens precede the actual three amount columns.
                parts=t[-3:];nums=[integer(x) for x in parts]
                if nums[-1] is None or sum(x for x in nums[:-1] if x is not None)!=nums[-1]:raise ValueError('CE component total mismatch')
                return {'statement':'자본변동표','pageOrdinal':pi,'lineOrdinal':li,'tokenCount':len(t),'componentTokenIndices':list(range(len(t)-3,len(t))),'printedComponents':parts,'total':str(nums[-1]),'rawLine':line,'rawGlyphLine':raw.decode().split('\f')[pi-1].splitlines()[li-1]}
        raise ValueError('Missing own equity row')
    initial=equityrow(start);final=equityrow(end);movements=[]
    for i in range(start+1,end):
        line=ce[i][2]
        if compact(line).startswith(('유상증자','주식발행비용','당기순이익','분배금의지급','현금분배금')):movements.append(equityrow(i))
    if int(initial['total'])+sum(int(x['total']) for x in movements)!=int(final['total']) or int(final['total'])!=integer(equity['printedAmount']):raise ValueError('CE close/movement mismatch')
    ceprofit=[x for x in movements if '당기순이익' in compact(x['rawLine'])]
    if len(ceprofit)!=1 or int(ceprofit[0]['total'])!=integer(net['printedAmount']):raise ValueError('CE PL own profit mismatch')
    selected=[assets,liab,equity,income,net,management,cell('현금흐름표','대출금의취득' if corp=='00435297' else '대출채권투자'),cell('현금흐름표','지분증권의취득' if corp=='00435297' else '유가증권투자')]
    metrics=['assets','liabilities','equity','fundOperatingIncome','netProfit','assetManagementCashFlow','fundLoanAcquisition','fundEquityAcquisition']
    observations=[]
    for metric,c in zip(metrics,selected):
        if c['amountInteger'] is None:raise ValueError('Missing selected category, no zero fill')
        observations.append({**c,'metric':metric,'cashDirection':'outflow' if metric in metrics[-2:] else None,'amountScope':'stockAtPeriodEnd' if metric in metrics[:3] else 'ownFiscalDuration'})
    return {'metadata':m,'rawTextSha256':hashlib.sha256(raw).hexdigest(),'decodedTextSha256':hashlib.sha256(decoded).hexdigest(),'decodedPages':decodepages,'textTransformation':VERSION,'observations':observations,'headers':headers,'checks':checks,'equityWitnesses':[initial,*movements,final],'equityDifference':'0','equityCloseDifference':'0','wholeProfitDifference':'0','cashScope':'numericalPrintedRowsAgree;MKIFdifferentCashLabelsNotDeclaredEquivalent' if corp=='00435297' else 'explicitPrintedCashEquivalentsRowAgrees;noNotesOpinionAssertion','rawText':raw,'decodedText':decoded,'fullStatementCollected':False,'automaticPosting':False}
