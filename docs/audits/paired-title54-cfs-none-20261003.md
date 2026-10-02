# 기존 별도 원문과 짝을 이루는 CFS 직접 비작성 15건

기준2444ecfa registry156. title54 원문54 접수와 기존154지도 비교: 반대OFS등록/CFS미등록21건 중 0TABLE 직접비작성15건만 선택했다. 숫자표3, heading-only1, TABLEwrapped1, 설명문1은 제외했다. 신규 실제본문/숫자 파서·literal 문법·Sync·retrycap 변경0, 외부GET0. 이미 캐시된 고유 owncorp/접수/shell/cover/CFS6좌표/원문SHA를 재검증한다.

## 후보 15

GNE2021 1, NS2021~22 2, CNS2021/23/24 3, BlueTop2021~25 5, Cronex2021/24 2, MoneyMove2024 1, Plumline2025 1. 각 접수·corp·인쇄 literal·URI/SHA는 paired-title54-cfs-none-source-ledger.json에 보존한다. 현재명과 과거사업을 연결하는 설명을 만들지 않는다.

반대OFS15는 모두 verified-current-period-whole-annual-v1 기존 숫자검증 패키지이며 신규 generic source6 저장거부 대상과 별개다. Plumline FY2025는 이 접수 whole7/8이 검증된 패키지이고 다른 FY의 매출 대시 partial6과 혼동하지 않는다. OFS registry등록 자체가 운영 저장 또는 완료를 증명하지는 않는다.

CFS에는 독립 strict 직접 비작성만 저장한다. 빈 노드, heading-only, 설명·조건 문장, 숫자표에서 비작성을 추정하지 않는다. CFS에 FinancialReport/FinancialFact 숫자를 만들지 않는다. 반대OFS가 실패한 경우 그 실패와 기간 미완료를 유지한다.

latest header18의 CFS5와 중복0(직접 에이전트 코드 대조). 여기 새15 package만 자체156→171, 부모 latest18과 합치면189가 예상되며 실제 통합 수는 부모가 확인한다. 기존 테스트의 CFS 미등록 가정 점검: 새15와 부모가 지적한 common_year_term/source_six_partial의 네 접수는 서로 다르므로 이번 패치에서는 해당 가정을 바꾸지 않았다. 실제 새15는 independent CFS URI/SHA·OFS변조 거부로 별도 검증한다.

## 검증

- 신규 CFS15와 기존 OFS15의 실제 양성·owner/receipt/year/basis/status/cap/SHA 음성420 PASS.
- 정상 admin 큐 DB15: bothfailed→CFSnoData/OFSstored, 기존 source expectedRows 직접계정·금액 및 statement/currency/current기간/fsDiv·중복수 검증. API0/meter20000/attempt7/public3 유지, 중복없는 Source/report/facts/ledger 재실행 updated0.
- 음성 DB1: CFS 자체 비작성 Source는 정상 보존하되 반대OFS raw SHA거부 시 OFSfailed/report0/facts0/기간 미완료1 유지. CFS비작성만으로 숫자 완료를 주장하지 않음.
- 초기 DB 실행의 원문순서와 public report 정렬순서 차이는 숫자·계정명 오류가 아니며 전체 tuple unordered 검증으로 정상 정렬 정책을 보존했다.

운영 쓰기·배포·API예산 리셋·새6계정 저장 활성화 없음. 순수 원문 패키지 및 테스트만 추가한다.
