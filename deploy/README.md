# 배포 절차

방식 비교는 [../docs/deploy.md](../docs/deploy.md). 여기는 고른 뒤의 실행 순서입니다.

## A. 맥 + Tailscale (무료) — 지금 쓰는 방식

맥이 서버를 돌리고 폰은 Tailscale 사설망으로 붙습니다. 인터넷에는 열리지 않습니다.
앱은 **접속한 주소의 8080**을 API로 쓰므로 (`lib/client.dart`), 주소가 바뀌어도 다시 빌드할 필요가 없습니다.

접속 주소: `http://investment-ontology.tailb7d6da.ts.net:8110`

### 맥에서 켜 두는 것 (재시작하면 다시)

```bash
serverpod start                  # API 8080 · 예약 수집 (서버 패키지 폴더에서)
scripts/host.sh                  # 앱 빌드 후 8110에 띄움 (--serve 는 빌드 건너뜀)
caffeinate -dims                 # 맥이 잠들면 접속도 수집도 멈춘다
/opt/homebrew/opt/tailscale/bin/tailscaled --tun=userspace-networking   --statedir=$HOME/.tailscale-state --socket=$HOME/.tailscale-state/tailscaled.sock
```

관리자 권한이 없어 **사용자 모드(userspace-networking)** 로 돌립니다. 이 방식은 맥이 사설망에
직접 붙지는 않고, `tailscale serve`가 받은 요청을 로컬 포트로 넘깁니다. 한 번 설정하면 상태가
남아 tailscaled를 다시 켜도 유지됩니다.

```bash
TS="tailscale --socket=$HOME/.tailscale-state/tailscaled.sock"
$TS up --hostname=investment-ontology --accept-dns=false   # 로그인 링크가 나온다
$TS serve --bg --http=8110 http://127.0.0.1:8110           # 앱
$TS serve --bg --http=8080 http://127.0.0.1:8080           # API
$TS serve status                                           # 확인
```

`--http=` 로 열면 인증서가 필요 없습니다 (사설망 안이라 그대로 씁니다). 관리자 권한이 있으면
Tailscale 맥 앱을 설치하는 쪽이 간단하고, 그때는 `serve` 없이 `http://<맥이름>:8110` 로 바로 붙습니다.

### 폰에서

App Store에서 Tailscale을 설치하고 같은 계정으로 로그인한 뒤 위 주소를 엽니다. 홈 화면에 추가하면 앱처럼 씁니다.

앱 화면을 고친 뒤에는 `scripts/host.sh` 를 다시 돌려야 폰에 반영됩니다.

## B. 작은 서버 (VPS)

준비: 도메인 하나, 디스크 40GB 이상인 서버(예: Hetzner CX22), 도메인 A 레코드를 서버 IP로.

1. 서버에 Docker와 Compose를 깝니다. 저장소를 올립니다(`git clone` 또는 rsync).
2. 비밀값을 채웁니다.

   ```bash
   cd deploy && cp .env.example .env && $EDITOR .env
   ```

3. `investment_ontology_serverpod_server/config/production.yaml` 의 `publicHost` 세 곳을 도메인으로 바꾸고, `database.host` 를 `postgres`, `redis.host` 를 `redis` 로 바꿉니다.
4. 앱을 빌드해 `deploy/web` 에 둡니다.

   ```bash
   cd investment_ontology_serverpod_flutter
   flutter build web --dart-define=SERVER_URL=https://<도메인>/api/
   rsync -a build/web/ ../deploy/web/
   ```

5. 올립니다. 첫 실행에서 마이그레이션이 적용됩니다.

   ```bash
   cd deploy && docker compose up -d --build
   ```

6. 맥의 데이터를 옮깁니다 (2.8GB, 몇 분). **먼저 맥의 `serverpod start` 를 멈춥니다.**

   ```bash
   # 맥에서
   pg_dump -h /tmp/iopg -U postgres -Fc investment_ontology_serverpod > io.dump
   scp io.dump <서버>:~
   # 서버에서
   docker compose cp ~/io.dump postgres:/tmp/io.dump
   docker compose exec postgres pg_restore -U postgres -d investment_ontology_serverpod --clean --if-exists /tmp/io.dump
   ```

7. 수집은 **한 곳에서만** 켭니다. 서버로 옮겼으면 맥에서는 `serverpod start` 를 다시 켜지 않습니다 (DART 하루 2만 건은 키 기준이라 나눠 쓰게 됩니다).
8. 백업을 걸어 둡니다 (서버 crontab, 주 1회).

   ```
   0 4 * * 0 cd /root/investment-ontology/deploy && docker compose exec -T postgres pg_dump -U postgres -Fc investment_ontology_serverpod > /root/backup-$(date +\%F).dump
   ```

## 확인

- `https://<도메인>` 에서 비밀번호를 묻고, 로그인 뒤 시장 화면이 뜹니다.
- 데이터 화면의 "수집 현황" 숫자가 맥에서 보던 것과 같습니다.
- 다음 날 00:05·00:10에 수집이 이어졌는지 데이터 화면에서 확인합니다.

### 자리를 비울 때: 지킴이

맥이 잠들거나 서버가 죽으면 수집도 접속도 멈춥니다. 며칠 자리를 비울 때는 지킴이를 켜 둡니다.

```bash
nohup scripts/watchdog.sh > /tmp/watchdog.log 2>&1 &
```

60초마다 API(8080)·앱(8110)을 확인해 세 번 연속 응답이 없으면 다시 켜고, `caffeinate`가
꺼져 있으면 같이 켭니다. 다시 켠 뒤 10분은 건드리지 않습니다 (재시작 중 오탐 방지).
서버 프로세스는 살아 있는데 응답만 없을 때는 손대지 않고 기다립니다 — 두 개가 겹쳐
뜨면 DART 하루 한도를 나눠 쓰게 되기 때문입니다.

무엇을 했는지는 `tail -f /tmp/watchdog.log`, 멈추려면 `pkill -f scripts/watchdog.sh`.

## C. 공개 URL (Tailscale Funnel) — 남에게 잠깐 보여줄 때

A가 도는 상태에서 인터넷에 여는 방법입니다. tailscaled는 사용자 모드라 소켓을 지정합니다.

```bash
TS="tailscale --socket=$HOME/.tailscale-state/tailscaled.sock"
$TS funnel --bg --set-path=/api http://127.0.0.1:8080   # API. 첫 실행이면 승인 링크가 나온다 → 브라우저에서 한 번 허용
$TS funnel --bg http://127.0.0.1:8110                   # 앱
$TS funnel status
```

주소: **https://investment-ontology.tailb7d6da.ts.net/** — 앱은 https로 열리면 같은 주소의 `/api/`를 API로 쓰므로(`lib/client.dart`) 다시 빌드할 필요가 없습니다. Funnel이 `/api` 앞부분을 떼고 넘겨 주는 것을 확인했습니다 (`/api/company/detail` → Serverpod `company/detail`). 사설망 주소(8080·8110 serve)는 그대로 둡니다.

닫기:

```bash
$TS funnel --https=443 off      # 공개만 끈다 (사설망 serve는 남는다)
# 또는 전부 초기화: $TS funnel reset
```

**주의**: 앱에 로그인이 없습니다. 링크를 아는 사람은 누구나 볼 수 있고, 데이터 화면의 수집 시작이나 검수 승인·거절 같은 **쓰기도 됩니다**. 보여 준 뒤에는 바로 닫으세요. 오래 열어 둘 거면 B처럼 비밀번호를 앞에 둡니다.
