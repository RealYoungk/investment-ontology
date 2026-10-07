import json,re
from pathlib import Path
from urllib.parse import urlparse
rows=json.load(open('output/company-branding/source-searches.json'));existing=json.load(open('output/company-branding/official-page-sources.json'));by={};needs=[]
blocked=r'digitaltoday\.|atsview\.|investing\.|tradingview\.|financialfilings\.|financialreports\.|roa\.ai|cocelo\.ai|brandb\.|stockevents\.|naver\.|daum\.|google\.|bing\.|tistory\.|fnguide\.|meerae\.|stock|saramin\.|jobkorea\.|thevc\.|wikipedia\.|wikimedia\.|instagram\.|facebook\.|youtube\.|brandatlas\.|logozip\.|logo\.domains|semologo\.|kind\.krx|dart\.fss|github\.|news|yna\.|biz|krx\.|linkedin\.|market|simplywall|crunchbase|tracxn|disfold|catch\.co|dnb\.|moneys|hankyung|mk\.co|chosun|edaily'
for row in rows:
 host=(urlparse(row.get('homepageUrl','')).hostname or '').lower().removeprefix('www.')
 urls=re.findall(r'URL: (\S+)',row.get('result',''))
 known=[u for u in urls if host and ((urlparse(u).hostname or '').lower().removeprefix('www.')==host or (urlparse(u).hostname or '').lower().endswith('.'+host)) and not re.search(r'\.pdf(?:\?|$)',u,re.I)]
 chosen=existing.get(row['stockCode']) or known
 if not chosen:
  chosen=[u for u in urls if not re.search(blocked,urlparse(u).hostname or '',re.I) and not re.search(r'\.pdf(?:\?|$)|/recruit|/careers|/jobs',u,re.I)]
  if chosen:needs.append(row['stockCode'])
 if chosen:by[row['stockCode']]=sorted(chosen,key=lambda u:not bool(re.search(r'/ci[./]|brand|identity',u,re.I)))
Path('output/company-branding/official-page-sources.json').write_text(json.dumps(by,ensure_ascii=False,indent=2))
Path('output/company-branding/page-identity-checks.json').write_text(json.dumps(needs))
print('Source pages',len(by),'new domains requiring issuer identity check',len(needs))
