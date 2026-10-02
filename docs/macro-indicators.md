# 시장 지표 — 2026-10-02

사용자 요청: 원유 등 매크로 지표를 추가하고, 인베스팅닷컴의 비교 정보 구성과 토스증권의 읽기 쉬운 지표→차트 흐름을 참고한다. 지표의 방향을 매매 신호로 단정하지 않고 기업의 원가·수요·금융환경에 전달되는 메커니즘과 확인할 공시 항목을 보여준다.

## 구현

- 시장(`/market`)에 6종 지표 요약과 상세 진입을 추가했다.
- `/market/indicators?series=DCOILBRENTEU&days=365`에서 지표·기간을 URL에 유지한다. 기간은 30/90/365/1095일이다.
- 넓은 화면은 지표 목록과 차트를 나란히, 850px 미만은 선택 메뉴→차트→해석 순서로 표시한다. 전체 비교 목록은 펼침으로 제공한다.
- 기업 개요에서 `company=corpCode`를 전달한다. 지표 선택·기간 변경에도 이 값을 유지하며, 해당 기업의 사업 정보(개요)·재무 탭으로 돌아갈 수 있다. 이 링크는 실제 경제적 노출이 확인됐다는 의미가 아니다.
- 상승/하락의 조건부 설명, 전달 경로, 기업 공시에서 확인할 항목, 원자료 링크·수신 시각·관측일·계산식·비교 기준값을 제공한다.

## 데이터

Serverpod `macro.overview`의 공개 조회 API. 외부 URL이나 지표 ID를 요청에서 받지 않으며 공유 DB/계정 데이터를 변경하지 않는다. EIA/연준 자료의 공식 FRED CSV 배포를 이용한다. 각 시계열에 기존 `Source` 타입의 출처를 포함한다. Source와 관측값은 첫 버전에서 서버 메모리 캐시에만 있으며 DB 사실로 저장하지 않는다. 따라서 DB 마이그레이션은 없다.

| 지표 | 시계열 | 원천·기준 |
|---|---|---|
| 브렌트 | DCOILBRENTEU | EIA 유럽 브렌트 현물, 달러/배럴 |
| WTI | DCOILWTICO | EIA Cushing 현물, 달러/배럴 |
| 원/달러 | DEXKOUS | 연준 H.10 뉴욕 정오 매입환율, 원/달러 |
| 광의 달러 지수 | DTWEXBGS | 연준 H.10 무역가중 명목 지수, 2006-01=100 |
| 미국 국채 2년 | DGS2 | 연준 H.15 고정만기 시장수익률, % |
| 미국 국채 10년 | DGS10 | 연준 H.15 고정만기 시장수익률, % |

6종 모두 FRED 원자료 페이지의 `Public Domain: Citation Requested` 표시를 확인했다. 페이지는 `https://fred.stlouisfed.org/series/<시계열>`이며 화면에 원천 기관과 FRED를 함께 표기한다. VIX/ICE DXY/구리/금 등의 상용 지표는 배포 권리와 데이터 원천을 확인한 뒤 확장할 항목이다. 연준 광의 달러 지수를 ICE DXY로 이름 붙이지 않는다.

캐시는 6시간, 최초 요청은 6종 병렬, 동시 요청은 합쳐 처리한다. 원천 요청은 15초 제한. 실패는 5분 뒤 재시도 가능하고 해당 시계열만 unavailable 또는 stale로 표시한다. 실패 시 기존 관측값·성공 수신 시각을 유지한다. 마지막 관측이 14일 이상 지난 경우에도 stale을 표시한다. 서버 재시작 후 첫 요청은 다시 원자료를 받는다. 예약 수집/DB 시계열 저장/실시간 호가는 이번 범위에 포함하지 않는다.

헤더의 시계열 ID, 날짜, 유한 숫자, 충돌 중복을 검증한다. HTML·잘못된 날짜·미래 관측·잘못된 숫자는 거부한다. 원유의 음수 가격은 유효한 관측일 수 있어 보존한다. 결측은 0이나 직전 값으로 채우지 않는다.

가격·환율 변화는 `(최신/기준-1)×100`, 금리는 `최신-기준` %p. 음수/0 가격 기준의 상대 변화는 자료 부족 처리. 날짜 기준은 최신 관측일에서 기간을 뺀 날짜 이전 최근 관측(7일 이내), 직전 관측도 7일 내만 사용한다. 차트는 관측일만 연결하는 범주형 차트로 실제 달력 날짜 간 간격은 균일하지 않을 수 있다.

## 설명 근거

- [EIA 원유가격 요인](https://www.eia.gov/finance/markets/crudeoil/spot_prices.php)
- [연준 공급·수요 충격과 금융시장](https://www.frbsf.org/research-and-insights/publications/economic-letter/2026/08/financial-markets-oil-prices-and-supply-side-risks/)
- [영란은행 금리 전달 경로](https://www.bankofengland.co.uk/quarterly-bulletin/2024/2024/about-a-rate-of-general-interest-how-monetary-policy-transmits)

기업별 영향은 일반 교육 설명이며 자동 판정·추천을 하지 않는다. AI 호출이나 사업 본문 수작업 추출을 실행하지 않는다.

## 검증

- 전체 `dart analyze`: No issues found.
- 서버 파서/캐시/실패·회복/동시요청/부분 실패 4 tests + 생성 등록 3 tests: 7 통과.
- Flutter 계산 3 + 로딩·재시도·빈 상태/URL·기업 맥락 유지/390px stale UI 3 + 디자인 경계 2: 8 통과.
- 실제 공개 RPC 6종 ready, 시계열당 751~764 관측. `outputs/macro-indicators-2026-10-02/live-response.json`에 공용 응답 저장.
- 실제 브라우저에서 지표·기간 선택, 모바일 선택 메뉴, 계산·출처 펼침 확인. 최종 기업 연결/시장 요약 증거는 후속 항목 참조.
- 같은 체크아웃의 결제 변경 도중 자동 생성이 membership/Billing 등록을 잠시 누락했다. 이후 자동 생성으로 복구되어 생성 등록 검사와 전체 정적 분석이 통과했다. 결제 변경은 이 작업에 포함하지 않는다.
- DTD 연결·health 정상. driver 명령은 일부 timeout이 발생해 해당 driver 실행을 통과로 집계하지 않는다. 실제 UI 검증은 브라우저와 위젯 테스트로 수행한다. 텍스트 입력 에뮬레이션은 false로 복원했다.
- 운영 배포는 수행하지 않았다.

최종 브라우저 확인: 삼성전자(00126380) 개요의 진입 버튼→시장 지표→`이 기업의 재무 확인`으로 삼성전자 재무 탭 표시를 확인했다. 시장 홈의 6종 요약 카드와 `전체 지표와 해석` 진입도 확인했다. 데스크톱/390px 화면 증거는 desktop.jpg/mobile.jpg, 시장 요약은 market.jpg. Flutter driver의 임시 frame sync와 텍스트 에뮬레이션은 각각 true/false 복원 응답을 확인했다. 최종 수정 대상 analyze와 Flutter8 tests를 다시 통과했다. Flutter watch 로그에는 여러 브라우저 연결 중 reassemble timeout이 남아 있으나 이후 새로고침에서 최종 화면을 확인했다.

## 초보자 설명 개선 (2026-10-02)

시장 요약에 지표별 한 줄 정의를 표시하고, 상세에서는 차트 앞에 ‘어떤 지표인가요?’와 ‘숫자는 이렇게 읽어요’를 항상 보여준다. 브렌트/WTI의 기준과 거래 지역, 원/달러 방향, 광의 달러 지수의 기준을 구분한다. 국채 표시명은 2년/10년 **금리**로 명시한다. 고정금리 채권 가격과 시장수익률의 반대 관계, 기존 약정 이자의 불변, 4.00→4.50%는 +0.50%p라는 가상 예시를 표시한다. 2년물과 10년물은 모두 Treasury Notes이며, 2년물을 만기 1년 이하 Treasury Bills로 설명하지 않는다.

정의 근거: [EIA의 Brent/WTI 기준 설명](https://www.eia.gov/todayinEnergy/detail.php?id=18571), [미 재무부 Treasury Notes](https://www.treasurydirect.gov/marketable-securities/treasury-notes/), [SEC의 고정금리 채권 금리 위험 설명](https://www.sec.gov/files/investor/alerts/ib_interestraterisk.pdf). EIA 설명의 북해는 브렌트의 기원으로 표현하며 현재 기준 원유 바스켓 전체가 북해산이라는 주장으로 사용하지 않는다.

추가 검증: 정의와 국채 가격/금리 구분을 포함한 Flutter 8 tests 통과, 390px 원유 화면 overflow 없음. 실행 중 Flutter 증분 컴파일러는 `app_auth.dart` library summary 누락 오류가 있어 MCP hot_restart 2회 이후에도 브라우저가 기존 화면을 제공했다. 최신 변경의 실브라우저 검증은 미완료이며 사용자 `serverpod start` 세션 재시작 후 확인이 필요하다. 서버는 에이전트가 새로 시작하지 않았다.

## 공통 요청 복구 (2026-10-02)

Flutter `ResilientClient`는 생성 클라이언트를 상속하며 인증 갱신과 직렬화를 그대로 사용한다. `ReadRetry.methods`에 명시된 조회만 네트워크/Timeout/502·503·504에서 추가 2회 재시도한다(500ms, 1500ms + 최대249ms jitter). 인증·권한·400·500·파싱/업무 예외 및 미등록/변경 요청은 자동 재시도하지 않는다. 새 읽기 엔드포인트는 검토 후 목록에 추가한다. 수동 복구는 디자인 공통 `ReadFailureNotice`를 사용하며 요청 중 비활성화한다. 시장 기존 `MarketLoadNotice`는 이를 상속하고 매크로 상세도 같은 UI를 쓴다. 전 화면의 수동 오류 UI를 이번 변경으로 모두 교체한 것은 아니다.

명시된 조회는 각 시도에 15초 제한을 두어 응답 없는 요청도 종료한다. 원래 Future는 취소되지 않으므로 서버의 읽기 처리는 계속될 수 있지만, 늦은 응답은 재시도 결과를 덮어쓰지 않는다. 변경 요청의 timeout은 기존 SDK 설정을 유지한다. 정적 분석 및 복구/화면/디자인 10 tests 통과. 실제 시장 요약 2,759개사 표시 확인.
