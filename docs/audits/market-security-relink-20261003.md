# 기업 마스터 변경 후 기존 종목 DB 재연결

격리 기준: `865553df`. 운영 적용·배포는 수행하지 않았다.

## 동작과 범위

기존 `MarketSnapshotFutureCall.run(Session, jobId)`의 등록/시그니처를 그대로 사용한다. `IngestJob.kind=market_security_relink`만 공공데이터 서비스키 읽기와 DataGoKrClient 생성 전에 DB 전용 경로로 분기한다. 그 외 알려지지 않은 kind는 실행하지 않는다. 모델·DTO·생성 코드·마이그레이션은 변경하지 않는다.

기업 마스터 작업이 실제 `company_master` 종류이고 성공했으며 updated>0일 때만 요청한다. startup에서는 상장회사와 미연결 저장 종목의 실제 식별자 고유 매칭이 있는 경우만 예약한다. 중복 crno/stockCode, 서로 다른 회사로 향하는 두 식별자, 비상장 회사, 이미 연결된 종목은 변경하지 않는다. 이름·ISIN·사업 설명으로 추측하지 않는다.

기존 `IngestJobs.startAndSchedule`로 재연결 kind별 한 작업만 생성한다. 별도 종류와 식별자를 사용하므로 시세/지수의 날짜·예산 이어받기 예약을 덮지 않는다. 시장 작업이 running이면 같은 relink jobId를 30초 뒤 기존 run으로 예약하며 별도 `market_security_relink_resume` 식별자를 교체해 하나만 남긴다. 이는 신규 cron이나 FutureCall 메서드가 아니다.

## 레이스와 복구

재연결 트랜잭션은 relink 시작 잠금 → market_snapshot 시작 잠금 → 자신의 job 행 잠금 순서로 진행한다. 정상 시장 start와 기존 시장 작업 claim도 같은 market 잠금을 사용한다. 따라서 시장 신규 실행·실패 작업 재개가 재연결 중간에 시작하지 않는다. 이미 running 시장 작업이 있으면 데이터 갱신을 하지 않고 지연한다. 중복 relink 호출은 같은 잠금 후 job의 running 상태를 다시 확인하므로 성공 후 재갱신하지 않는다. 실패한 옛 relink 호출은 새 작업 옆에서 되살리지 않는다.

회사 식별값은 재연결 트랜잭션의 share row lock으로 보호하고, Security에는 여전히 companyId가 null이며 shortCode/crno가 읽은 원형과 같은 행에 companyId/linkBasis 두 컬럼만 조건부 갱신한다. 원래 Source/sourceId와 종목 식별값, lastSeenDate는 보존한다. 시장 시세·지수·날짜 원장·API 예산 및 기존 시장 작업 카운터는 쓰지 않는다. 자체 작업의 updated는 실제 조건부 갱신 행수이다.

취소와 완료는 기존 job 행 잠금으로 순서가 정해진다. 먼저 커밋된 취소는 dispatch·지연 예약·재연결을 막는다. 이미 진행 중인 원자적 DB 트랜잭션이 먼저 끝나면 완료이며 뒤의 취소는 완료를 덮지 않는다. 취소 전에 저장된 지연 FutureCall은 남을 수 있으나 실행 시 cancelled 상태를 확인해 무동작으로 끝난다. startup은 마지막 relink가 cancelled이면 자동 재생성하지 않는다. 새로운 실제 마스터 변경은 새 요청을 만들 수 있다.

예약 실패는 정상 fail 작업으로 남기고, 다음 startup에서 실제 미연결 매칭이 있을 때 복구한다. 기존 recoverInterrupted가 새 kind의 기존 MarketSnapshotRunFutureCall(jobId)을 인식하도록 prefix를 등록한다. 이미 저장된 예약이 있는 interrupted 작업은 추가 생성하지 않는다. 취소/예약 교체의 서버 중단 구간은 startup orphan 복구 대상이며, 서버가 살아 있는 중 예약 자체가 실패한 경우 무한 자동 재시도하지 않고 실패 상태를 표시한다.

## 화면

기존 공통 IngestMonitor 목록에 kind를 추가해 완료 시 dataVersion을 갱신한다. 새 poller는 만들지 않는다. 데이터 화면 시세 카드에 별도 '기존 종목 재연결 · 시세 API 호출 없음' 상태와 관리자만 제공하는 기존 ingest.cancel 버튼을 붙인다. 이 작업을 시세 전체 수집 완료로 표시하지 않는다.

## 검증

- 서버 순수 매칭 4 + 기존 생성 등록 3: 7 PASS.
- 정상 DB 재연결 9 + 기존 작업/예약 회귀 14: 23 PASS. 단일 프로세스, 전용 PG 종료 확인.
- DB에 실제 Source/시세/시세 날짜 원장/지수/지수 날짜 원장을 넣고 전체 JSON 불변 확인. 정상 run의 apiCalls=0, Source/sourceId·기존 종목 원형 보존.
- 요청 coalesce, 시장 running 시 동일 jobId의 지연 예약 하나, admin 취소와 reader 거부, orphan 복구/예약 보존, 다른 kind·실패한 옛 호출 무동작, 성공+변경된 master만 예약, 두 세션 시장 start/claim 공유 잠금 대기 확인.
- Flutter 공통 monitor 5 + 상태/취소 UI 2 + 디자인 경계 2: 9 PASS.
- 최종 scoped analyze 0, format 13 files/0 changed, diff check 통과.

로그: `/private/tmp/io-market-security-relink-db-final.log`, `/private/tmp/io-market-security-relink-flutter-final.log`. 운영 데이터에 재연결이 완료됐다는 주장은 하지 않는다.
