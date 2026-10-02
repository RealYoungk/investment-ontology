# 투자회사 고정 원문 보존 단계

## 범위와 호출 경로

9e135ca8 기준. 검토된 12개 연간 PDF와 각 회사의 최신 원문 3개를 `assets/issuer_documents/verified_fund_documents.json`에 고정한다. 맥쿼리와 맵스는 2021~2025 각 5개, KB발해는 2024~2025 2개이며 KB발해 2021~2023은 미확보다. 이 목록은 미래 자료 자동 발견이나 재무 숫자 수집 완료를 의미하지 않는다.

기존 `DisclosureFutureCall.runBusiness`의 정상 예약 진입에서 독립 원문 단계를 실행한다. 원문 단계는 DART 키·예산을 소비하지 않고 기존 본문 job의 상태·건수도 바꾸지 않는다. 실제 실행은 production 모드이며 `ISSUER_DOCUMENT_CACHE_DIR` 설정이 있을 때만 가능하다. 일반 테스트·개발 모드에서는 외부 HTTP를 실행하지 않는다. 새 FutureCall/모델/DTO/생성 변경이 없다.

메타데이터는 기존 ResearchSnapshot(kind=issuerDocuments)과 Source(kind=officialFile)에 저장한다. `research.data`로 공개 메타데이터를 읽을 수 있다. 기존 `importFeed`의 Scope.admin 검사는 유지한다. 금액은 notExtracted/null이며 Source에 실제 읽기 범위, 원문 SHA, 최초 다운로드 시각, 독립 KIND 접수와 문서 ID를 남긴다. 게시일을 얻지 못한 맥쿼리 연간 원문은 publishedAt=null로 보존한다. 게시일을 파일명이나 다운로드일로 채우지 않는다.

## 원본 파일과 배포 계획

PDF는 공개 경로에 서빙하지 않는다. 고정 공식 URL만 GET하고 redirect를 따르지 않으며 원본 SHA/매직헤더/20MB 상한을 검사한다. 신규 GET 발사는 1초 이상 간격이며 GET 전·응답 스트림·cache 저장·DB 저장 직전에 취소를 확인한다. 기존 SHA cache가 손상되면 덮어쓰거나 완료로 간주하지 않는다. 회사별 모든 지정 PDF가 확인된 뒤 immutable snapshot transaction을 실행하고 회사 row lock 아래 중복을 제거한다.

영속 원본까지 보존하려면 배포 담당자가 비공개 host 경로 `/opt/alfinder/issuer-documents`를 전용 컨테이너 경로 `/var/lib/alfinder/issuer-documents`에 rw로 mount하고 `ISSUER_DOCUMENT_CACHE_DIR=/var/lib/alfinder/issuer-documents`를 설정해야 한다. Caddy/Cloudflare 정적 경로에는 연결하지 않는다. 이 패치에서 운영 mount/권한/배포는 실행하지 않았다.

기존 Dockerfile은 `adduser -S -G serverpod ...` 후 `USER serverpod`를 사용하지만 숫자 UID를 지정하지 않는다. 따라서 UID를 100 또는 1000으로 추정하면 안 된다. 배포할 정확한 이미지에서 비네트워크 `id -u serverpod`/`id -g serverpod`를 읽고 그 UID/GID에만 host 경로 쓰기 권한을 부여해야 한다. 기존 compose는 server용 원문 volume이 없으므로 환경변수만 설정하면 영속성이 확보된다는 주장을 할 수 없다.

## 현재 검증 상태

단위 및 기존 생성 등록 회귀 29개 통과, scoped analyze 오류 없음. 실제 목록 15개, 기간·SHA·제공자 ID·숫자 null, cache 재사용·손상·SHA 불일치·redirect·취소를 검증했다. 실제 PDF 15개 전체 숫자를 분석한 테스트가 아니다. 격리 DB 회귀 2개도 통과했다. 실제 PDF fixture 3개(MK2024, KB2024, 맵스2026반년)를 HTTP MockClient로 재생하여 원본 SHA, Source 공식 파일 유형, 최초 다운로드 시각과 원문 proof, 공개 JSON, 중복·새 관측·기존 불변 행, admin mutation 거부를 확인했다. 잘못 회사·변조 SHA·미완료 fetch·취소는 최신 snapshot을 바꾸지 않았고 FinancialReport/BusinessDocument/IngestJob/APIusage 수는 그대로였다. 외부 GET/API/운영 저장·배포는 수행하지 않았다.
