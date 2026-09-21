# 배포 절차

방식 비교는 [../docs/deploy.md](../docs/deploy.md). 여기는 고른 뒤의 실행 순서입니다.

## A. 맥 + 터널 (무료) — 지금 쓰는 방식

맥이 서버를 계속 돌리고, 폰은 사설망으로 붙습니다. 앱은 **접속한 주소의 8080**을 API로 쓰므로 (`lib/client.dart`), 주소마다 다시 빌드할 필요가 없습니다.

1. **Tailscale**: 맥과 폰에 앱을 깔고 같은 계정으로 로그인합니다.
2. 맥에서 세 가지를 띄웁니다. 재시작하면 다시 켜야 합니다.

   ```bash
   serverpod start                 # API 8080 · 예약 수집 (서버 패키지 폴더에서)
   scripts/host.sh                 # 앱 빌드 후 8110에 띄우고 접속 주소를 출력
   caffeinate -dims                # 맥이 잠들면 접속도 수집도 멈춘다
   ```

   화면만 다시 띄울 때는 `scripts/host.sh --serve` (빌드 건너뜀).

3. 폰에서 `http://<맥이름>.ts.net:8110`. 같은 와이파이에서는 `http://<맥 IP>:8110`.

앱 화면을 고친 뒤에는 `scripts/host.sh`를 다시 돌려야 폰에 반영됩니다.

Cloudflare Tunnel로 공개 주소를 쓰려면, `cloudflared`로 8110(앱)과 8080(API)을 각각 도메인에 붙이고 Cloudflare Access로 잠급니다. 이때는 https라 자동 감지가 꺼지므로 `flutter build web --dart-define=SERVER_URL=https://<API 도메인>/`로 빌드합니다.

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
