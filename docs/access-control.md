# 로그인과 권한

2026-09-22 사용자 선택으로 로컬 앱에도 Serverpod 내장 이메일 로그인을 적용했다.

- 비로그인: 업무 데이터 API 접근 불가.
- 로그인 사용자: 공용 기업·시장 데이터 조회 가능.
- 관리자(`Scope.admin`): 수집 실행/취소/재추출, AI 결과 제출, 테마 변경, 검수 결정, 인물 연결 거부 가능.
- 화면의 버튼 제한과 별개로 서버가 변경 요청을 검사한다. 기존 데이터는 계정별로 복제하거나 분리하지 않는다.

## 최초 관리자

서버 패키지의 `config/admin_emails.local`에 지정한 이메일만 이메일 인증 후 관리자 권한을 부여한다. 이 파일은 gitignore 대상이다. 배포 환경에서는 `ONTOLOGY_ADMIN_EMAILS`(쉼표 또는 공백 구분)가 파일보다 우선한다. 빈 목록이면 누구에게도 관리자 권한을 자동 부여하지 않는다. 첫 가입자라는 이유로 권한을 주지 않는다.

가입 화면에서 비밀번호를 직접 설정한다. 개발 모드는 인증 코드를 이메일로 보내지 않고 `serverpod start` 콘솔에 표시한다. staging/production에서 기본 메일 발송은 Serverpod Cloud 서비스 설정이 필요하다. 다른 환경에 공개 배포하기 전 메일 발송과 HTTPS 주소를 실제 값으로 설정해야 한다.

현재 Serverpod 4.0의 최초 가입 응답은 계정 생성 콜백 전의 scope를 사용한다. 지정된 관리자는 가입 완료 후 로그아웃하고 다시 로그인하면 관리자 scope가 담긴 새 토큰을 받는다. 기존 계정의 관리 권한 변경·회수는 AuthUsers 관리 API로 수행하고 기존 토큰도 폐기해야 한다. 허용 목록에서 이메일을 지우는 것만으로 기존 권한이 회수되지는 않는다.

## 구독 세션 제출 도구

`tool/digest/submit.py`는 `ONTOLOGY_ACCESS_TOKEN` 환경변수의 관리자 access token으로 인증한다. 토큰을 코드·명령 인자·문서에 저장하지 않는다. `--dry-run`은 로그인 토큰 없이 동작한다. 수동 AI/요약 작업은 사용자가 다시 요청할 때만 실행한다.

## 검증 범위

격리된 테스트 DB에서 익명 차단, 읽기 허용, 모든 수집/AI 변경 차단, 테마·검수·지배구조 권한, 관리자 허용 목록을 검사한다. 실제 사용자의 비밀번호는 테스트에서 만들거나 수집하지 않는다.

## 웹 쿠키와 로컬 실행

Flutter 웹은 Serverpod 4.0의 HttpOnly refresh 쿠키를 사용한다. 개발 HTTP에서는 Secure=false, SameSite=Lax이며 허용 Origin은 localhost/127.0.0.1의 지정 포트로 제한한다. 외부 주소를 사용할 때는 실제 Origin을 명시하고 HTTPS에서는 Secure=true로 설정한다. staging/production의 examplepod 주소는 실제 배포 주소로 바꿔야 한다.

쿠키는 브라우저 JavaScript에서 refresh 토큰을 읽지 못하게 한다. access token의 기본 유효기간은 10분이므로 refresh 폐기와 이미 발급된 access token의 만료는 구분한다.

로컬 실행과 테스트는 Serverpod 4의 관리형 PostgreSQL을 사용하므로 Docker가 필요 없다. 별도 compose/Dockerfile은 선택적 외부 배포 예시이며 이번 점검에서 이미지를 빌드하거나 배포하지 않았다.
