# 로컬 개발 DB

운영 서비스는 iwinv DB를 사용한다. Mac에는 같은 embedded PostgreSQL 클러스터 안에 두 개의 별도 데이터베이스를 둔다. 코드/채팅 포크가 아니다.

| 이름 | 목적 | 쓰기 |
| --- | --- | --- |
| `investment_ontology_serverpod` | 운영 이전 시점 보관본 | 기본 읽기 전용 유지 |
| `investment_ontology_dev` | 기능 개발·로컬 검증 | 허용 |

`config/development.yaml`의 `database.name`으로 앱이 사용할 DB를 선택한다. `dataPath`는 기존 `.serverpod/development/pgdata`를 유지한다. 두 DB는 논리적으로 분리되지만 PostgreSQL 프로세스와 디스크를 공유한다. 클러스터 디렉터리를 삭제하면 둘 다 사라지므로 초기화 목적으로 삭제하지 않는다. 기존 운영 이전 백업은 별도로 유지한다.

## 생성

`python3 scripts/ops/create_local_dev_database.py`

실행 중인 로컬 PostgreSQL 소켓만 사용한다. 원본을 일관된 읽기 전용 스냅샷으로 논리 복제하며, 이미 대상 DB가 있으면 덮어쓰지 않는다. 비밀번호는 기존 로컬 비공개 파일에서 읽고 출력하지 않는다. 원본과 핵심 테이블 건수를 대조하고 개발 DB 쓰기를 롤백으로 검증한다. 실패한 복사본은 조사용으로 남기며 앱 설정을 자동으로 변경하지 않는다.

## 운영과 개발의 분리

- `futureCallExecutionEnabled: false` 유지. 운영의 재무 백필·일일 수집을 개발 DB에서 중복 실행하지 않는다.
- 같은 DART 키의 호출 한도는 DB가 달라도 공유된다. 개발 DB의 복사된 과거 사용량만으로 남은 운영 호출량을 판단하지 않는다.
- 원본에 포함된 기존 계정과 권한도 로컬에 복제된다. 공개 읽기·관리자 쓰기 규칙을 그대로 적용하며 개발용 인증 우회를 추가하지 않는다.
- 로컬 변경은 운영으로 자동 전송되지 않는다. 운영 배포/마이그레이션/수집은 별도 절차다.
- 보관본 확인이 필요하면 읽기 전용 DB로 직접 접속한다. 개발 작업을 위해 보관본의 읽기 전용 설정을 해제하지 않는다.

## 상태

2026-10-01 복제 및 앱 연결 완료. 원본 `default_transaction_read_only=on`, 개발 `off`를 환경변수 덮어쓰기 없는 새 연결에서 확인했다. 개발 DB의 임시 테이블 쓰기/롤백 성공. 최초 검증 스크립트가 원본용 읽기 전용 세션 옵션을 개발 검증에도 적용한 오류는 수정 후 재검증했다.

건수 대조: company 2,763; financial_report 111,241; financial_fact 16,467,728; market_snapshot 3,403,018; business_document 2,855; research_snapshot 0. 모두 원본과 일치한다. 앱 재시작 후 PostgreSQL 연결 10개가 개발 DB를 사용하며 `research/data` 공개 조회 HTTP 200을 확인했다. 최신 마이그레이션 적용 상태 정상. 신규 연구 자료는 아직 미수집이다.
