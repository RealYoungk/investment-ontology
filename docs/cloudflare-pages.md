# Cloudflare Pages 이전 준비

2026-10-01: 프런트엔드는 Cloudflare Pages Free, API·DB·정기결제 작업은 기존 iwinv Serverpod를 유지한다. 현재 alfinder.kr은 기존 웹 배포를 사용한다. Cloudflare 계정 로그인·프로젝트 생성·도메인 전환은 아직 완료되지 않았다. 광고 송출과 실결제는 비활성이다.

## 무료 한도와 요청 경로

정적 파일은 Pages에서 직접 제공한다. `_routes.json`은 `/api`와 `/api/*`만 Worker에 보낸다. 따라서 Flutter 파일·약관 페이지·ads.txt 조회는 Functions 요청 한도를 소비하지 않는다. Functions는 계정 전체 Workers Free와 공유하는 하루 100,000회 한도다. 이는 방문자 수가 아니라 API 호출 수다. 초과 시 API가 실패할 수 있으므로 로그인·결제 개통 전 사용량 경고와 한도 도달 시 동작을 확인한다. 유료 플랜으로 자동 전환하지 않는다.

프록시는 고정 iwinv HTTPS 주소로만 전달하며, Serverpod 인증 헤더·쿠키·Origin과 여러 Set-Cookie를 보존한다. 결제 요청은 재시도하지 않고 API 응답은 저장하지 않는다. 비즈니스 로직·시크릿 키는 Worker에 넣지 않는다.

공식 문서:
- https://developers.cloudflare.com/pages/functions/pricing/
- https://developers.cloudflare.com/pages/functions/routing/
- https://developers.cloudflare.com/pages/platform/limits/
- https://developers.cloudflare.com/pages/get-started/direct-upload/
- https://developers.cloudflare.com/pages/configuration/custom-domains/

## 검증된 릴리스에서 패키지 만들기

기존 release.py의 CI 또는 clean-main 검증 산출물만 입력한다. Flutter를 다시 빌드하거나 로컬 Serverpod 소스를 업로드하지 않는다.

```sh
node --test deploy/cloudflare/worker.test.mjs
python3 scripts/prepare_cloudflare_web.py \
  --release output/releases/local-<main-sha> \
  --output output/cloudflare/<main-sha>
```

모든 정적 파일의 릴리스 체크섬, 파일 수, 25 MiB 크기 제한을 검사한다. 출력은 새 디렉터리여야 한다. Worker·라우팅·보안 헤더를 추가한다. 최종 Worker 버전은 별도의 Git 커밋으로 기록한다. 기존 release.json은 앱 빌드의 커밋을 유지한다.

Pages Direct Upload의 `_worker.js`는 대시보드 업로드와 Wrangler 모두 지원한다. Git integration으로 전환하려면 새 프로젝트가 필요하므로 검증 완료한 prebuilt artifact를 배포하는 현재 방식에 맞춰 Direct Upload를 사용한다. Pages 기본 SPA fallback을 이용한다. 임의의 404.html이나 모든 경로를 덮는 redirect를 추가하지 않는다.

## 실제 이전 순서

1. 사용자가 Cloudflare 로그인/가입을 완료한다. Free 계정과 Pages 프로젝트를 확인한다.
2. 전용 Pages 프로젝트에 먼저 미리보기 배포한다. 아직 alfinder.kr DNS를 바꾸지 않는다.
3. 미리보기에서 assets, 정책 페이지, ads.txt, release.json, 기업 RPC와 비로그인 개인 API 401을 확인한다. 로그인·가입·토스 테스트 카드 등록/청구/해지/환불과 쿠키 동작은 실제 Cloudflare 런타임에서 확인한다. 로컬 단위 검증만으로 이를 통과했다고 보고하지 않는다.
4. Gabia DNS 레코드 전체를 먼저 보존한다. apex alfinder.kr을 Pages에 붙이려면 Cloudflare zone/nameserver가 필요하다. 메일 MX·SPF·DKIM·DMARC·검증 TXT를 함께 복사하고 확인한 뒤 등록기관 nameserver를 바꾼다. DNSSEC가 켜져 있으면 기존 DS 처리까지 확인한다. 도메인 등록기관 이전은 필요 없다.
5. 인증서 활성화 후 Pages의 alfinder.kr 연결을 완료한다. 브라우저에서 로그인·로그아웃, 개인 권한, 주요 화면, 결제 callback origin, ads.txt와 AdSense 소유 확인을 다시 검증한다. 호스팅 제공자 개인정보 안내는 실제 전환 시 업데이트한다.
6. 장애 시 보존한 기존 DNS/배포로 되돌린다. 이전 배포를 삭제하지 않는다. Cloudflare 전환 완료와 광고·실결제 활성화는 별도 기록한다.

## 이번 검증

4개 transport 테스트: 정적 요청 우회, 인증/쿠키/Origin 유지·고정 upstream·오청구 재시도 방지, 401/복수 쿠키/캐시 금지, 잘못된 경로 거절. 현재 main 0c70c646 릴리스의 64개 파일로 Pages 업로드 폴더를 준비했다. Cloudflare 업로드·실제 런타임·DNS 이전은 로그인 완료 후 진행한다.
