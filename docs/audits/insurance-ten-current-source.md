# 보험 연간 원문 10기준의 정확한 부분 핵심계정 복구

기준 c6491d31의 기존 보험 5개 프로필은 보존하고 다음 10개를 추가한다. registry 203→213이며 범용 파서·재시도 횟수·동기화 예산·인증 계약은 변경하지 않는다.

|접수|회사|실제 연간기간|지원 기준|
|---|---|---|---|
|20220308000939|삼성생명보험|2021.01.01~12.31|CFS/OFS|
|20220323000792|롯데손해보험|2021.01.01~12.31|OFS|
|20221017000313|미래에셋생명보험|2021.01.01~12.31|CFS/OFS|
|20230309000797|현대해상화재보험|2022.01.01~12.31|CFS/OFS|
|20230317001035|미래에셋생명보험|2022.01.01~12.31|CFS/OFS|
|20230323001495|롯데손해보험|2022.01.01~12.31|OFS|

운영 공개 장부 읽기 확인: 모든 접수는 최근 5개 연간 회계연도 내 동일기간 최종 접수이며 대상 10기준 실패, API attempts3/publicattempt3이다. 해당 정확 접수 FinancialReport는 0개였다. 롯데 CFS는 기존 noData이며 신규 숫자 지원 대상이 아니다. 이 조회는 작업 시점 스냅샷으로 향후 운영 상태를 보장하지 않는다.

각 프로필은 공식 shell의 법인코드·접수, 표지·해당 기준 원문 URI의 여섯 좌표와 raw SHA256, 실제 회사명·연도·기간 및 현재 셀의 전체 행을 고정한다. 표지 연간기간과 CIS/CE/CF의 독립 완전 시작·종료일, BS A=L+E, 전체 CIS NI=현년도 CE 전체 NI, CE 말자본=BS 자본, CE 초자본=전기 BS 자본, CF 활동합/인쇄 증감/현금 롤과 당기·전기 BS 현금이 모두 인쇄단위에서 일치했다. owners 순익 및 라벨 괄호 안 조정이익은 금액으로 사용하지 않는다.

미래에셋 OFS 2021/22는 독립 환율효과 행이 미인쇄다. 해당 프로필은 인쇄된 활동합·증감·기초·기말만 대조하며 `exchangeCash:null`, `exchangeCashPrinted:false`, `exchangeCashMissingNotAssumedZero:true`를 보존한다. 0-valued FX 행은 생성하지 않는다. 나머지 원문의 환율효과 포함/별도 증감 구조도 원문대로 유지한다.

원문 직접 총행 7개(자산/부채/자본/영업수익/영업이익/전체 순손익/CFO)만 저장하며 account_id는 null, 인쇄 이름과 금액셀은 변경하지 않는다. `fullStatementCollected:false`, capex 미수집을 표시한다. 전체 재무제표 수집 완료 주장이나 원문 매출 합산은 없다. 삼성생명 FY2021은 네 표에 각각 백만원이 인쇄되어 FinancialFact KRW 계약에 따라 1,000,000배 환산하고 원문 문자열·표/행/열·인쇄단위·환산배수를 Source audit에 보존한다. 나머지 표는 각각 원 단위다. 이는 DocumentFact의 원문단위 보존 정책과 다른 FinancialFact 계약이다.

NI 라벨 8개의 정확한 전체 인쇄 문자열만 기존 공용 Dart/SQL fallbackNames에 추가한다. 조정주석 정규식은 넓히지 않는다. 표제 로마숫자와 공백 제거 외의 금액·주석 숫자·라벨 변형, owners/EPS는 거부한다. 정상 캐시 once-audit 경로를 사용하므로 public3 이후도 reset 없이 정확 source digest별 1회 복구하며 반대 기준 기존 보고서·Source·숫자는 불변이다.

원문 읽기 근거: root outputs/filing-collection-priority/b18-insurance-ten-independent-readonly-20261003/ledger.json, review.md, live-target-metadata.json. raw 30개와 manifest·현재셀 기대값은 assets/financial_source_cache/*-insurance-current/에 고정한다. 전체 주석·PDF·모든 세부행의 완전 검산을 했다는 뜻은 아니다.

검증: 보험15 순수 테스트 121 PASS, analyze No issues, Dart7파일 format0. 순수 실제 10+기존5 파서 양성, 독립 표 단위·기간·CE/CF·BS 현금 셀 변조, 잘못된 법인·접수·기준·URI·표지·라벨 거부 및 캐시 cap3 원문 계약. 슬롯 허가 후 전용 격리 DB에서 정상 큐 10기준 모두 PASS(exit0, 33초, tearDownAll 완료). 실제 7계정/인쇄 이름/null ID/Source 단위·현재셀·미인쇄 FX 감사, summary7/SQL7, 반대 기준 synthetic 보존 sentinel, API0/attempts 불변 및 once-audit 재실행 멱등성을 검증했다. 전용 postmaster PID89539 종료(PG0)를 확인했다. 운영 DB 변경·배포는 하지 않았다. 전체 순수 합회귀 3,229 PASS, 최종 보험15 순수 121 PASS이다. 근거 로그: `/private/tmp/io-insurance-ten-db.log`, `/private/tmp/io-insurance-ten-unit-final.log`, `/private/tmp/io-insurance-ten-exact-final.log`; root 감사 기록: `outputs/filing-collection-priority/b18-insurance-ten-independent-readonly-20261003/candidate-validation.json` (검증 대상 코드 커밋 `7df09d669349714e750b0cc62f60fedbfbc92994`).

## 새 finite NI 원형 (Dart/SQL 공유)

```dart
// Exact insurance whole NI cells, independently equal to pinned CE totals.
      "당기순이익(손실)(비상위험준비금반영후조정이익(손실)당기:114,199,225,967원전기:(-)24,215,079,079원대손준비금반영후조정이익(손실)당기:120,125,439,090원전기:(-)28,815,936,079원)",
      "당기순이익(대손준비금반영후조정이익당기:75,781,712,981원,전기:77,699,663,310원)",
      "당기순이익(대손준비금반영후조정이익당기:92,823,564,486원,전기:90,024,490,823원)",
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:465,707,342,599원전기:330,317,307,787원대손준비금반영후조정이익당기:562,246,349,804원전기:405,964,567,689원)",
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:452,051,776,492원전기:336,102,116,734원대손준비금반영후조정이익당기:548,543,201,146원전기:411,689,146,425원",
      "당기순이익(대손준비금반영후조정이익당기:58,458,197,450원,전기:75,781,712,981원)",
      "당기순이익(대손준비금반영후조정이익당기:57,113,704,745원,전기:92,823,564,486)",
      "당기순이익(손실)(비상위험준비금반영후조정이익(손실)당기:(-)64,149,087,377원전기:114,199,225,967원대손준비금반영후조정이익(손실)당기:(-)55,543,106,206원전기:120,125,439,090원))",
```
