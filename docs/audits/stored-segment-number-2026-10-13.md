# 저장된 부문 매출 쉼표 문법 재검증

`segment_revenue.dart`와 `production_facts.dart`의 scalar·결합칸·퍼센트·원문 비율 분자/분모는 shared `literalTableNumber` 엄격 문법을 사용한다. 쉼표 3자리 묶음이 아닌 셀을 단순 제거해 숫자로 승격하지 않는다. 새 원천 추출에서는 malformed 숫자를 제외하고 원문을 유지한다.

기존 malformed candidate 6개는 저장 원문과 동일 연도 합계·비중으로 별도 확인했다. 원풍 fact311982의 8,763,517,741원은 잘못됐다. 원문 `87,635,177,41`은 마지막 자리 형식이 깨졌고 단일 100% 행만으로 자기검산되어, 저장 financial/summary 2025 annual revenue 87,635,177,741원과 10배 차이가 난다. 기존 fact 값을 다른 금액으로 덮어 쓰지 않는다.

나머지 5개는 숫자 자체는 맞다. 유진기업 식음료 218/24,203=0.9007%, 주연테크 PC 34,915,712/66,667,584=52.3728%, 테고사이언스 3차원모델 144,714,095/8,299,613,165=1.7436%, 스마트레이더 산업 1,712,180/9,397,297=18.2199%, 리센스 소모품 2,774,032/8,828,611=31.4209%로 인쇄 비중과 맞고 각 해당기간의 타행 포함 합계도 정확히 닫힌다. 3개 trailing comma, 2개 중간 쉼표 누락이다. 원문 오류를 지우거나 신규 정상 숫자로 저장하지 않는다.

`StoredSegmentNumberGuard.isCandidate(fact)`는 `segmentRevenue`이며 `extractedBy: api`인 기존 값 중 source malformed digit sequence가 저장 값과 일치하는 후보만 선택한다. `assess(fact, doc, report, financialRevenues:)`는 문서·보고서·회사·연도·활성 접수번호를 검증하고, scratch copy에서 같은 숫자 자리만 정규화해 최신 인쇄기간·단위·라벨·비중을 재검산한다. 원문 여러 행의 합과 독립 합계가 닫히는 5개는 기존 값 그대로 유지한다. 단일 100% 행은 독립 분모가 없어 연결/별도 기준과 동일 접수번호·연도·보고서 종류의 active financial revenue가 있어야 통과하며, 모호하면 원문 전용으로 남긴다. API/AI/manual 과거 검수 값을 일괄 변경하지 않는다.

호출부는 candidate 회사/연도/보고서/범위만 scoped financial query를 수행하고 레코드 목록을 전달할 수 있다. 5 closed-source 사례는 SQL 참조 없이 결정한다. source malformed 의심 값 외 전체 사실을 다시 읽거나 DB를 수정하지 않는다. endpoint 통합은 parent 담당이다.

검증: 생산/부문/인쇄기간/단위 경계 suite 45 tests pass, 실제 6 저장 원문 및 receipt/year/basis guard+scalar poison suite 11 tests pass. Targeted analyze clean, format 완료. 공개 API 실제 통합 6사는 parent가 원풍 1 제외·유효 5 유지 및 HTTP200을 확인했다(`tmp/business-universe-audit-2026-10-13/segment-public-integration.json`).
