# 보안·DB 추가 점검 (2026-09-22)

로컬 실행 기준 점검과 발견된 문제 수정을 완료했다. 아래에 실행 증거와 검증하지 않은 운영 범위를 구분한다.

## 실행 범위

Serverpod 4.0.0 로컬 앱을 기준으로 점검했다. 로컬 서버와 테스트 DB는 Serverpod가 관리하는 PostgreSQL을 사용한다. Docker는 필요하지 않으며, Docker Desktop 실행 요청은 철회했다. 저장소에 존재하는 별도 배포 템플릿은 정적 검토만 한다. 실제 배포·이미지 빌드·운영 메일 발송을 완료했다고 주장하지 않는다.

Serverpod overview/auth/database/models/migrations/configuration/testing/sessions/caching/scheduling/health-checks/logging/endpoints/deployment 지침, gstack review 및 cso 점검 기준, GBrain query/smoke-test 지침을 적용했다. gstack review는 main 브랜치이므로 정식 PR pre-landing 실행과 구분하여 체크리스트로 검토했다. 앱과 무관한 업로드·스트림·FFI·유료 추출 스킬은 실행하지 않았다. 스킬 수가 검증 범위를 대신하지 않는다.

## 확인된 근거

- 실제 DB: PostgreSQL 16.13, 69 테이블, FK 72개, 인덱스 167개(고유 106개). 미검증 제약·무효 인덱스 0개. Serverpod repair-migration 검사 결과 schema drift 없음, 마이그레이션 생성 없음.
- 로컬 DB는 TCP listen_addresses가 비어 있고 Unix 소켓 디렉터리 권한은 0700이다. 개발용 postgres superuser/local trust는 이 로컬 경계 안에서 사용한다. 운영 최소권한 역할까지 검증한 결과는 아니다.
- fsync/full_page_writes/autovacuum 활성. 전역 쿼리·잠금 제한시간과 WAL archive/PITR은 설정되어 있지 않다.
- 데이터 불변식 검사: 다른 회사의 사실/요약 연결, 문서 사실·요약 중복, 잘못된 정수 원문, 비유한 숫자, 중복 실행 중 작업, 빈 근거, AI 근거 원문 불일치, 다른 회사 정정 연결 모두 0건. 현재 활성 재무보고서 기간 중복도 0건.
- FinancialFact 원화 BigInt는 Serverpod가 text로 저장한다. DocumentFact의 double은 공시의 배율 단위·비율을 유지하는 별도 타입이다. 타입 차이만으로 금액 손상이라고 판정하지 않았다.
- DB 전체 백업/복원 실험: PostgreSQL 16 도구로 2,186,784,399바이트 dump를 만들고 별도 임시 DB에 복원 성공. 69 테이블, 11,553,858행. 투자·계정 테이블 행 수 일치, 차이는 실행 중 추가되는 로그·헬스 기록뿐이었다. 복원 DB 불변식/제약 검사 통과 후 임시 DB만 삭제했다. 백업 파일은 권한 제한된 /tmp에 남겼으며 정기·외부 백업을 구성한 것은 아니다.
- 실제 브라우저 refresh 쿠키: HttpOnly, SameSite=Lax 확인. localhost HTTP에서는 Secure=false, staging/production 설정은 Secure=true. 허용 localhost Origin에만 CORS 응답 헤더, 외부 Origin에는 없음.
- 12개 업무 endpoint의 로그인 및 관리자 변경 권한, SQL 파라미터화 검토. 익명 health live/ready/startup 200 확인. 실제 관리자 화면 확인.
- 잠금파일의 hosted 의존성 185개를 OSV 조회, 반환된 advisory 0개. git 이력의 2MB 이하 blob 1,980개에 주요 서비스 키·개인키 패턴 검사, 후보 0개. 전용 비밀 스캐너의 모든 규칙을 실행한 결과가 아니며 임의 형식 비밀값의 부재까지 보장하지 않는다.
- GBrain 로컬 검색 정상. smoke-test 핵심 3/4 통과, 임베딩 키 미설정 항목 실패/선택 항목 건너뜀. 사용자의 무료 로컬 키워드 사용 선택에 따라 유료 임베딩은 설정하지 않았다.

## 수정과 회귀 검증

- 웹 refresh 토큰을 HttpOnly 쿠키로 전환하고 허용 Origin을 명시했다. 사용자가 재로그인했고 실제 관리자 상태와 쿠키 속성을 확인했다.
- 자동 표 규칙 재실행은 문서 행 잠금/트랜잭션으로 직렬화하고 최신 문서를 다시 읽는다. 사라진 자동 결과는 제거하되 사람이 내린 결정은 보존한다. 생산/연구개발/공급 관계 동시 실행·원문 변경·행 제거 회귀 5건 통과.
- 이메일 인증 잘못된 코드·재사용, 관리자 allowlist, 비밀번호 재설정 후 이전 비밀번호/refresh token 차단 회귀 3건 통과.
- 정정공시 도착 순서에 무관하게 최신 접수번호 하나만 활성화하도록 기간별 advisory lock과 양방향 대체 판정 적용. 원본→정정, 정정→원본, 세 버전 뒤섞임 3건 통과. 과거 금액과 출처는 보존한다. 동시 재무 수집의 실제 경합 테스트는 별도로 실행하지 않았다.
- 로그인 기본 화면과 회원가입/재설정 이동을 한글화했다. 코드 입력과 비밀번호 조건 화면의 고정 높이 때문에 생긴 작은 화면 overflow를 고쳤다. 320px에서 가입·인증·비밀번호 설정 단계까지 위젯 검증했다. 사용자의 실제 비밀번호 입력/실계정 신규 가입은 대신하지 않았다.
- 선택적 Docker 컨텍스트에서 비밀 설정·관리자 목록·로컬 DB를 제외하고 SDK 요구 버전 및 non-root 실행을 맞췄다. compose의 인증 환경변수·관리자 이메일·DB 설정·마이그레이션을 보완하고 충돌하는 basic auth를 제거했다. 이미지 빌드는 수행하지 않았다.
- CI에서 불필요한 Docker 실행을 없애고 전체 워크스페이스 분석/수기 코드 포맷/Flutter 테스트를 포함했다. GitHub에서 확인한 action commit으로 고정했다. 원격 CI는 PR #77에서 실행하며 최신 결과는 해당 체크를 따른다.
- 최종 서버 전체 273개 통과. 카운트다운 반영 후 깨끗한 checkout에서 Flutter 전체 55개 통과, Web release 빌드 성공. 정적 분석 오류 없음. 앱 hot restart 후 실제 관리자 로그인 유지, 최근 서버/Flutter 로그 오류 없음.

## 해석과 한계

JWT access token은 기본 10분 동안 유효하다. refresh token 폐기는 즉시 적용되지만 이미 발급된 access token까지 즉시 소멸하는 방식은 아니다. 실제 사용자 자격증명은 자동 테스트에 사용하지 않았다. 테스트는 격리 DB의 합성 계정으로 실행했다.

현재 데이터가 정상이라는 관찰은 모든 미래 공시 형태의 정확성을 증명하지 않는다. 운영 HTTPS/메일/최소권한 DB/백업 보관 정책과 외부 배포 검증은 별도의 운영 작업이다. 본 검토는 자동화된 코드·설정·실행 검사이며 전문 침투 테스트나 보안 무결점 보증이 아니다.

공식 근거: [Serverpod 웹 인증](https://docs.serverpod.dev/concepts/authentication/web-authentication), [JWT](https://docs.serverpod.dev/concepts/authentication/token-managers/jwt-token-manager), [설정](https://docs.serverpod.dev/concepts/lookups/configuration-reference), [4.0 업그레이드](https://docs.serverpod.dev/upgrading/upgrade-to-four), [PostgreSQL dump](https://www.postgresql.org/docs/16/app-pgdump.html). 설치된 4.0 소스와 대조했다.
