#!/usr/bin/env python3
"""통계청(현 국가데이터처) 한국표준산업분류 고시 자료 → assets/ksic/*.json

재현 방법은 README.md 참고.

    python3 build_ksic.py --ksic10-txt ksic10.txt --ksic11-hwpx ksic11.hwpx --out ../../assets/ksic
"""
import argparse
import json
import re
import zipfile
from pathlib import Path

KSIC10_URL = 'https://mods.go.kr/board.es?act=view&bid=107&list_no=358712&mid=a10403040000'
KSIC11_URL = 'https://mods.go.kr/board.es?mid=a10403040000&bid=107&act=view&list_no=428660'

# 공식 분류 항목 수 (대/중/소/세/세세) — 추출 결과 검증용
EXPECTED = {'KSIC 10': [21, 77, 232, 495, 1196], 'KSIC 11': [21, 77, 234, 501, 1205]}


def parse_ksic10(txt_path):
    """hwp5txt 출력에서 코드·명칭 추출.

    hwp5txt는 표 셀을 붙여 "2411차 철강 제조업"처럼 코드와 명칭이 이어진다.
    상위 코드가 먼저 나와야 한다는 계층 규칙으로 경계를 정한다.
    """
    lines = Path(txt_path).read_text(encoding='utf-8').split('\n')
    end = next(i for i, l in enumerate(lines) if l.strip() == '1. 신ㆍ구 연계표')
    first = next(i for i, l in enumerate(lines) if l.strip().startswith('01110'))
    start = max(i for i in range(first) if re.match(r'01[가-힣]', lines[i].strip()))

    items = {}
    for s in (l.strip() for l in lines[start:end]):
        m = re.match(r'(\d{2,6})\s*(\S.*)', s)
        if not m or s.endswith('다.') or len(s) > 90:
            continue
        digits, rest = m.group(1), m.group(2)
        spaced = len(s) > len(digits) and s[len(digits)] == ' '
        for k in range(min(5, len(digits)), 1, -1):
            code = digits[:k]
            name = (digits[k:] + (' ' if spaced and k == len(digits) else '') + rest).strip()
            if code in items or not name:
                continue
            if name[0].isdigit() and not re.match(r'\d차', name):
                continue
            if not re.match(r'[\d가-힣(]', name):
                continue
            if k > 2 and code[:-1] not in items:
                continue
            items[code] = re.sub(r'\s+', ' ', name)
            break

    sections = {}
    for l in lines:
        m = re.match(r'^([A-U])\s+(.+?)\((\d{2})(?:\s*[~～]\s*(\d{2}))?\)\s*$', l.strip())
        if m and m.group(1) not in sections:
            name = re.sub(r'\s+', ' ', m.group(2)).strip()
            if re.fullmatch(r'(?:[가-힣] )+[가-힣]', name):  # "제 조 업" 자간 조정
                name = name.replace(' ', '')
            sections[m.group(1)] = (name, int(m.group(3)), int(m.group(4) or m.group(3)))
    # T는 제목이 두 줄로 나뉘어 있어 본문 표기를 쓴다
    sections['T'] = ('가구 내 고용활동 및 달리 분류되지 않은 자가 소비 생산활동', 97, 98)
    return items, sections


def _hwpx_rows(xml):
    for tr in re.findall(r'<hp:tr\b.*?</hp:tr>', xml, flags=re.S):
        yield [' '.join(t.strip() for t in re.findall(r'<hp:t>([^<]*)</hp:t>', tc)).strip()
               for tc in re.findall(r'<hp:tc\b.*?</hp:tc>', tr, flags=re.S)]


def parse_ksic11(hwpx_path):
    """해설서 hwpx의 분류항목표(코드|한글명|영문명)에서 추출. 대분류명은 목차에서."""
    with zipfile.ZipFile(hwpx_path) as z:
        toc = z.read('Contents/section0.xml').decode('utf-8')
        table = z.read('Contents/section1.xml').decode('utf-8')
    items = {}
    for cells in _hwpx_rows(table):
        if len(cells) == 3 and re.fullmatch(r'\d{2,5}', cells[0]):
            code, name = cells[0], re.sub(r'\s+', ' ', cells[1]).strip()
            if code in items and items[code] != name:
                raise ValueError(f'{code}: {items[code]} != {name}')
            items[code] = name  # 쪽 넘김으로 같은 행이 반복됨
    sections = {}
    for p in re.findall(r'<hp:p\b.*?</hp:p>', toc, flags=re.S):
        t = re.sub(r'\s+', ' ', ''.join(re.findall(r'<hp:t>([^<]*)</hp:t>', p))).strip()
        m = re.match(r'^([A-U]) (.+?)(\(\d.*\))?$', t)
        if m and m.group(1) not in sections:
            sections[m.group(1)] = m.group(2).strip()
    return items, sections


def build(revision, items, section_names, ranges, source):
    def section_of(division):
        d = int(division)
        return next(code for code, (lo, hi) in ranges.items() if lo <= d <= hi)

    out = [{'code': c, 'name': section_names[c], 'level': 1, 'parentCode': None}
           for c in sorted(section_names)]
    out += [{'code': c, 'name': items[c], 'level': len(c),
             'parentCode': section_of(c) if len(c) == 2 else c[:-1]}
            for c in sorted(items)]

    counts = [sum(1 for o in out if o['level'] == lv) for lv in range(1, 6)]
    assert counts == EXPECTED[revision], (revision, counts)
    codes = {o['code'] for o in out}
    assert all(o['parentCode'] is None or o['parentCode'] in codes for o in out)
    return {'revision': revision, 'source': source, 'items': out}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ksic10-txt', required=True)
    ap.add_argument('--ksic11-hwpx', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    items10, sec10 = parse_ksic10(a.ksic10_txt)
    items11, sec11 = parse_ksic11(a.ksic11_hwpx)
    ranges = {k: (lo, hi) for k, (_, lo, hi) in sec10.items()}
    assert {c for c in items10 if len(c) == 2} == {c for c in items11 if len(c) == 2}, \
        '10차와 11차의 중분류 구성이 다르면 대분류 범위를 따로 추출해야 한다'

    results = {
        'ksic_10.json': build('KSIC 10', items10, {k: v[0] for k, v in sec10.items()}, ranges, {
            'title': '한국표준산업분류 제10차 개정 고시자료 — 총설, 분류 항목표, 분류 항목 명칭 및 내용 설명 (통계청 고시 제2017-13호)',
            'publisher': '통계청(현 국가데이터처)',
            'url': KSIC10_URL,
            'note': '첨부 hwp에서 분류 코드·명칭을 추출. 대분류 명칭과 중분류 범위는 같은 문서의 대분류 제목에서 가져옴.',
        }),
        'ksic_11.json': build('KSIC 11', items11, sec11, ranges, {
            'title': '한국표준산업분류 제11차 개정 해설서(신구연계표 포함) (통계청 고시 제2024-2호, 2024.7.1 시행)',
            'publisher': '통계청(현 국가데이터처)',
            'url': KSIC11_URL,
            'note': '첨부 hwpx의 분류항목표에서 코드·명칭을 추출. 대분류 명칭은 같은 문서 목차에서, 중분류 범위는 제10차와 동일함을 확인.',
        }),
    }
    for name, data in results.items():
        Path(a.out, name).write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding='utf-8')
        print(name, len(data['items']))


if __name__ == '__main__':
    main()
