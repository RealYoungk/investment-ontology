#!/usr/bin/env python3
"""사업의 내용 요약(BusinessDigestSection)의 숫자를 재무제표와 대조한다.

요약 문장에서 "매출은 N조 M억", "2024년 M억보다 X% 늘었다", "영업이익 M억", "순이익 M억"을
정규식으로 뽑아 `financial_fact`의 FY 연차 값(연결·별도, ifrs-full_Revenue ·
dart_OperatingIncomeLoss · ifrs-full_ProfitLoss)과 비교한다. 3%(이익은 5%) 넘게 다르면 줄을 찍는다.

찍힌 줄이 모두 틀린 것은 아니다 — 사업의 내용 표는 내부거래를 포함한 부문 합계이거나
종속회사를 뺀 본사 값인 경우가 많다. 그런 줄은 요약에 "부문 합계(내부거래 포함)"처럼 적고
연결재무제표 값을 같이 두면 된다 (docs/handoff.md 3-4절).

실행 (서버가 켜져 있고 내장 PostgreSQL 소켓이 /tmp/iopg 에 있을 때):

    python3 tool/digest_audit/digest_audit.py            # FY2025
    python3 tool/digest_audit/digest_audit.py --year 2026 --psql "psql -h localhost -p 8090 -U postgres"
"""

import argparse
import re
import subprocess

DB = 'investment_ontology_serverpod'

NUM = r'(?:(\d+)조\s*)?([\d,]+)억'
REVENUE = re.compile(
    r'(?:매출(?:액)?|영업수익)(?:\(총액\)|\(계속영업\))?(?:은|이|는)\s*' + NUM)
PRIOR = re.compile(r'(?:2024년|전년)\s*' + NUM)
PROFIT = {
    'dart_OperatingIncomeLoss': re.compile(
        r'영업(?:이익|손실)(?:은|이|는|\s)\s*(?:연결\s*|별도\s*)?(−|-)?' + NUM),
    'ifrs-full_ProfitLoss': re.compile(
        r'(?:당기)?순(?:이익|손실)(?:은|이|는|\s)\s*(?:연결\s*|별도\s*)?(−|-)?' + NUM),
}
GROWTH = re.compile(
    NUM + r'(?:원)?(?:으로|이며|이고|에서|,)?\s*(?:\([^)]*\)\s*)?(?:2024년|전년)\s*'
    + NUM + r'(?:원)?(?:보다|에서|대비)\s*(\d+(?:\.\d+)?)%\s*(늘|줄|증가|감소|커|작)')


def won(jo, eok):
    return (int(jo) * 10**12 if jo else 0) + int(eok.replace(',', '')) * 10**8


def query(psql, sql):
    out = subprocess.run(
        psql.split() + ['-d', DB, '-t', '-A', '-F', '\t', '-c', sql],
        capture_output=True, text=True, check=True).stdout
    return [line.split('\t') for line in out.splitlines() if line.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--year', type=int, default=2025)
    ap.add_argument('--psql', default='psql -h /tmp/iopg -U postgres')
    ap.add_argument('--tolerance', type=float, default=0.03)
    a = ap.parse_args()

    facts = {}  # (companyId, accountId) -> {fsDiv: (amount, prior)}
    for cid, fs, acc, amt, prior in query(a.psql, f"""
        select r."companyId", r."fsDiv", f."accountId", f.amount, f."priorAmount"
        from financial_fact f join financial_report r on r.id = f."reportId"
        where r."bsnsYear" = {a.year} and r."reportCode" = 'annual'
          and r."supersededById" is null and f."supersededById" is null
          and f."accountId" in ('ifrs-full_Revenue','dart_OperatingIncomeLoss','ifrs-full_ProfitLoss')
          and f.statement in ('incomeStatement','comprehensiveIncome') and f.amount <> ''"""):
        facts.setdefault((int(cid), acc), {})[fs] = (
            int(amt), int(prior) if prior else None)

    sections = query(a.psql, f"""
        select d."companyId", c.name, s."documentId", s.kind,
               regexp_replace(s.summary, E'[\\n\\r]+', ' ', 'g')
        from business_digest_section s
        join business_document d on d.id = s."documentId"
        join company c on c.id = d."companyId"
        where d."bsnsYear" = {a.year} order by s."documentId", s.ord""")

    def closest(vals, v):
        return min(vals, key=lambda x: abs(x - v) / max(abs(x), abs(v), 1))

    def rel(x, v):
        return abs(x - v) / max(abs(x), abs(v), 1)

    checked = flagged = 0
    seen = set()
    for cid, name, doc, kind, text in sections:
        cid = int(cid)
        # 매출 (당기·전기) — 개요 절에서만, 회사당 한 번
        if kind == 'overview' and (cid, 'rev') not in seen:
            m = REVENUE.search(text)
            r = facts.get((cid, 'ifrs-full_Revenue'))
            if m and r:
                seen.add((cid, 'rev'))
                v = won(m.group(1), m.group(2))
                cur = {fs: x[0] for fs, x in r.items()}
                fs = min(cur, key=lambda k: rel(cur[k], v))
                checked += 1
                if rel(cur[fs], v) > a.tolerance:
                    flagged += 1
                    print(f'매출   {rel(cur[fs], v):5.0%} {name} doc{doc} | "{m.group(0)}" | '
                          + ' · '.join(f'{k} {x // 10**8:,}억' for k, x in cur.items()))
                else:
                    m2 = PRIOR.search(text, m.end(), m.end() + 80)
                    prior = r[fs][1]
                    if m2 and prior:
                        pv = won(m2.group(1), m2.group(2))
                        checked += 1
                        if rel(prior, pv) > a.tolerance:
                            flagged += 1
                            print(f'전기   {rel(prior, pv):5.0%} {name} doc{doc} | "{m2.group(0)}" | '
                                  f'재무제표 전기 {prior // 10**8:,}억 ({fs})')
        # 영업이익·순이익 — 어느 절이든, 회사당 계정마다 한 번
        for acc, pat in PROFIT.items():
            m = pat.search(text)
            r = facts.get((cid, acc))
            if not m or not r or (cid, acc) in seen:
                continue
            seen.add((cid, acc))
            v = won(m.group(2), m.group(3))
            if m.group(1) or '손실' in m.group(0) or '적자' in text[m.end():m.end() + 12]:
                v = -v
            cur = [x[0] for x in r.values()]
            best = closest(cur, v)
            checked += 1
            if rel(best, v) > max(a.tolerance, 0.05):
                flagged += 1
                print(f'이익   {rel(best, v):5.0%} {name} doc{doc} {kind} | "{m.group(0)}" | '
                      + ' · '.join(f'{k} {x[0] // 10**8:,}억' for k, x in r.items()))
        # 증감률 산수
        for m in GROWTH.finditer(text):
            cur_v = won(m.group(1), m.group(2))
            prior_v = won(m.group(3), m.group(4))
            if prior_v == 0:
                continue
            said = float(m.group(5)) * (-1 if m.group(6) in ('줄', '감소', '작') else 1)
            real = (cur_v - prior_v) / prior_v * 100
            checked += 1
            if abs(real - said) > 1.6 or (said > 0) != (real > 0):
                flagged += 1
                print(f'증감률 {abs(real - said):4.1f}pt {name} doc{doc} {kind} | "{m.group(0)}" | 실제 {real:.1f}%')

    print(f'-- 확인 {checked}건, 살펴볼 것 {flagged}건')


if __name__ == '__main__':
    main()
