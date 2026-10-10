# 기업 분류 사전 계산과 영구 저장 — 2026-10-09

사용자 결정: 페이지에 들어갈 때 분류하지 않는다. 서버에서 미리 분류하고 저장된 결과를 조회한다. 앞선 메모리 warm cache만으로는 서버 재시작 시 다시 원문을 처리하므로 이 요구의 최종 구현이 아니었다.

## 저장·조회

`industry_catalog_snapshot`의 단일 활성 row에 전 상장사 분류, 반도체 pilot, 원천 fingerprint, builderVersion, computedAt을 저장한다. 근거·공시 번호·기간·분류 기준은 기존 IndustryActivity 그대로 보존한다. snapshot을 한 트랜잭션으로 교체하며 PostgreSQL advisory lock으로 프로세스 간 writer를 제어한다.

`industry.browse`와 `industry.discover`는 저장된 snapshot만 읽는다. snapshot이 없으면 준비 중 오류를 반환하며 원문 처리·분류·쓰기 fallback을 수행하지 않는다. 서버 재시작 시 DB snapshot을 먼저 메모리에 올린다. 업종 선택 화면은 별도 서버 호출 없이 표시한다.

## 갱신

서버 background 작업은 시작 시와 5분 주기, 기업마스터·공시·사업 본문 작업의 terminal 저장 후 원천 변경을 확인한다. 개발 서버에서도 기존 공용 원천의 파생 snapshot을 준비하지만 원천 수집을 시작하지 않는다. production에서는 futureCallExecutionEnabled인 worker만 snapshot을 작성하고 조회 전용 API process는 DB의 저장 결과를 다시 읽는다.

기업 코드·종목코드·이름·시장·등록 업종, 최신 연간 본문 ID/해시·기간·접수번호, KSIC 자료, KIND/발행사 자료, 현재 연도와 builderVersion이 fingerprint에 포함된다. 값이 같으면 원문 분류를 하지 않는다. 규칙/정규화 소스를 변경할 때 `AllIndustryCatalog.builderVersion`을 올리고 서버를 재시작한다. builderVersion은 저장 형식/계산 갱신 번호이며 공개 분류 ruleVersion12의 의미 검증 범위를 확대하지 않는다.

갱신 중에는 기존 snapshot을 제공한다. 빌드 전후 fingerprint가 다르면 결과를 발행하지 않고 다음 갱신으로 넘긴다. 실패 시 마지막 정상 row를 보존한다. 수동 `industry.rebuild`는 OntologyAccess의 admin 검사를 통과해야 하며 익명/일반 계정에는 허용하지 않는다. 로컬 인증 예외를 추가하지 않았다.

## 검증

- MCP migration `20261009120546476-stored-industry-classification` 생성/적용. 테이블 추가만 있고 기존 데이터 파괴 없음.
- 로컬 저장 결과 2,759개 상장사/6,749개 활동이 변경 전 전체 활동·근거와 동일.
- 서버 restart 전후 computedAt `2026-10-09T12:08:32.832429Z` 및 반도체 activity 전체 동일. restart 후 조회15.614ms/173,384bytes. 원문 재분류 없이 DB 결과가 복원됨.
- 대상 analyze 오류/경고/info 없음. 서버 생성 등록3 및 통합1, Flutter14 tests 통과.
- 통합 검사: 미준비 익명 조회는 snapshot을 생성하지 않음; 원천만 추가해도 조회는 기존 분류 유지; 명시적 사전 계산 뒤에 새 기업 반영; 원천 테이블을 임시로 이름 변경하여 조회 불가능하게 해도 browse/discover 정상; 원천 불변 시 computedAt 유지; builderVersion 변경 시 재계산; 익명/일반 계정의 rebuild 거절과 테스트 admin 허용.
- 기존 generated test group helper는 설치 serverpod_test4.0.0에 없는 ephemeralDatabase 인자를 넘겼다. generated 파일을 수정하거나 의존성을 올리지 않고, 해당 버전의 공개 test harness와 실제 generated endpoint dispatch를 사용하는 작은 전용 테스트 harness를 작성해 통합 검사를 완료했다.

이 검증은 분류 저장/조회·재시작 계약 검증이다. 전 상장사 사업의 의미 정확성을 새로 검증했다는 뜻은 아니다. 운영 migration·배포는 아직 진행하지 않았다.
