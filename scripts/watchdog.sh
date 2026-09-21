#!/bin/zsh
# 자리를 비운 동안 서버와 앱이 죽으면 다시 켠다.
#
#   nohup scripts/watchdog.sh > /tmp/watchdog.log 2>&1 &
#   tail -f /tmp/watchdog.log          # 무엇을 했는지
#   pkill -f scripts/watchdog.sh       # 멈추기
#
# 곁에 있을 때는 필요 없다. `serverpod start`를 직접 띄워 두고 쓰면 된다.
# 이 스크립트는 그 명령을 대신 띄우므로, 사람이 띄운 것과 겹치지 않게
# 이미 돌고 있으면 아무것도 하지 않는다.
set -u

root=${0:a:h}/..
server=$root/investment_ontology_serverpod_server
api=http://127.0.0.1:8080/
app=http://127.0.0.1:8110/
interval=60          # 확인 간격(초)
fails_needed=3       # 이만큼 연속 실패해야 다시 켠다 (재시작 중 오탐 방지)
cooldown=600         # 다시 켠 뒤 이만큼(초)은 건드리지 않는다

say() { echo "$(date '+%m-%d %H:%M:%S') $*"; }

up() { curl -s -o /dev/null --max-time 10 "$1"; }

api_fails=0
app_fails=0
api_next=0
app_next=0

say "지킴이 시작 · API $api · 앱 $app · ${interval}초마다 확인"

while true; do
  now=$(date +%s)

  if up $api; then
    api_fails=0
  else
    api_fails=$((api_fails + 1))
    say "API 응답 없음 ($api_fails/$fails_needed)"
    if [[ $api_fails -ge $fails_needed && $now -ge $api_next ]]; then
      if pgrep -f "serverpod start" > /dev/null; then
        say "API는 죽었는데 serverpod 프로세스는 살아 있다 — 손대지 않고 기다린다"
      else
        say "serverpod start 다시 켬"
        (cd $server && nohup serverpod start >> /tmp/serverpod.log 2>&1 &)
      fi
      api_next=$((now + cooldown))
      api_fails=0
    fi
  fi

  if up $app; then
    app_fails=0
  else
    app_fails=$((app_fails + 1))
    say "앱 응답 없음 ($app_fails/$fails_needed)"
    if [[ $app_fails -ge $fails_needed && $now -ge $app_next ]]; then
      say "앱 서빙 다시 켬 (빌드는 건드리지 않음)"
      nohup $root/scripts/host.sh --serve >> /tmp/host_serve.log 2>&1 &
      app_next=$((now + cooldown))
      app_fails=0
    fi
  fi

  # 맥이 잠들면 접속도 수집도 멈춘다. 꺼져 있으면 같이 켜 둔다.
  if ! pgrep -f "caffeinate -dims" > /dev/null; then
    say "caffeinate 다시 켬"
    nohup caffeinate -dims > /dev/null 2>&1 &
  fi

  sleep $interval
done
