"""Reproduce issuer-bound comparison tables from an official IR-linked PDF.

Usage: python extract_pdf.py CORP_CODE COMPANY_NAME IR_PAGE PDF_URL OUTPUT
No factual before/after cells or explanations are entered manually.
"""
import sys, re, json, hashlib, urllib.request, io
from datetime import datetime, timezone
import pdfplumber
from urllib.parse import urlparse

code, company, ir, url, output = sys.argv[1:]
if not re.fullmatch(r'\d{8}', code) or urlparse(url).scheme != 'https':
    raise ValueError('Invalid issuer/source')
page = urllib.request.urlopen(urllib.request.Request(ir, headers={'User-Agent':'Mozilla/5.0'}), timeout=25).read().decode('utf8')
if url not in page and urlparse(url).path not in page:
    raise ValueError('PDF is not linked by the specified official IR page')
body = urllib.request.urlopen(url, timeout=25).read()
with pdfplumber.open(io.BytesIO(body)) as doc:
    cover = ''.join((p.extract_text() or '') for p in doc.pages[:8])
    norm = lambda s: re.sub(r'\s|주식회사|\(주\)|㈜', '', s)
    m = re.search(r'회\s*사\s*명\s*:\s*([^\n]+)', cover)
    if not m or norm(m[1]) != norm(company):
        raise ValueError('PDF issuer does not match company')
    meeting = re.search(r'1\.\s*일\s*시\s*:\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일', cover)
    if not meeting: raise ValueError('Meeting date absent')
    tables, pages = [], []
    for i, p in enumerate(doc.pages):
        text = p.extract_text() or ''
        if not ('변경전' in re.sub(r'\s', '', text) and '변경후' in re.sub(r'\s', '', text)):
            continue
        for table in p.extract_tables():
            if not table: continue
            header = [re.sub(r'\s', '', c or '') for c in table[0]]
            if not {'변경전내용','변경후내용','변경의목적'}.issubset(header): continue
            tables.append([[c or '' for c in row] for row in table])
            pages.append(i+1)
    if not tables: raise ValueError('No explicit charter comparison table')
    data = dict(corpCode=code, company=company, meetingDate='%04d-%02d-%02d' % tuple(map(int, meeting.groups())),
        sourceUrl=url, discoveryUrl=ir, sourcePages=sorted(set(pages)),
        sourceSha256=hashlib.sha256(body).hexdigest(), retrievedAt=datetime.now(timezone.utc).isoformat(),
        stage='proposal', tables=tables)
    with open(output, 'w') as f: json.dump(data, f, ensure_ascii=False, indent=2)
    print(f'Extracted {len(tables)} explicit tables, pages {pages}; issuer matched.')
