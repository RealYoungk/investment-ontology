# 저장 사업 원문: 검산되지 않은 운영지표 표시

2026-10-13. 원문 재수집·DB 변경 없음. 기존 `tmp/business-50-audit/capture/corpus.jsonl`의 S-Oil, 아모레퍼시픽 첫 저장 원문을 fixture로 복사했다.

`UnvalidatedOperatingSourceTables.parse(text, period)`는 BusinessTableInsight만 반환한다. 부모의 BusinessTableInsights에서 결과를 합쳐야 화면에 표시된다. DocumentFact 생성 없음.

- S-Oil: 명시된 기간과 행 단위(천배럴/천톤), 생산실적 98,008 및 과거 236,050, 공시 가동률 87.4% 등을 원문값으로 구조화. 두 번째 헤더의 생산실적/가동률 위치를 정확히 고정. 합계나 분모 검산을 주장하지 않는다.
- 아모레퍼시픽: 사업소/평균가동률 2열의 126.3% 포함. 100% 초과를 임의 삭제하지 않는다. 다른 생산실적표는 백만원/만RMB 혼합 단위여서 이번 파서에서 구조화하지 않는다.
- 생산·수주·연구개발비의 명시적 비공개, 산출곤란, 별도 계상하지 않는다는 설명은 원문 한 줄 그대로 보존한다. measures는 빈 배열이고 회사 전체 부재나 0으로 확대하지 않는다. scope는 보고기간·절·원문 대상 범위이다.
- 기존 ProductionFacts가 검산하여 읽은 행은 원문 evidence 비교로 measures에서 제외한다. 모든 measures가 제외되면 추가 카드도 생성하지 않는다.

검증: 새 단위 테스트 4개 통과. scoped 자회사 설명, 검산 미수행 문구, 출력 행 열수, 원문 기간 및 100% 초과를 확인. analyzer는 해당 새 파일 및 테스트로 실행. 전체 원문 전수 replay와 화면 검증은 부모 통합 뒤 별도 수행 필요.

추가 엄격화: 평균가동률 숫자의 % 단위는 위 3줄 안 명시 단위 또는 값 suffix에서만 읽는다. ## 경계와 새 표를 넘지 않는다. Infinity/NaN·비문자 숫자를 거부한다. S-Oil 가동률 셀도 인쇄 % suffix가 필수다. 전체 저장 export 15,261문서(850MB)에 단순 사업소/평균가동률 헤더 35문서(7개 회사), S-Oil형 2단 헤더 6문서가 존재함을 확인했다.

전수 실제 파서 replay 성공: 15,261개 문서, 1,032카드(정량 원문 17, 범위별 공시 제한 설명 1,015), 정량 관측 197개, 카드가 있는 회사 241개. 모든 카드 evidence가 저장 text substring, row/columns 길이 일치, 모든 measure finite 및 허용 인쇄단위(%, 천배럴, 천톤), 수량 measure의 period가 evidence에 존재함을 assert했다. 정량 추가는 S-Oil 2021~2026 각16관측 및 아모레퍼시픽/홀딩스 2023~2026 사업소 가동률 등이다. 설명카드는 여러 기간/자회사 범위가 각각 남으므로 1,015를 독립 회사수로 해석하지 않는다. 투자집행/취득장부값은 이 파서의 대상이 아니다.


최신기간 coverage read-only SQL 검증(2026-10-13): dart_filing.reportName의 실제 결산연월로 최신 annual과 그보다 최신인 interim을 선택하고 active disclosure_report/business_document/source와 대조했다. 2,759회사 중 2,745회사에 5,330대상 보고서(annual 2,723, newer interim 2,607)가 있다. 5,251접수번호 일치, 79첨부정정 동일기간 이전 원문 fallback이며 대상 미저장은 0이다. 모든 대상 businessContent 장부 status=stored다. 나머지 14회사는 대상 filing 자체가 로컬 장부에 없으며 원문 내용 부재와 구별한다. 모든 fallback storedReceipt <= targetReceipt를 확인했다. SQL: scripts/audit/export_business_latest_coverage.sql. 결과: tmp/business-universe-audit-2026-10-13/latest-coverage.jsonl 및 latest-coverage-summary.json.

Flutter 읽기 진단: business_guide_panel 끝은 모든 tableInsights를 generic panel에 전달하므로 새 topic은 표시 경로가 있다. 다만 topic별 해당 section 배치는 없다. 금융사업·복합매출·생산원문·비공개 설명도 매출 composition 뒤에 일괄 표시된다. operatingSourceObservation은 measure가 있어 topic/title별 history로 진행한다. operatingDisclosureLimit는 measure가 없고 historyTopics에도 없어 inline 원문표만 표시한다. 기간별 coverage의 비공개/산출불가 구분은 미지원이다. 구체 제안: 금융사업·복합매출은 매출 설명, 생산원문은 생산 블록, 제한설명은 scope 대상 블록에 배치하고 설명의 기간 history 및 비공개/정량없음/미추출 구분을 추가한다. 공유 Flutter 파일은 변경하지 않았다.

추가 읽기 진단(재무 summary 동시요청): FinancialSourceDuration.load(companyIds:[id])의 audits/anchors/partialSources 조회는 company 필터 이전 전체 Source를 가져온다. 실제 noDataAudit 806행 title 9,020,766bytes, partial source 972행 796,735bytes, anchor 191행 129,089bytes다. pg_stat_activity에서 여러 Source 조회의 ClientWrite 및 parallel MessageQueueSend를 확인했고, EXPLAIN은 noDataAudit Source 조회 Gather→Parallel Seq Scan(2workers)을 보여준다. Source 인덱스는 PK만이다. 회사 scoped annual reports/receipts/sourceIds를 먼저 가져와 audit exact reference·관련 anchor·partial source를 제한하는 수정이 우선이며, 공통 dataVersion 캐시+singleflight도 고려할 수 있다. FinancialBasis.ctes 현재 파일은 companyScope를 eligible input에 pushdown하지만 측정 당시 실행 SQL에는 그 조건이 없어 35.6초 active였다. 서버 reload 전 기존 요청인지 확인이 필요하다. 근거 tmp/business-universe-audit-2026-10-13/financial-slow-diagnosis.jsonl 및 financial-source-size-explain.jsonl. DB 변경 없음.

비12월 결산의 미래 FY 표시 확인: 미래 bsnsYear=2027인 저장 문서 13건 모두 q1이며 실제 원문 날짜는 2026년이다. 11건 source.title/filing.reportName/settlementDate는 2026.06, JTC는 2026.05, 테라뷰홀딩스는 2026.07로 일치한다. 전체 corpus에서 year와 settlementDate 연도가 다른 사례는 이 13건뿐이다. endpoint reportPeriod가 doc.bsnsYear로 만들어져 '2027 1분기'만 표시하므로 달력 보고기간을 보완해야 한다. 예: '2026.06 보고서 · 회계연도 2027 1분기'. q1을 달력 2분기로 재분류하면 안 된다. raw header에 인쇄된 기간은 그대로 유지하고 공통 fallback 기간만 source actual month로 보완한다. 근거 future-year-source.jsonl/future-year-metadata.json. 직접 3S API 읽기는 30초 timeout으로 실응답 기간 확인은 미완료지만 현재 endpoint 코드 및 저장 source의 불일치는 확인됨. 공유 코드 및 DB 변경 없음.

숫자 문법·기존 DocumentFact 감사: 새 read-only scripts/audit/business_fact_number_audit.py로 2,745회사 API factTrends 캡처 108,494개 고유 사실을 읽었다. 쉼표 천단위 grouping과 부호/괄호를 엄격히 검사했다. evidence 안 strict 숫자 일치 104,982, malformed 쉼표를 삭제해야만 일치 25, evidence 값 미포함 3,487이다. 15,261 원문 교차 검사에서 그 3,487중 3,174는 다른 원문 행에 숫자가 있으나 기간/열 정렬 재확인이 필요하다. 원문 전체에도 값이 없는 313은 전부 수주 사실이고, 150은 '-'→0 후보, 109는 인쇄 두 값 합계 후보, 54는 음수 감소량 절댓값·조/억 서술 정규화·다항 합계 등이 남아 자동 오류 판정하지 않았다. 원문 table 전체 numeric scalar 중 잘못된 쉼표 문법 셀 4,589개를 탐지했다(다른 사업·원재료 표 포함).

25개는 rndRatio13/rndExpense5/segmentRevenue6/orderDelivered1. 예 fact296111의94%는 원문0,94%, fact382574의144%는1,44%, fact391841의474%는4,74%다. 이러한 숫자는 쉼표 삭제로 다르게 해석한 확인된 문제다. 후행쉼표(3,464,)는 strict 문법에는 어긋나도 수치 자체는 맞을 수 있어 분리해서 판단해야 한다. Production/Segment/Order/Rnd 숫자 helper는 현재 [\d,]+와 쉼표 삭제로 malformed grouping을 허용한다. RndFacts.store는 당기 ratio를 검산하여 total을 고른 후 과거 연도 ratio도 저장하므로 과거 쉼표 비율이 검산 없이 verified로 들어갈 수 있다. shared helper와 DB는 변경하지 않았다. 결과 fact-number-audit.json은 모든 후보 원문 인용과 id/documentId를 포함한다. Python 컴파일 및 strict grouping/음수/괄호 자기검사 통과.

R&D 수정(2026-10-13): RndFacts.number는 명시된 %의 소수 쉼표 0,94%를 0.94로 읽고 금액의 malformed comma를 거부한다. StoredRndFacts는 매 연도 각자의 비용÷매출액=비율을 확인하며 당기 검산으로 과거 열을 승인하지 않는다. 표 자체 매출 우선, 부족한 연도는 FinancialBasis eligible source 검증 및 company-scoped 한 번의 bulk revenue SQL로 가져온다. accountDetail null, revenue 계정, 손익계산서, KRW, 사실/보고서 company·source·연도·code·fs 일치, superseded 제외를 조건으로 한다. 표 모든 연도에 매출이 있으면 financial SQL을 생략한다. store도 동일 검산 함수를 사용하나 이번 작업에서 호출·DB 쓰기는 하지 않았다.

읽기 통합: StoredRndFacts.read(session,doc,report)는 source 일치하는 annual/interim의 검산된 ephemeral facts를 반환한다. StoredRndFacts.isLegacyRuleFact로 예전 rule R&D 사실을 제외한 다음 read 결과를 합칠 수 있고 project(session,doc,report,stored)도 제공한다. independent AI/manual facts는 제거하지 않는다. InterimRndFacts는 같은 검산을 재사용하되 현재 interim 기간만 반환하며 report.settlementDate를 우선해 FY2027→실제2026.06 관측일을 유지한다. 회계연도 키와 원문 calendar 헤더 연도가 다른 당기 금융 매출도 source 보고서의 fiscal year로 읽어 헤더 연도에 연결한다. root가 endpoint를 통합했다. 새 테스트 5종(소수쉼표, 금액이상문법, 매년독립검산, 매출우선, FY날짜 및 source mismatch)+기존6종 통과.

실제 저장소/API 통합 검증: 과거 malformed R&D 비율/비용이 있었던 16회사 factTrends를 다시 호출해 모두 HTTP200(0.076~0.328초), 반환 R&D 관측의 malformed comma 삭제값 매칭 0을 확인했다. 원문 매출행 없는 회사(00107613 등)는 scoped FinancialFact SQL branch를 실제 실행했다. 독립 결과는 rnd-projection-integration/*.json 및 rnd-projection-integration-summary.json에 보존했다. 비용/비율 evidence는 최종 코드에서 각각의 인쇄 한 행을 별도로 유지하여 비연속 두 행을 하나의 인용으로 합치지 않는다. 전체회사 최종 재수집은 root가 진행하는 refresh 완료 후 다시 audit한다.

최종 숫자 감사 비교 준비: --before fact-number-audit-before-rnd-projection.json 옵션으로 원래 25사례를 corpCode/kind/asOf 기준 corrected/removed/validated-retained로 분류한다. 새 API가 없거나 숫자 근거가 부족하면 unknown 상태를 유지한다. retained의 검증 범위는 strict 인쇄 숫자와 날짜 키이며 독립적 열/스코프 검증을 의미하지 않는다. explicit 소수 쉼표 %는 lexical support로 읽지만 예전 0,94→94 값은 계속 잘못된 쉼표 삭제 사례로 탐지한다. 전체 원문에 숫자가 존재한다는 것은 열·기간·단위·회사 스코프 100% 입증이 아니다. flow total은 단순 두 값 합계 가능성을 unknown으로 남기고, 원문 header 기반 OrderFacts.verifiedRows의 정확한 evidence/unit/선택 값 일치가 있을 때만 별도 source-row proof를 붙인다. abs delivered도 같은 parser-selected row proof를 요구한다. parser SHA가 바뀌면 기존 proof는 stale로 제외한다. before 25원본은 별도 JSON으로 보존했고 전체 refresh 이후에 after를 확정한다.

시장점유율 원인·수정: 대주이엔티 원문 doc11143/15365의 경쟁사(현대엘리베이터/오티스 등) 표에서 13/12/16 같은 두 자리 점유율을 parser가 연도 머리글로 오인해 직전 한 행을 singleton 제품으로 flush했다. 명시적 연도 header와 bare 두자리 연도를 구분했고, bare 연도는 구분/품목/회사명 등 머리글에서만 허용한다. 실제 두 문서 원문 fixture와 정상 구분|25|24|23·제품 TV 반례를 검증했다. StoredMarketShareProjection은 지원되는 원문 연도표만 evidence/value/date로 재검산하고, 미지원·prose·AI/manual은 보존한다. 동일 버그의 원문 숫자행을 연도로 오인했던 정상 당사/sole-product 수치는 recover로 한정 복구하며 source guard, 날짜 guard, 기존 key 중복 제거를 적용한다.

HoldingSourceScope는 첫 4,000자에서 당사는 지주회사로서 등의 직접 자기서술만 확인한다. 지주회사로부터 배당, 피투자회사의 전환, 지주회사의 자회사, 자회사 전환 같은 문장은 해당하지 않는다. 따라서 generic KSIC649 전체를 지주회사로 간주하지 않는다. 실제 동국홀딩스 원문은 직접 선언이 있어 자회사 점유율을 모회사 verified 사실에서 제외했다. 실제 public API 대주 경쟁사 legacy7 및 동국 자회사 parent3이 모두 제외됨을 확인했으며 원문은 그대로 저장되어 있다.

최종 시장점유율 source replay: 15,261문서에 currentparser 관측 2,021개, holding 범위 208개, 숫자행-연도머리글 오류 복구 후보 15개. market-share-current-parser-proofs.json에 parser SHA와 각 원문행·값·기간을 보존했다. refresh 전 API 947시장점유율 사실 중 902가 currentparser exact row/value/holding scope와 일치, 45는 7회사에서 미일치했다. 미일치는 지원하지 않는 상대기업 표·옛 기준·holding 등도 포함하므로 전부 수치 오류로 단정하지 않는다. 실제 결과 비교는 최종 refresh 후 확정한다.

R&D 최종 안전성: 연결 매출→별도 매출 우선순위를 명시하고 분모마다 후보 합계를 검산한다. 같은 분모에서 다른 합계 두 개가 인쇄 반올림 허용오차에 함께 맞으면 해당 연도를 제외하며 동액 후보만 dedup한다. 같은 최신 재무보고서·기준의 Revenue가 두 손익계산서에서 다르면 임의 첫 값을 고르지 않는다. 연결 매출이 모호할 때 별도로 우회하지 않는다. 마지막 16회사 public R&D API 모두 정상, 수정 전후 관측 값 변화 0회사. 최종 관련 테스트 28개 통과 및 analyzer 문제 없음. 소스 동결.

최종 캡처 대기 준비(소스 동결 후): before25·oldOrders10,821·marketShare947 기준을 보존했다. 새 숫자 감사는 각각의 after API carry-forward와 명확한 시장 scope 실패 10건 제외, 정상시장 narrow recovery15 원문 후보를 비교해 한 파일에 남긴다. 수주 parser source-row proof는 /tmp Dart 스크립트와 workspace package_config로 496문서에서 다시 생성하여 lib/test 수정과 runtime 변경 없이 최신 parser SHA로 고정했다. 숫자 lexical support와 source column/period/issuer proof는 계속 분리한다. 최종 캡처가 완료될 때까지 after 결과를 권위 있는 완료 결과로 발표하지 않는다.

현재 이름 파서의 미매칭 35건 원문 재분류: 동국제강 own 제품 4건은 표 아래의 당사 매출수량 비율 설명이 명시되므로 현재 flat parser 미지원만으로 제외하면 안 된다. 실제 doc538/7672 표/각주 fixture로 테스트했고 table-local own 제품 제목 또는 매출수량 비율 설명이 있는 기존 사실을 보존하도록 좁게 수정했다. public API에서 정상 ids353332/353333/299923/299925(12,12,14,12)를 모두 유지했으며 대주 경쟁사7 및 동국holding자회사3 제외는 유지했다. 나머지 한솔3은 회사명 자체가 원문에 일치하는 제N기 table, 이녹스3은 당사 부문별제품 title, 대상3은 DAESANG VIETNAM 명시 상대회사 범위다. 동국holding4와 NICE18은 지주/관련사업 원문범위 정책상 raw-only이며 숫자 오류라 부르지 않는다. 현재 회사명/KSIC만으로 과거 발행 주체와 지주 여부를 100% 입증하지 않는다. market-share-remaining35-source-classification.json에 35건을 각 factId별로 기록했다. 추가 숫자 오류 건수는 0으로 분리한다. 소스 재동결.
