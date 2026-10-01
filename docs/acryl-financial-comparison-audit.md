# 아크릴 재무 지표 누락 진단 — 2026-10-01

## 확인한 원인

- corpCode 01829819, 종목 0007C0. 사업보고서 원문에서 상장일 2025-12-16 확인.
- 로컬 financial.summary 연결/별도 모두 2025 annual, 2026 q1/halfYear 3기간 존재, pendingFilingCount=0.
- 최신 반기 원천 fact에는 전년 동기 비교열이 이미 저장되어 있다. summary DTO는 이를 전달하지 않았고 Flutter TTM 및 서버 공통 FinancialBasis SQL은 별도 전년 동기 보고서만 참조했다.
- 별도 전년 동기 공시가 없는 신규 상장사에도 최신 공시 비교열로 TTM을 계산할 수 있으나 자료 부족으로 표시되던 결함.

## 수정

- FinancialLine DTO에 priorSameCumulativeAmount와 priorSameUnavailableReason 추가. 모델 YAML 변경 후 running watcher가 서버/클라이언트 자동 생성. 테이블 변경/마이그레이션 없음.
- FinancialComparatives: 손익은 priorCumulativeAmount, Q1만 priorQuarterAmount 보완 가능. 현금흐름은 priorQuarterAmount가 누적. annual/BS에는 동기 비교값을 만들지 않는다.
- own-period 보고서 우선, 그 값 미확보 시 같은 기준의 최신 공시 비교열. 가상의 과거 보고서/저장값을 생성하지 않는다. 통화 혼합/취득액 부호 정규화 유지.
- 기업 화면 TTM/추이와 서버 FinancialBasis 공통 SQL에 반영. 입력 근거에 비교열의 실제 접수번호 표시.
- 아크릴 원천 지배주주 전년 누적은 0이지만 전체 순이익 -2,715,804,289원, 비지배주주 0원으로 합계 불일치. 같은 재무제표·통화의 유일한 전체/비지배 순이익 행으로 대조, 불일치한 지배주주 비교열만 차단. 원천 fact는 보존. 기존 연결 전체 순이익 fallback 동작 유지.

## 실제 확인

2026 반기 말 TTM 연결 매출 = 13,312,020,352 + 12,047,351,414 - 4,827,787,392 = 20,531,584,374원.
시세는 2026-09-29 기준, 시총 147,597,355,120원. 실제 IAB 아크릴 화면:
PSR 7.19배, 영업이익률 -11.6%, FCF 수익률 -5.0%, ROA -4.4%, ROE -5.5%, 영업현금흐름률 -22.1%, 설비투자/매출 13.6%, 잉여현금흐름 -73억.
PER은 실제 적자 때문에 계산 불가로 표시. 성장률에는 전년 동시점 TTM이 더 필요하므로 미확보 유지. EBITDA/EV 입력 누락과 별도 항목 매핑 전체 해결을 주장하지 않는다.

## 검증과 한계

- 서버 integration financial_basis + unit financial_accounts + generated_code_test 28개 통과.
- Flutter financial_metrics + financial_basis_widget 31개 통과.
- 서버 전체 dart analyze 정상. Flutter 전체 analyze 오류 없음, 기존 다른 작업 ownership_snapshot.dart curly-brace info 1건. 변경 파일 analyze 정상.
- MCP hot_restart/hot_reload 완료. 최신 Flutter 로그 끝은 restart 성공; 로그에 과거 작업 컴파일 실패도 남아 있으므로 전체 로그 무오류로 주장하지 않는다.
- DTD 연결/health 정상. driver 전체지표 tap은 timeout; 실제 IAB AX에서는 펼침 결과 확인, PSR 근거 창도 클릭·검증.
- outputs/acryl-financial-audit/: 수정 전 summary 3개, 최신 반기 원천, 실제 지표/PSR 출처 화면.
- 운영 배포/DB 변경 없음. 전 기업 전수 의미 검증 아님.
- 참고 원문: https://kind.krx.co.kr/external/2026/03/18/002198/20260318010268/11011.htm

## 후속 공통 로직 및 현금 점검

- 2026 반기 연결 현금및현금성자산 3,364,253,367원, 단기금융상품 31,053,198,747원, 합계 34,417,452,114원. 현금흐름표 단기금융상품 취득 31,000,554,231원. 원문 반기 접수번호 20260814003765. 금융상품의 만기·사용제한을 합계의 즉시 가용성으로 해석하지 않는다.
- 표준 XBRL 단기금융상품 계정만 추가하고 현금과 구분. 동일 최근 기말·통화의 두 항목이 확보될 때 합계 표시, 미확보를 0 처리하지 않음. 헤더 기준일 표시. EV는 좁은 현금 기준 유지. 실제 헤더가 profile.select를 우회하던 부분도 브라우저 확인 후 수정.
- 현재 연간 공시가 있으면 과거 통화 차이보다 해당 연간 값을 우선. 비교열 전체/지배/비지배 항목은 같은 보고서·통화·유일 행으로 검증.
- 2,759개 기업, 연결/별도 4,912개 및 자동 선택 포함 7,671개 응답. canonical 보고서 110,969개, 선택 원천 행 1,155,036개, 비교열 443,157개 대조 불일치 0. 불일치 비교열 377건은 차단 여부 확인(기업 수 아님).
- 독립 Decimal 계산 191,775건 불일치 0, 자동 기준 선택 오류 0. 서버 SQL TTM 26,031건 대조 불일치 0(유형자산 취득 부호 정규화 반영). 이는 수집된 계정 선택·산술 대조이며 모든 공시 본문 의미 해석의 보장이 아님.
- 재시작 후 서버 회귀/등록 테스트 30개, Flutter 계산 테스트 37개 통과. 헤더 후속 수정 정적 분석 오류 없음.
- 재현 도구 scripts/audit/collect_financial_followup.py, verify_financial_followup_sources.py, verify_financial_followup_arithmetic.py, export_local_readonly.py. 대용량 스냅샷 outputs/financial-followup-2026-10-01/는 gitignore.
- 운영 배포 및 DB 변경 없음.

- 후속 실제 IAB 화면 검증 완료: 헤더 현금·단기금융상품 344억 / 2026 반기 기말. 클릭 입력값 33.6억원 + 310.5억원과 동일 접수번호 확인. 증거 cash-header-fixed.png / cash-components-fixed.png. 기존 탭 CDP 연결이 멈춰 별도 임시 검증 탭 사용 후 닫음.
