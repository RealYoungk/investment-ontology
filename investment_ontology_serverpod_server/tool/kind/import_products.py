"""Reproduce KIND's public EXCEL export as a minimal, attributed source asset.
Usage: python3 tool/kind/import_products.py downloaded.xls output.json
Download: https://kind.krx.co.kr/corpgeneral/corpList.do?method=download&searchType=13&currentPageSize=3000&pageIndex=1
Never include officers/contact details: only classification source fields.
"""
import datetime,hashlib,json,pathlib,re,sys
from html.parser import HTMLParser
class Table(HTMLParser):
 def __init__(self):super().__init__();self.rows=[];self.row=[];self.cell=None
 def handle_starttag(self,tag,attrs):
  if tag=='tr':self.row=[]
  if tag in ('th','td'):self.cell=''
 def handle_data(self,data):
  if self.cell is not None:self.cell+=data
 def handle_endtag(self,tag):
  if tag in ('th','td') and self.cell is not None:self.row.append(self.cell.strip());self.cell=None
  if tag=='tr' and self.row:self.rows.append(self.row)
raw=pathlib.Path(sys.argv[1]).read_bytes();p=Table();p.feed(raw.decode('euc-kr'))
assert {'회사명','종목코드','주요제품','업종'}.issubset(p.rows[0]),'Unexpected source schema'
rows=[];seen={};duplicates=0
for cells in p.rows[1:]:
 assert len(cells)==len(p.rows[0]),'Misaligned source row'
 r=dict(zip(p.rows[0],cells));code=r['종목코드']
 assert re.fullmatch('[0-9A-Z]{6}',code),(code,'invalid code')
 row=dict(stockCode=code,name=r['회사명'],industry=r['업종'],products=r['주요제품'])
 if code in seen:
  assert seen[code]==row,(code,'conflicting source rows')
  duplicates+=1;continue
 seen[code]=row;rows.append(row)
assert 2500<len(rows)<3000,'Check export pagination before accepting a truncated list'
out=dict(sourceUrl='https://kind.krx.co.kr/corpgeneral/corpList.do?method=loadInitPage',retrievedAt=datetime.datetime.now(datetime.timezone.utc).isoformat(),sourceSha256=hashlib.sha256(raw).hexdigest(),duplicateRows=duplicates,rows=rows)
pathlib.Path(sys.argv[2]).write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n');print(len(rows))
