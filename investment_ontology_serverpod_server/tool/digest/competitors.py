#!/usr/bin/env python3
"""사업의 내용 본문에서 경쟁·공급·매출 관계를 말하는 문장 가운데 **다른 상장사 이름이 나오는** 것만 뽑는다.

AI가 아니라 낱말 규칙이다. 결과는 후보일 뿐이라 사람이(세션이) 읽고 `relations_<id>.json`으로 쓴다
(`submit.py`). "경쟁력"만 있는 문장은 대부분 관계가 아니라 빼고, 이름은 3자 이상만 맞춘다.

    python3 tool/digest/competitors.py                 # AI 관계가 아직 없는 최신 본문 전부
    python3 tool/digest/competitors.py --ids 12,34     # 몇 문서만
    python3 tool/digest/competitors.py --all           # 이미 관계가 있는 문서도

출력: 문서 id | 회사 | 맞은 상장사 | 문장(200자)
"""
import argparse
import re
import subprocess

DB = ['psql', '-h', '/tmp/iopg', '-U', 'postgres', '-d', 'investment_ontology_serverpod', '-t', '-A', '-F', '\t']
CUE = re.compile(r'경쟁사|경쟁업체|경쟁 업체|경쟁회사|경쟁\s*구도|과점|양강|BIG\s*3|빅3|주요 경쟁|경쟁하고|경쟁 관계|시장을 나누|점유율을 두고|주요 고객|주요 매출처|주요 공급|납품하고|공급하고 있')
NOT_CUE = re.compile(r'경쟁력|경쟁우위|경쟁 우위')
FORM = re.compile(r'\((주|유)\)|㈜|주식회사|유한회사|\s+')


def psql(sql: str) -> str:
    r = subprocess.run(DB + ['-c', sql], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(r.stderr)
    return r.stdout


def key(name: str) -> str:
    return FORM.sub('', name).lower()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--ids', default='')
    ap.add_argument('--all', action='store_true')
    a = ap.parse_args()

    listed = [l.split('\t') for l in psql(
        '''select id, name from company where market in ('kospi','kosdaq') and name is not null'''
    ).strip().split('\n') if l]
    # 보통 낱말과 겹치는 상장사 이름은 뺀다 ("디바이스"·"하이브리드"·"아크릴 섬유"·"따라서 전기전자").
    stop = {'디바이스', '디아이', '이닉스', '서전기전', '하이브', '케이씨', '라닉스', '한네트', '그래피', '아크릴', '삼양사', '대상', '한섬', '동서', '대한'}
    names = {}
    for cid, name in listed:
        k = key(name)
        if len(k) >= 3 and k not in stop:
            names[k] = name
    # 본문은 다른 표기를 쓴다.
    for alias, full in {'sk하이닉스': '에스케이하이닉스(주)', 'sk텔레콤': '에스케이텔레콤 주식회사', 'hd현대중공업': '에이치디현대중공업(주)', 'lg디스플레이': '엘지디스플레이(주)', 'lg화학': '(주)엘지화학', 'lg전자': 'LG전자(주)'}.items():
        names.setdefault(alias, full)
    # 긴 이름부터 맞춰 "삼성전자"가 "삼성전자서비스"에 먹히지 않게 한다.
    ordered = sorted(names, key=len, reverse=True)

    cond = ''
    if a.ids:
        cond = f' and d.id in ({a.ids})'
    elif not a.all:
        cond = ''' and not exists (select 1 from ontology_relation r where r."factKind"='businessDocument' and r."factId"=d.id and r."extractedBy"='ai' and r."extractorModel" not like '표 규칙%')'''
    docs = psql(f'''
        select d.id, c.name, d."companyId" from business_document d join company c on c.id=d."companyId"
        where d."bsnsYear" = (select max(d2."bsnsYear") from business_document d2 where d2."companyId"=d."companyId"){cond}
        order by d.id''').strip().split('\n')
    total = 0
    for row in docs:
        if not row:
            continue
        doc_id, company, _ = row.split('\t')
        me = key(company)
        text = psql(f'select text from business_document where id={doc_id}')
        for line in text.split('\n'):
            if ' | ' in line:
                continue  # 표는 규칙 추출이 따로 읽는다
            for sent in re.split(r'(?<=[.다])\s+(?=[가-힣A-Z(])', line):
                if not CUE.search(sent) or (NOT_CUE.search(sent) and not re.search(r'경쟁사|경쟁업체|과점|양강', sent)):
                    continue
                low = key(sent)
                hits = []
                for k in ordered:
                    if k in low and k != me and not (k in me or me in k):
                        hits.append(names[k])
                        low = low.replace(k, ' ')
                if hits:
                    total += 1
                    print(f'{doc_id}\t{company}\t{", ".join(hits[:6])}\t{sent.strip()[:200]}')
    print(f'-- 후보 문장 {total}건', flush=True)


if __name__ == '__main__':
    main()
