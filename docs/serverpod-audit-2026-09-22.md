# Serverpod 점검 및 후속 수정 — 2026-09-22

## 현재 상태

이 문서는 같은 날의 초기 점검 보고서를 갱신한다. 초기 보고서에서 미수정으로 남겼던 수집 동시성, 시작 hooks 순서, Flutter 응답 순서는 수정했다. 사용자가 추가로 선택한 로그인·사용자 권한도 구현했다. 사용자 가입 완료 후 실제 관리자 표시와 로그인된 주요 화면까지 검증했다. 아래에 검증 범위를 구체적으로 기록한다.

## 구현과 검수 분담

Claude Code 구독 로그인으로 세 개의 범위를 나누어 구현했다. 각 작업에 AGENTS.md 및 관련 Serverpod/Dart/Flutter SKILL.md 경로와 수정 가능 파일을 명시했다. Codex는 diff를 독립 검수하고 통합·보완·테스트 실행을 담당했다. 모델 API 키는 사용하지 않았다.

적용 기준: serverpod-overview, sessions, logging, caching, database, scheduling, endpoints, auth, configuration, testing 및 Flutter 아키텍처·위젯 테스트 스킬. 기존 디자인 시스템 예외를 적용해 테마 토큰을 유지했다.

## 해결한 사항

1. **스크리너 백그라운드 갱신 실패**: 이전 캐시 유지, 오류 및 stackTrace 기록, 수동 세션 종료, 다음 요청 재시도. 실패 주입 테스트에서 세션 종료와 로그 출력을 확인했다.
2. **수집 중복 실행**: kind별 PostgreSQL transaction advisory lock 안에서 확인·생성. 기존 작업이면 같은 작업을 반환하고 예약은 새 작업 생성자만 실행한다. 예약 실패 시 실패 상태로 정리한다. 12개 병렬 시작 및 12개 병렬 예약에서 작업·예약 한 개를 검증했다.
3. **취소 경합 및 완료 재실행**: cancel/claim/save/fail에 row lock과 최종 상태 보호를 적용했다. 취소 직후 늦게 도착한 진행·성공·오류 저장이 취소를 덮지 않으며 성공한 작업은 claim하지 않는다.
4. **시작 순서**: pod.start가 FutureCall 실행을 시작하기 전에 IngestSchedule.installHooks 실행. 생성 dispatcher는 기존처럼 ingest_schedule에 격리했다.
5. **Flutter 응답 순서·로그아웃**: 이전 조회 응답은 상태 변경 전에 무시. 로그아웃 때 polling 중단, 진행 응답 무효화, 다음 로그인 때 재시작. 실제 대기 없는 Completer/fake timer 테스트로 검증했다.
6. **로그인·권한**: 모든 ontology endpoint에 Serverpod 내장 로그인 요구. 일반 사용자는 공유 데이터 조회, 관리자는 수집·AI·테마·검수·인물 연결 변경. 변경 함수 시작에서 서버가 Scope.admin 검사. UI에서도 변경 요청을 차단하고 역할과 로그아웃을 표시한다.
7. **관리자 지정**: 사용자 지정 이메일은 gitignored 로컬 허용 목록에 저장. verified account 생성 callback에서만 admin 부여. 첫 가입자 자동 승격 없음. 기존 scope 보존·불일치 이메일·빈 목록 테스트 통과. 상세는 access-control.md.
8. **로그인 화면·상태 초기화**: 로그인 전 데이터 화면을 mount하지 않으며 로그인 후 deep link 유지. 로그아웃이나 계정 ID 변경 시 이전 화면 상태를 버린다.
9. **구독 세션 제출 도구 호환성**: digest/submit.py에 환경변수 bearer token 지원 및 무토큰 제출 거부. dry-run은 계속 무토큰 지원. 실제 제출 없이 mock transport 검증.
10. **이전 생산 추출기 수정 재검수**: 표·절·회사 경계 단위 처리와 회귀 10개 유지. 기존 생산능력·실적 380건 읽기 전용 대조에서 수정 전후 불일치 0건. 전체 원문 의미 정확성 보장은 아니다.

## 코드 생성 복구

작업 도중 Serverpod 4.0 watch generator가 helper 파일 변경을 analyzer에 전달하지 않아 ingest/ai endpoint를 생성 코드에서 누락했다. 설치된 CLI의 defaultProtocolChangeClassifier 및 affectedPaths 처리를 확인했고, IngestJobs에 의도와 `extends Endpoint` dependency marker 주석을 추가해 helper 변경도 analyzer 갱신에 포함시켰다. 자동 생성으로 API가 복구됐으며 generated registration 테스트가 통과했다. 생성 코드의 함수·모델은 수동 편집하지 않았다. 유지보수 시 CLI watcher 개선 이후 marker 제거 가능 여부를 확인할 수 있다.

## 검증

- 전체 서버 테스트: **262개 통과**.
- Flutter 전체 테스트: **46개 통과** (계정 직접 교체 상태 폐기까지 포함).
- workspace dart analyze: 이상 없음. 변경 Dart 파일 format 적용.
- 실제 서버: 익명 read 요청 24개를 동시성 8로 호출해 모두 HTTP 401. 관측 p95 74.3ms. 이는 인증 차단 경로 점검이며 로그인된 스크리너 계산의 부하 성능 측정은 아니다.
- 실제 앱: Serverpod MCP로 실행·재시작. DTD 연결 및 driver health 성공. driver frame sync를 끈 뒤 주요 화면과 기업 상세를 탐색했고 CUA로 실제 데이터 렌더링을 교차 확인했다. 종료 전 frame sync를 다시 켰다.
- 운영 DB migration 버전 `20260922010854397`은 registry 최신과 일치. 전체 schema drift 검증을 뜻하지 않는다.
- 새 모델/마이그레이션 없음. 기존 원천 데이터 재추출·배포·커밋·푸시는 하지 않았다.

## 실제 사용자 확인 및 운영 전제

계정 DB는 적용 전 0개였다. 본인의 비밀번호는 사용자가 직접 정하고 가입·재로그인해야 한다. 개발 모드는 가입 인증 코드를 이메일이 아닌 서버 콘솔에 표시한다. 최초 관리자 가입 후 재로그인이 필요한 이유와 운영 메일 설정은 access-control.md 참조. 사용자가 가입을 완료했고 관리자 scope가 있는 계정 1개를 확인했다. 재로그인 및 최종 서버/앱 재시작 후에도 실제 화면의 관리자 표시와 JWT 갱신·로그인 상태 확인 성공을 확인했다.

새 외부 배포는 요청하지 않았으므로 하지 않았다. production 예시 호스트·HTTPS·실제 이메일 발송 서비스 설정은 배포 환경 정보 없이 임의로 만들지 않는다. 이번에 구현한 로그인/권한을 근거로 인터넷 공개 배포가 검증됐다고 주장하지 않는다.

## 참고

[공식 Sessions 문서](https://docs.serverpod.dev/concepts/sessions), [Authentication basics](https://docs.serverpod.dev/concepts/authentication/basics). 공식 페이지 기본 버전은 조회 당시 3.4.0이어서 4.0.0 관련 세션·FutureCall·이메일 callback 동작은 실제 설치 패키지 소스와 대조했다.

## 최종 실제 화면 검증

- 시장, 기업 목록, 스크리너, 관계망, 지분 묶음, 테마, 데이터 페이지를 Flutter driver로 탐색했다. 스크리너에서는 계산 가능한 2,189개사와 실제 결과 행을 확인했다.
- 삼성전자 상세 개요와 재무·사업의 내용·지배구조·주주환원·공시 항목 탭을 직접 전환했다. 재무 출처, 사업 본문/값, 지배구조 회사 연결, 배당·자기주식 표, 공시 항목 조회를 확인했다. 관련 서버 API success 로그도 확인했다.
- 가입 완료 직후 읽기 전용 표시, 재로그인 후 관리자 표시, 최종 재시작 뒤 관리자 유지 확인. 로그인 화면에는 개발 모드 메일 미발송/콘솔 코드 안내를 추가했다.
- 마지막 analyze 이상 없음, diff --check 통과, 서버 262개·Flutter 46개 전체 테스트 통과.
- 실제 외부 API 수집이나 AI 과금 작업을 검증 목적으로 실행하지 않았다. 변경 요청의 허용/거부와 동시성은 격리된 테스트 DB에서 확인했다.
- 이는 위 경로의 기능 검증이다. 모든 기업·모든 입력 조합·인터넷 공개 배포·대규모 부하 성능까지 보증하는 전수검사는 아니다.
