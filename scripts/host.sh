#!/bin/zsh
# 맥을 서버로 두고 폰에서 쓰기 (배포 A).
#
#   scripts/host.sh          # 빌드하고 띄운다
#   scripts/host.sh --serve  # 이미 빌드했으면 띄우기만
#
# 앱은 접속한 주소의 8080을 API로 쓰므로, 집 네트워크든 Tailscale이든 같은 빌드로 된다.
# 수집과 API는 `serverpod start`가 계속 맡는다. 이 스크립트는 화면만 띄운다.
set -e

port=8110
root=${0:a:h}/..
app=$root/investment_ontology_serverpod_flutter

if [[ "$1" != "--serve" ]]; then
  echo "앱 빌드 중… (2분쯤)"
  (cd $app && flutter build web --release)
fi

echo
echo "폰에서 열 주소:"
if command -v tailscale >/dev/null 2>&1; then
  host=$(tailscale status --json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['Self']['DNSName'].rstrip('.'))" 2>/dev/null || true)
  [[ -n "$host" ]] && echo "  Tailscale  http://$host:$port"
fi
lan=$(ipconfig getifaddr en0 2>/dev/null || true)
[[ -n "$lan" ]] && echo "  같은 와이파이  http://$lan:$port"
echo
echo "맥이 잠들면 멈춥니다. 다른 창에서 'caffeinate -dims' 를 켜 두세요."
echo "멈추려면 Ctrl-C."
echo

exec python3 $root/scripts/serve_web.py $app/build/web $port
