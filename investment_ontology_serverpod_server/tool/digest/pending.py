#!/usr/bin/env python3
"""요약(BusinessDigestSection)이 없는 사업의 내용 본문을 골라 파일로 덤프한다.

세션(사람 또는 모델)이 읽고 요약을 쓰기 위한 준비 단계다. 서버 API를 부르지 않고
내장 PostgreSQL(/tmp/iopg)에서 바로 읽는다.

    python3 tool/digest/pending.py --out /tmp/digest_work            # 최신 보고서만, 시가총액 큰 순
    python3 tool/digest/pending.py --out DIR --limit 50 --all-years   # 옛 연도 본문까지

DIR 에 `doc_<id>.txt`(본문)와 `pending.tsv`(id, 회사, 연도, 글자 수, 시가총액)를 쓴다.
요약은 `digest_<id>.json`으로 같은 DIR에 쓰고 `submit.py`로 넣는다.
"""
import argparse
import os
import subprocess

DB = ['psql', '-h', '/tmp/iopg', '-U', 'postgres', '-d', 'investment_ontology_serverpod', '-t', '-A']


def psql(sql: str) -> str:
    r = subprocess.run(DB + ['-c', sql], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(r.stderr)
    return r.stdout


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--all-years', action='store_true', help='최신 보고서가 아닌 본문도 포함')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    latest = '' if a.all_years else (
        ' and d."bsnsYear" = (select max(d2."bsnsYear") from business_document d2 where d2."companyId" = d."companyId")'
    )
    limit = f' limit {a.limit}' if a.limit else ''
    # 시가총액: 가장 최근 시세일의 기업별 합.
    rows = psql(f'''
        with cap as (
          select s."companyId", sum(m."marketCap"::numeric) as cap
          from market_snapshot m join security s on s.id = m."securityId"
          where m."baseDate" = (select max("baseDate") from market_snapshot)
          group by 1)
        select d.id, c.name, d."bsnsYear", length(d.text), coalesce(cap.cap, 0)
        from business_document d
        join company c on c.id = d."companyId"
        left join cap on cap."companyId" = c.id
        where not exists (select 1 from business_digest_section g where g."documentId" = d.id){latest}
        order by coalesce(cap.cap, 0) desc, d."bsnsYear" desc{limit}
    ''').strip()
    if not rows:
        print('요약이 없는 본문이 없습니다.')
        return
    with open(os.path.join(a.out, 'pending.tsv'), 'w') as f:
        f.write('id\t회사\t연도\t글자수\t시가총액\n')
        for line in rows.split('\n'):
            doc_id, name, year, chars, cap = line.split('|')
            f.write(f'{doc_id}\t{name}\t{year}\t{chars}\t{cap}\n')
            text = psql(f'select text from business_document where id = {doc_id}')
            with open(os.path.join(a.out, f'doc_{doc_id}.txt'), 'w') as t:
                t.write(text)
    print(f'{len(rows.splitlines())}건 → {a.out}/pending.tsv, doc_<id>.txt')


if __name__ == '__main__':
    main()
