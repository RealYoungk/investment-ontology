#!/usr/bin/env python3
"""비밀번호를 물어보는 작은 프록시. 공개 터널 앞에 세운다.

앱(8110)과 API(8080)를 한 주소로 묶어 준다. `/api/...` 는 API로, 나머지는 앱으로
보낸다. 앱은 https로 열리면 같은 주소의 `/api/` 를 서버로 쓴다 (lib/client.dart).

    PROXY_USER=me PROXY_PASS=... python3 scripts/auth_proxy.py [포트]

로그인이 없는 앱을 인터넷에 내놓을 때만 쓴다. 사설망(Tailscale)에서는 필요 없다.
"""

import base64
import os
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

APP = "http://127.0.0.1:8110"
API = "http://127.0.0.1:8080"
HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class Proxy(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    expected = ""

    def _unauthorized(self) -> None:
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="investment ontology"')
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _authed(self) -> bool:
        header = self.headers.get("Authorization", "")
        if not header.startswith("Basic "):
            return False
        # 길이가 달라도 시간이 같도록 비교한다.
        given = header[6:].strip()
        return len(given) == len(self.expected) and all(
            a == b for a, b in zip(given, self.expected)
        )

    def _forward(self) -> None:
        if not self._authed():
            self._unauthorized()
            return
        path = self.path
        if path.startswith("/api/"):
            target, path = API, path[4:]
        elif path == "/api":
            target, path = API, "/"
        else:
            target = APP
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        headers = {
            k: v for k, v in self.headers.items() if k.lower() not in HOP | {"authorization", "host"}
        }
        req = urllib.request.Request(
            target + path, data=body, headers=headers, method=self.command
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as res:
                data = res.read()
                self.send_response(res.status)
                for k, v in res.headers.items():
                    if k.lower() not in HOP | {"content-length"}:
                        self.send_header(k, v)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except OSError as e:
            self.send_error(502, str(e))

    do_GET = do_POST = do_PUT = do_DELETE = do_HEAD = do_OPTIONS = _forward

    def log_message(self, *args):
        pass


def main() -> None:
    user = os.environ.get("PROXY_USER")
    password = os.environ.get("PROXY_PASS")
    if not user or not password:
        sys.exit("PROXY_USER, PROXY_PASS 환경변수가 필요합니다.")
    Proxy.expected = base64.b64encode(f"{user}:{password}".encode()).decode()
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8120
    with ThreadingHTTPServer(("127.0.0.1", port), Proxy) as server:
        print(f"앱 8110 · API 8080 → 127.0.0.1:{port} (비밀번호 필요)", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
