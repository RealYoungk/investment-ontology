# iwinv 1 CPU・4GB・100GB 이전

2026-10-01 사용자 승인으로 hpa_1.4-g2, Ubuntu 24.04, KR1-Z03, 1대를 신청했다. 월 25,200원 + VAT = 27,720원이며 27일 이상 사용하면 월 요금이 적용된다. 생성된 VM은 49.247.192.41, 이름 alfinder-prod이며 SSH 키 접속을 검증했다. 키 이름 alfinder-mac-20261001; 개인키는 맥 ~/.ssh/alfinder_iwinv_20261001에만 있다. 저가 rCore.P2와 hpa_1.4-g1은 확인한 영역에서 재고 준비중이었다.

2026-10-01 전체 DB 이전과 공개 전환을 완료했다. 최종 원본은 맥 FutureCall을 끄고 DB 기본 트랜잭션을 조회 전용으로 설정한 뒤 MCP hot_restart하여 동결했다. 최종 백업은 ~/.config/alfinder/backups/iwinv/local-full-20261001T021620Z.dump (4,992,521,909 bytes, SHA256 684d8a93787c3ad0f63e79cf5b224e8013cd4eac7b6125f7fd0377b6aadffe83)이며 인증과 수집 상태를 포함한다. 전송 체크섬 일치·복원 성공·핵심 테이블 건수 일치를 확인했다. 전환 스냅샷은 기업 2,763, financial_report 111,241, financial_fact 16,467,728, market_snapshot 3,403,018, business_document 2,855, 계정 2개다. iwinv에서만 FutureCall을 켰으며 재무 수집 이어받기를 확인했다. 맥 DB는 현재 조회 전용인 이전 전 사본이며 자동 수집과 영구 로그 저장은 꺼져 있다.

실제 도메인의 권한 있는 DNS는 Gabia다. Vercel에 시험 추가했던 api A 레코드는 실제 DNS에 반영되지 않아 제거했다. API_HOST는 alfinder-api.49.247.192.41.sslip.io이고 Caddy의 Let's Encrypt HTTPS 인증서 발급을 확인했다. Vercel 전송 프록시만 이 HTTPS 호스트로 바꾸고 기존 Flutter 정적 빌드를 유지했다. alfinder.kr은 배포 dpl_27N6k7yY8LSpKUqvGyowRprPHc7G (https://alfinder-research-k5efve5bf-realyoungks-projects.vercel.app)로 승격했다. 공개 응답 X-Alfinder-Backend: iwinv, company/overview·screen/list 200, 익명 관리자 작업 401, cookie 인증의 허용되지 않은 Origin 403, 잘못된 로그인 invalidCredentials를 확인했다. 실제 공개 Chrome에서 삼성전자 상세 데이터 렌더링을 확인했다. 기존 회원의 실제 로그인 성공은 별도 사용자 확인이 필요하다.

## 2026-10-01 전환 재개

사용자는 월 27,720원 기본료와 트래픽 초과 요금 조건을 확인하고 iwinv 운영을 승인했다. 공개 데이터 조회는 비로그인에도 유지하고, 개인 기능에서 회원가입을 유도한다. 관리자 변경 권한은 유지한다. AGENTS.md의 오래된 조회 로그인 필수 문구를 이번 결정에 맞춰 정정했다. 신규 개인 저장 기능이나 가입 유도 UI를 이번 이전에서 구현한 것은 아니다.

VM 재부팅 후 Docker 앱·DB·HTTPS 자동 복구를 확인했다. SSH 비밀번호 접속은 끄고 기존 키 접속을 재검증했다. UFW는 관리자 현재 IP의 SSH와 공개 80/443만 허용하고 DB·Insights 포트는 publish하지 않는다. 최초 스크리너 계산은 23~35초가 걸렸고, 준비된 캐시는 약 0.1~0.3초로 응답했다. 복원 후 ANALYZE를 실행하고 alfinder-warm.timer가 시작 후 및 2분마다 조회 전용 loopback 요청으로 캐시를 미리 준비한다. 재시작 직후는 준비 시간이 필요하며 동시접속 부하 시험 결과는 아니다.

alfinder-backup.timer는 매일 04:00 KST 부근에 전체 논리 백업을 만들고 최근 3개를 보관한다. 맥의 kr.alfinder.iwinv-backup-fetch LaunchAgent는 매시간 새 완료 백업만 내려받고 SHA256 검증 후 최근 3개를 보관한다. 맥이 꺼져 있거나 관리자 IP가 바뀌어 SSH 연결이 안 되면 서버 밖 사본 갱신은 지연된다. 인증 정보를 포함하므로 파일은 private 권한으로 저장한다. Mac Serverpod pg_restore는 내장 gzip 지원이 없으므로 운영 백업은 --compress=0 custom archive를 외부 gzip으로 압축한 .dump.gz 형식을 사용한다. 복원할 때 gzip -dc로 푼 뒤 pg_restore에 전달한다. 첫 압축 형식 .dump는 Linux pg_restore에서는 복원 가능하지만 Mac 내장 도구에서는 데이터 복원이 불가능해 새 형식으로 교체했다. 새 운영 백업 alfinder-20261001T024925Z.dump.gz의 맥 다운로드·SHA256 일치, gzip 전체 CRC 검사, Mac Serverpod pg_restore로 company 테이블 데이터 추출 성공을 확인했다. 이번 운영 백업을 별도 DB에 전체 복원한 것은 아니며, 이전 최종 원본 dump의 VM 전체 복원과 핵심 건수 대조는 완료했다.

무료 리소스·포트 알림은 수신 여부에 대한 사용자 답변 대기 중이다. 트래픽 속도 제한이나 초과 요금 차단은 적용하지 않았다. 기존 Serverpod Cloud 체험 프로젝트는 별도로 남아 있으며 자동 해지되지 않는다.

## 트래픽 비용과 측정

한 달 계속 사용할 때 기본 제공 outbound는 1,000GB다. 초과 첫 구간은 GB당 70원 + VAT이며 전체 청구액이 27,720원에 고정되는 것은 아니다. inbound는 무료다. 요금 정책: https://docs.iwinv.kr/docs/billing/iwinv_price_policy/ . 응답 크기 기반 계산 결과는 outputs/iwinv/traffic-sample-20261001.json에 있다. 현재 맥 API 10종과 삼성전자 자료를 기준으로 3개 회사 조회 약 1.148MB, 10개 회사 약 3.507MB로 계산했다. 압축 이득은 가정하지 않았고 특정 회사의 자료 크기를 반복한 시나리오이므로 전체 사용자를 대표하지 않는다. 백업 등 200GB를 임의 예비량으로 남기고 30일을 가정하면 5MB/user/day에서 약 5,333 DAU가 트래픽 포함량 경계다. CPU/RAM 동시접속 성능 시험이나 프런트 호스팅 비용 시험은 아니다.

## 준비한 실행 구성

`deploy/iwinv/compose.yaml`은 PostgreSQL 16, AOT Serverpod 이미지, HTTPS Caddy 구성이다. 서버 Dockerfile로 Linux amd64 이미지를 빌드하며 VM 안에서 개발 모드 컴파일러나 Flutter 개발 앱을 실행하지 않는다. 프런트는 기존 Vercel을 사용한다.

- PostgreSQL/Insights/Serverpod 내부 포트는 호스트에 publish하지 않는다. HTTPS 80/443만 proxy에 publish한다. 관리 SSH는 실제 관리자 IP로 제한한다.
- PG shared_buffers 512MB, work_mem 16MB, maintenance_work_mem 128MB, effective_cache_size 2GB, jit off, parallel query workers 0; Serverpod 연결 풀 6, FutureCall concurrency 1. 메모리 상한은 PG 1.5GB, 서버 1.5GB, proxy 128MB다. 서버 요금제 변경 없이 기존 4GB 안에서 배분했다.
- 리허설 설정은 futureCallExecutionEnabled=false. server.dart의 기존 guard가 startup 수집 복구/예약도 차단한다. app profile은 복원과 설정 완료 전 켜지 않는다. endpoint를 통한 관리자 수동 수집은 별도로 실행하지 않는다.
- 별도의 bootstrap postgres 비밀번호 파일을 사용한다. 실제 app 연결은 비-superuser `alfinder` 역할과 그 역할 소유 DB로 설정한다. 복원 전에 역할/DB를 생성해야 하며 bootstrap superuser를 앱에 사용하지 않는다.
- runtime/에는 production.yaml, passwords.yaml, admin_emails.local, postgres_password가 필요하다. Git에 제외한다. 로컬의 인증 키·pepper·메일·원천 API 설정을 안전하게 옮기고 production DB password는 app 역할 비밀번호와 일치시킨다. 기존 production placeholder를 그대로 복사하지 않는다.
- 실제 VM에 연결한 API 호스트를 정한 뒤 API_HOST와 production publicHost를 일치시킨다. Caddy는 현재 Vercel 프록시의 `/api/` prefix를 제거해 Serverpod API로 전달한다. 실제 인증/쿠키 동작은 전환 전 검증한다. allowedOrigins는 alfinder.kr로 제한한다.
- init dataPath 폴더 대신 버전 호환 pg_dump 논리 백업을 사용한다. 복원 후 마이그레이션 상태, 전체 핵심 테이블 건수, 수집 cursor와 계정 권한을 대조한다. 초기 테스트 DB는 실제 계정 데이터 접근을 제한한다.

## 재구축 순서

1. iwinv 로그인/본인인증, KR1의 hpa_1.4-g2 및 Ubuntu 24.04 LTS 신청 가능 여부·최종 비용 확인.
2. VM 생성 후 SSH 및 방화벽을 설정하고 Docker·compose를 설치한다. 재부팅 자동 시작을 확인한다.
3. 빌드 이미지와 운영 설정을 안전하게 전달하고 DB 복원 리허설을 한다. 이미지에 비밀값을 넣지 않는다. 복원은 단일 작업으로 실행한다.
4. 실제 로그인·권한·주요 화면 조회와 수집 시 메모리/조회 지연을 검증한다. CPU가 높아도 성공적으로 완료하고 조회가 허용 가능한지 판단한다.
5. 맥 쓰기/수집을 중지하고 최종 dump·복원을 한 뒤 iwinv만 FutureCall을 활성화한다. 맥과 iwinv의 수집을 동시에 실행하지 않는다.
6. Vercel 프록시 upstream만 실제 HTTPS API로 변경해 공개 화면에서 검증한다. DB와 서버의 정합성 확인 전 현재 공개 경로를 바꾸지 않는다.
7. 서버 외부로 주기적인 논리 백업을 보관하고 별도 DB 복원을 시험한다. 현재 보관은 서버와 맥에 각각 최근 3개이며 서버 밖 다운로드 트래픽도 outbound 포함량을 사용한다. 디스크 부족/백업 실패를 감시한다.

새 서버에서 쓰기가 시작된 후 옛 맥 DB로 단순히 되돌리면 변경이 유실될 수 있다. 롤백 시 최신 DB를 먼저 역이전한다. 기존 Serverpod Cloud 체험 프로젝트는 별도이며 이 이전으로 자동 해지되지 않는다.
