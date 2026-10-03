# 정확 두 원문 독립 CE 모순 차단

기준 2d95d585. 외부 GET/API/운영 변경 0. 캐시 원형을 변경하거나 기존 저장 자료를 삭제하지 않는다.

- 도부 01109690 / 20250324000541 / OFS / 2024.01.01~12.31: BS 총자본 834,482,799원, CE `2024.12.31(당기말)` 전체 총자본 834,482,800원. 인쇄 단위 원. 1원 차이를 허용하거나 보정하지 않는다.
- 퓨쳐메디신 01185867 / 20220322000964 / CFS / 2021.01.01~12.31: BS·CE 총자본은 7,178,098,852원으로 일치하지만 CE 당기말 라벨은 원문 `202.12.31 (당기말)`이다. 부모 열5·NCI 열6과 구분되는 전체 열7을 읽으며, 인쇄 연도를 2021로 고치지 않는다.

일반 날짜 표기 8계정 경로의 선택적 CE 검사에 의해 두 원문은 이전 parser+MockFetcher에서 8행을 반환했다. 이번 helper는 회사·접수·basis·시작/종료일·표지/재무 URI 전체·두 원문 SHA가 정확히 같은 경우에만 실제 행을 재대조하고 typed 실패를 만든다. 수정된 원문, 다른 basis·회사·접수는 이 한정 예외가 아니라 기존 검증을 따른다.

오류 Source는 `financial-source-conflict:<receipt>:<basis>` 참조로 정상 transaction/advisory lock 아래 한 건만 기록한다. 실제 재무 URI/두 SHA/비교값·실패 이유와 `financialFactsStored:false`를 남긴다. FinancialReport/Fact 생성 및 API/숫자 재시도 정책 변경은 없다. 취소 시 새 오류 감사도 만들지 않는다.

표지·본문·shell 원형은 test/fixtures/financial_html/known-conflicts, URI/SHA는 evidence.json에 보존했다. 승인된 다른 7/8계정 및 썬테크 FY2022 거부 회귀 포함 순수 58개 PASS. 정적 분석 오류 0. 정상 큐 DB2는 최초 시도에서 macOS semaphore 부족으로 setUpAll 이전 중단했으며 데이터 검증 실행 성공으로 보고하지 않는다. 환경 해소 후 재실행 결과를 별도로 기록한다.

## 이후 실제 검증 결과

슬롯 반환 후 두 번째 실행도 동일 semaphore 부족으로 테스트 본문 이전 중단했다. 부모가 종료된 본작업 PG의 고유 semaphore만 안전하게 회수한 후 세 번째 실행은 테스트 본문에 진입했으나, 기존 실패 정책 `attempts+1`을 반영하지 않은 테스트 기대값에서 실패했다. 생산 카운터 정책은 수정하지 않았다.

정상 실패 카운터 증가를 매 run마다 검증하고, 공개 attempt 1→2→3 이후 세 번째 run에는 신규 조회가 없음을 검증하도록 fixture를 보완했다. 네 번째 실행 `/private/tmp/io-known-conflict-db2-fourth.log`에서 실제 정상 큐 DB2가 13초에 모두 PASS했다. API calls 0/일일 사용량 20,000 유지, 숫자 Report/Fact 신규 저장 0, 반대 basis의 Source·Report·Fact 전체 JSON 불변, 실패 Source 한 건, 실제 본문 URI/SHA와 거부 근거를 확인했다. 세 번째 capped run에서도 실패 Source나 숫자를 중복 저장하지 않았다.

추가 직접 witness 단언 순수7개 PASS: 도부 BS834482799/CE834482800, 퓨쳐메디신 인쇄 `202.12.31 (당기말)` 및 전체 총자본7178098852가 그대로 보존된다. 앞선 환경 실패와 기대값 실패를 DB 검증 성공으로 합산하지 않는다.
