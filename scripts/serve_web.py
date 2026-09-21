#!/usr/bin/env python3
"""Flutter 웹 빌드를 띄우는 작은 정적 서버.

주소창에 /companies 처럼 바로 들어오거나 새로고침해도 index.html을 돌려준다
(파이썬 기본 서버는 404를 낸다).

    python3 scripts/serve_web.py <빌드 폴더> [포트]
"""

import os
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class SpaHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = self.translate_path(self.path)
        # 없는 경로는 앱이 화면을 정한다 (파일 요청은 그대로 404).
        if not os.path.exists(path) and "." not in os.path.basename(path):
            self.path = "/index.html"
        return super().send_head()

    def end_headers(self):
        # 빌드가 바뀌면 바로 반영되도록.
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, *args):
        pass


def main() -> None:
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8110
    handler = partial(SpaHandler, directory=directory)
    with ThreadingHTTPServer(("0.0.0.0", port), handler) as server:
        print(f"{directory} → 0.0.0.0:{port}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
