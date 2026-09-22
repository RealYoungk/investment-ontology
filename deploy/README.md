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
2. 비밀값을 채웁니다. 로그인 키(`JWT_HMAC_SHA512_PRIVATE_KEY`·`JWT_REFRESH_TOKEN_HASH_PEPPER`·`EMAIL_SECRET_HASH_PEPPER`)는 한 번 정하면 재배포 때마다 새로 만들지 않습니다 — 바꾸면 발급된 로그인·리프레시 토큰이 전부 무효화됩니다.

   ```bash
   cd deploy && cp .env.example .env && $EDITOR .env
   ```

3. DB 접속 정보(호스트·DB 이름·SSL)는 `docker-compose.yml`이 환경변수로 이미 이 compose의 postgres에 맞게 덮어쓰므로 손대지 않습니다. `investment_ontology_serverpod_server/config/production.yaml` 의 `publicHost` 세 곳(apiServer·insightsServer·webServer)은 아직 자리표시자(`*.examplepod.com`)이므로 도메인으로 직접 바꿉니다(서버 앱 코드 소유라 이 compose가 대신 바꿔주지 않습니다).
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

- `https://<도메인>` 에서 앱 자체 로그인(이메일) 화면이 뜨고, 로그인 뒤 시장 화면이 뜹니다. 프록시 단 비밀번호는 없습니다 — 인증은 서버가 모든 엔드포인트에서 강제합니다.
- 데이터 화면의 "수집 현황" 숫자가 맥에서 보던 것과 같습니다.
- 다음 날 00:05·00:10에 수집이 이어졌는지 데이터 화면에서 확인합니다.

### 이메일 발송 — 자체 호스팅에서는 직접 붙여야 합니다

가입·비밀번호 재설정 인증코드는 서버 코드(`AdminProvisioning.configuration()`)가 기본값으로
`ServerpodCloudEmailIdpConfig`를 씁니다. 이 설정은 Serverpod Cloud에 올린 프로젝트에서만
실제로 메일을 보냅니다 — Serverpod Cloud가 자동으로 넣어주는 `scloudAuthEmailKey` 비밀값이
있어야 발송되기 때문입니다. **이 compose처럼 직접 호스팅하면 그 키가 없어서 발송이 조용히
실패합니다** (실패해도 예외를 던지지 않고 로그만 남기는 방어적 설계라, 가입 화면은 정상으로
보이는데 메일만 영영 오지 않습니다).

이 부분은 배포 파일 소유 범위 밖(서버 앱 코드)이라 여기서 고치지 않았습니다 — 실제 서비스로
열기 전에 다음 중 하나가 필요합니다:

- Serverpod Cloud에 배포한다 (이 self-host compose 대신), 또는
- `AdminProvisioning.configuration()`을 `EmailIdpConfigFromPasswords` + 실제 이메일 발송
  콜백(SMTP·SES·Postmark 등)으로 바꾼다 (앱 코드 담당자 몫).

가입 테스트를 이 compose에서 미리 해 본다면 서버 로그(`SERVERPOD_SESSION_CONSOLE_LOG_*` 또는
`docker compose logs server`)에서 "Failed to send ... email" 에러가 찍히는지 확인하세요.

### 리프레시 쿠키와 프록시

Serverpod 4.0 클라이언트는 브라우저가 보는 API 기준 경로를 전달하고 서버는 이를 검증해 쿠키 경로를 정한다. `/api` 프록시를 사용할 때도 별도의 수동 쿠키 경로 변경은 필요하지 않다. 실제 외부 배포 후 HTTPS·허용 Origin·쿠키 동작을 다시 확인한다.

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

**주의**: 앱은 이제 이메일 로그인을 강제하므로(모든 온톨로지 엔드포인트에서 인증 필요, 쓰기는
Scope.admin 필요) 링크만으로 데이터를 보거나 고치는 것은 막혀 있습니다. 다만 가입 화면
자체는 누구나 열 수 있고, 위 "이메일 발송" 항목이 아직 해결 전이면 가입해도 인증코드가 오지
않습니다 — 자체 호스팅에서 잠깐 보여줄 때는 계정을 미리 만들어 두거나(비밀번호 재설정도 같은
문제), 이메일 발송을 먼저 붙이세요. 다 보여준 뒤에는 닫으세요.

현재 개발 설정은 localhost Origin만 허용한다. Tailscale/Funnel 등 외부 주소로 사용할 때는 해당 정확한 Origin과 HTTPS 쿠키 설정을 별도로 구성해야 한다. 위 과거 접속 절차가 현재 설정으로 검증되었다는 뜻은 아니다. 로컬 개발에는 Docker가 필요 없으며 B는 선택적 배포 예시다.
