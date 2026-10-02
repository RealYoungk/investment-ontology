#!/usr/bin/env python3
"""Fetch official USD/KRW daily reference rates once; never print auth URLs."""
import argparse
import concurrent.futures
import datetime as dt
import json
import os
from pathlib import Path
import urllib.parse
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--key-file', type=Path)
    parser.add_argument('--days', type=int, default=1105)
    parser.add_argument('--output', type=Path, default=Path('investment_ontology_serverpod_server/assets/macro/exim_usdkrw.json'))
    args = parser.parse_args()
    key = os.environ.get('SERVERPOD_PASSWORD_koreaEximApiKey') or os.environ.get('KOREA_EXIM_API_KEY')
    if not key and args.key_file:
        key = args.key_file.read_text().strip()
    if not key:
        raise SystemExit('Missing API key; use environment or --key-file')
    today = dt.datetime.now(dt.timezone(dt.timedelta(hours=9))).date()
    dates = [today-dt.timedelta(days=i) for i in range(args.days+1) if (today-dt.timedelta(days=i)).weekday()<5]
    if len(dates)>850:
        raise SystemExit('Request budget exceeds 850; daily provider limit is 1000')

    def fetch(date):
        url = 'https://oapi.koreaexim.go.kr/site/program/financial/exchangeJSON?' + urllib.parse.urlencode({'authkey':key,'searchdate':date.strftime('%Y%m%d'),'data':'AP01'})
        try:
            data = json.load(urllib.request.urlopen(url, timeout=15))
            if data is None:
                return None
            if not isinstance(data,list) or any(row.get('result')!=1 for row in data):
                raise ValueError()
            usd = [row for row in data if row.get('cur_unit')=='USD']
            if not usd:
                return None
            if len(usd)!=1:
                raise ValueError()
            value=float(usd[0]['deal_bas_r'].replace(',',''))
            if value<=0:
                raise ValueError()
            return {'date':date.isoformat(),'value':value}
        except Exception:
            raise RuntimeError('Official history request failed for '+date.isoformat()) from None

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        results=list(executor.map(fetch,dates))
    points=sorted([row for row in results if row],key=lambda row:row['date'])
    if not points:
        raise SystemExit('No observations')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps({'seriesId':'EXIM_USDKRW','publisher':'한국수출입은행','reference':'AP01 USD deal_bas_r','retrievedAt':dt.datetime.now(dt.timezone.utc).isoformat(),'points':points},ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'requests':len(dates),'observations':len(points),'latest':points[-1]},ensure_ascii=False))


if __name__ == '__main__':
    main()
