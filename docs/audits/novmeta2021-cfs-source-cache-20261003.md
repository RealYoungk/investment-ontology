# 노브메타파마 FY2021 연결 직접 원문 패키지

접수 `20220318000715`, 회사 `01065785`, 연결 기준, 사업연도 `2021.01.01~2021.12.31`. 기존 rare54 corpus의 정확 shell/cover/CFS 원문 3개를 바이트 그대로 보존했다. shell owncorp와 표지 당시 회사명·기수·기간, 고유 CFS viewer `dcm8477481/eleId19/offset424663/length55601/dart3.xsd`를 검증했다. source별 URL/SHA 및 manifest SHA를 compiled registry 1개에 고정한다. Source는 실제 CFS URI이며 다른 접수·별도 기준으로 재사용하지 않는다.

| 직접 계정 | 당기 원 |
|---|---:|
|자산 총계|8,348,217,667|
|부채 총계|8,810,811,187|
|자본 총계|-462,593,520|
|매출액|74,484,000|
|영업손실|-6,900,304,702|
|당기순손실|-7,516,838,106|
|영업활동으로부터의 순현금유출|-4,521,510,709|
|유형자산의 취득|-57,441,932|

손익표의 전체 순손실은 독립 CE 전체 총계열 `(7,516,838,106)`과 일치한다. 바로 옆 부모 `(7,057,722,395)`와 비지배 `(459,115,711)`는 별도 열이며 그 값을 전체로 대체하지 않았다. CE 기말 전체 자본 `(462,593,520)`은 BS와 일치한다. 기존 기본 파서가 실제 8개 직접 행을 읽는다. 새로운 문법이나 숫자 계산·변환 규칙을 추가하지 않았다. 모든 accountId는 null이며 인쇄 계정명을 유지한다.

단위 12 PASS: 실제8/전체CE/BS identity, 각 원문·manifest SHA 변조, wrongcorp/year/type/receipt/period/currentname 및 OFS 기준 재사용 거부. 정적 분석 0건, 포맷 통과.

정상 큐 DB1 PASS: 실제 both-failed fixture에서 CFS8만 저장, Source/current period/audit/public summary 직접값 일치, OFS failed 유지 및 coverage 미완료1, API0·publicattempt3/일반 시도7 유지. 재실행 추가 읽기·중복 Source/report/facts·장부 변경 없음. 첫 실행의 coverage 인증 예외는 관리자 전용 호출을 정상 asAdmin fixture로 수정하여 해결했다. auth 가드는 바꾸지 않았다. 로그 `/private/tmp/io-novmeta21-cfs-db.log`, teardown 완료·DB 슬롯 반환.

별도 원문 매출 대시·부분6 미지원은 그대로다. 이 연결8 복구는 해당 filing 양쪽 기준의 전체 완료가 아니다. 기존 전체 registry 정상 큐 harness는 반대 기준 Source/report/facts 보존 회귀를 이 신규 entry에도 적용한다. 본 문서는 운영 저장 완료 주장이 아니다. 신규 GET/API/운영 변경/Sync 수정/시도 초기화 없음.
