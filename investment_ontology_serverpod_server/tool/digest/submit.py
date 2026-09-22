#!/usr/bin/env python3
"""DIR의 `digest_<id>.json`(요약), `relations_<id>.json`(관계), `facts_<id>.json`(본문 값)을
서버에 넣는다. 근거 인용이 `doc_<id>.txt`에 글자 그대로 없으면 **보내기 전에** 멈춘다
(서버도 같은 검사를 하지만, 여기서 걸리면 어느 절인지 바로 보인다).

    python3 tool/digest/submit.py --dir /tmp/digest_work             # 새로 쓴 것 전부
    python3 tool/digest/submit.py --dir DIR --ids 12,34               # 몇 개만
    python3 tool/digest/submit.py --dir DIR --model 'claude-fable-5-1 (본문 읽음)'

파일 모양:
- digest_<id>.json   {"sections":[{"kind":"overview","title":"…","summary":"…","evidence":"원문 한 줄"}, …]}
                     kind: overview·products·supplyChain·production·sales·market·rnd·risks·other
                     한 문서의 절 전부를 한 번에 — 서버는 그 문서의 이전 절을 모두 바꾼다.
- relations_<id>.json {"relations":[{"type":"competitor|supplier|customer|product","name":"…","evidence":"…","confidence":0.9}]}
- facts_<id>.json     {"facts":[{"kind":"orderBacklog","label":"…","value":1234,"unit":"백만원","asOf":"2025-12-31","evidence":"…","confidence":0.9}]}
                     kind: orderTotal·orderDelivered·orderBacklog·capacity·production·utilization·marketShare·investmentPlan·investmentActual
                     value는 숫자(공시 단위 그대로), 문서당 한 번에 — 서버는 그 문서의 이전 초안을 지운다.

넣은 파일은 `<이름>.sent`로 이름을 바꿔 두 번 보내지 않는다.
"""
import argparse
import glob
import json
import os
import re
import urllib.request

SERVER = 'http://localhost:8080'
DEFAULT_MODEL = 'claude-fable-5-1 (본문 읽음)'
KINDS = {'digest': ('ai/submitDigest', 'sections'), 'relations': ('ai/submit', 'relations'), 'facts': ('ai/submitFacts', 'facts')}


def post(path: str, body: dict) -> str:
    req = urllib.request.Request(
        f'{SERVER}/{path}', data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'}
    )
    return urllib.request.urlopen(req).read().decode()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', required=True)
    ap.add_argument('--ids', default='')
    ap.add_argument('--model', default=DEFAULT_MODEL)
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    only = {int(x) for x in a.ids.split(',') if x.strip()}

    sent = 0
    for kind, (path, key) in KINDS.items():
        for file in sorted(glob.glob(os.path.join(a.dir, f'{kind}_*.json'))):
            m = re.search(rf'{kind}_(\d+)\.json$', file)
            if not m:
                continue
            doc_id = int(m.group(1))
            if only and doc_id not in only:
                continue
            src_path = os.path.join(a.dir, f'doc_{doc_id}.txt')
            if not os.path.exists(src_path):
                raise SystemExit(f'{file}: 본문 파일이 없습니다 ({src_path}) — pending.py로 먼저 덤프')
            src = open(src_path).read()
            payload = json.load(open(file))
            items = payload.get(key) or []
            if not items:
                raise SystemExit(f'{file}: "{key}"가 비어 있습니다')
            for i, item in enumerate(items):
                ev = (item.get('evidence') or '').strip()
                if not ev or ev not in src:
                    raise SystemExit(f'{file} [{i}] {item.get("kind") or item.get("type")}: 근거가 원문에 글자 그대로 없습니다\n  {ev[:120]}')
            if a.dry_run:
                print(f'OK {file} ({len(items)}건)')
                continue
            out = post(path, {'documentId': doc_id, 'answer': json.dumps(payload, ensure_ascii=False), 'model': a.model})
            print(f'{kind} {doc_id}: {out[:160]}')
            os.rename(file, file + '.sent')
            sent += 1
    print(f'보낸 파일 {sent}개')


if __name__ == '__main__':
    main()
