#!/usr/bin/env python3
"""Authenticated authored-content operations. Never publishes during import."""
import argparse
import json
import os
from pathlib import Path
import urllib.error
import urllib.request


def rpc(method, args):
    token = os.environ.get('ONTOLOGY_ACCESS_TOKEN')
    if not token:
        raise SystemExit('관리자 로그인 토큰을 ONTOLOGY_ACCESS_TOKEN에 설정하세요.')
    server = os.environ.get('SERVER', 'http://localhost:8080').rstrip('/')
    request = urllib.request.Request(
        f'{server}/investmentNotes/{method}', data=json.dumps(args).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {token}'},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            value = json.load(response)
            return json.loads(value) if isinstance(value, str) else value
    except urllib.error.HTTPError as error:
        # Don't print request headers or access tokens.
        raise SystemExit(f'서버 요청 실패: HTTP {error.code}') from error


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='operation', required=True)
    imp = sub.add_parser('import')
    imp.add_argument('file', type=Path)
    imp.add_argument('--article-id', type=int)
    preview = sub.add_parser('preview')
    preview.add_argument('article_id', type=int)
    publish = sub.add_parser('publish')
    publish.add_argument('article_id', type=int)
    publish.add_argument('--approved-digest', required=True,
                         help='사용자가 최종 확인한 미리보기의 digest. 자동 추출하지 마세요.')
    args = parser.parse_args()
    if args.operation == 'import':
        result = rpc('importDraft', {'payload': args.file.read_text(), 'articleId': args.article_id})
    elif args.operation == 'preview':
        result = rpc('preview', {'articleId': args.article_id})
    else:
        result = rpc('publish', {'articleId': args.article_id, 'approvedDigest': args.approved_digest})
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
