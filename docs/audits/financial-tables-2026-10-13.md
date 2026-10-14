# 금융업 명시 표 구조화 (2026-10-13)

저장된 `tmp/business-50-audit/capture/corpus.jsonl`만 사용했다. 원문 재수집, AI 호출, 수동 사실 제출, DB 변경은 하지 않았다.

`FinancialBusinessSourceTables.parse(text, reportPeriod)`는 새 topic `financialBusiness`를 반환한다. 기존 제품매출과 분리하며 명시 금융 지표명, 원문 단위, 기간 열, 문서 내 범위를 유지한다. 합계가 단순히 검산 가능한 부문 표 및 준비금 표는 합계 검산 결과를 validation에 표시한다. 불일치는 값을 바꾸지 않고 표시한다. 표시 반올림 허용치는 합산 행 수(원문 단위)다. 범위/회계기준은 원문 context와 주석을 scope에 보존한다.

확인 근거:

- 삼성생명 20260814003263: 준비금평잔 합계 267,802,310 백만원, 부리이율 4.10%, 비중 100.00%; `제 71 기 반기(FY2026 2Q)` 열. 준비금은 보험료나 매출로 변환하지 않는다.
- 삼성화재 202608 반기 저장문서: 일반손해보험 화재 보험수익 33,578 백만원. 보험서비스비용·재보험수익·재보험서비스비용 열을 별개 metric으로 유지한다.
- 미래에셋증권 저장 반기 문서: 영업수익 합계 36,060,098 백만원, 영업비용 합계 (32,195,185) 백만원. 괄호 음수를 보존하고 조정을 포함한 합계 검산을 표시한다.

한계: `금액|비율`만 있는 운용내역별 표의 비율은 수익률인지 비중인지 표 행에 따라 다르므로 이번 파서는 미지원으로 남긴다. 기간 없는 부문 테이블은 보고기간과 함께 `표 내 기간 미특정`을 표시한다. 이 반환값은 저장되지 않으며 부모 에이전트의 read API 등록이 필요하다. 전수 corpus는 이 문서 작성 시 아직 준비되지 않았다.

검증: targeted dart analyze 이상 없음; dart format; 실제 저장문서 fixture 3개와 회귀 테스트 5개 통과(준비금, 보험수익/서비스비용, signed 영업비용, 미명시 비율 거부, 단위 누락 거부).

## 전수 저장원문 replay 후 수정

`tmp/business-universe-audit-2026-10-13/capture/corpus.jsonl` 현재 DB read-only export 15,261건 전부 replay했다. 금융 업종코드 64/65/66 문서는 1,064건(222사), 이 중 명시 지원표를 반환한 문서 324건, 표 1,166개, 측정치 11,331개다. 나머지 740건은 이번 지원 패턴 미검출이며, 미공시나 원문 부재로 단정하지 않는다. 저장원문은 존재한다.

전수 invariant: evidence가 원문 substring, row.cells 수 == columns 수, metric/period 비어있지 않음, 유한 숫자, 명시 단위(원/천원/백만원/억원/%) 전부 통과. 2단 헤더는 `범위·종류 + 기간×지표`로 펼치고 merged label을 1열로 합쳐 ragged rows를 없앴다. evidence는 원문 그대로다. 단위 window는 새 `##` 절이나 다른 표를 넘어가지 않는다. 이 경계와 비금융 업종 거부 회귀도 추가해 전체 8개 tests 통과했다.

실제 counterexample: 업종 없는 문맥 키워드 fallback이 KG케미칼 등 비금융 문서 151건을 허용했다. KG케미칼 document 3490/800/5609/8686에 금융종속회사 이자수익·유가증권처분이익·채권처분이익 표가 섞여 있으며, 모회사 업종은 201이다. 연결 문서에 금융종속회사 표가 존재하는 것과 모회사의 금융업 표를 동일시할 수 없어 업종코드 없는 호출을 fail-closed로 바꾸었다. 최종 호출은 `parse(text, reportPeriod, industryCode: company.industryCode)`이며 비금융/코드누락 출력은 0이다. 금융종속회사 별도 식별은 이 파서의 미지원 범위다.

최종 targeted analyze 이상 없음, format 적용. 외부 조회/재수집/DB 변경 없음.

전체 corpus replay는 unit test에서 제거했다. unit test는 3개 소형 fixture로 동일 invariant를 검증한다. 명시적으로 전수 audit를 실행하려면 서버 패키지에서 아래 명령을 사용한다. JSONL을 stream으로 읽으며 실패는 exit 1과 문서 ID로 표시한다.

```sh
dart run tool/business_tables/audit_financial_sources.dart ../tmp/business-universe-audit-2026-10-13/capture/corpus.jsonl
```

## 쉼표 숫자 문법 교정

UI 전수 검증에서 병합 셀 문자열이 큰 수로 파싱되는 결함을 발견했다. 금융 helper도 쉼표를 먼저 지우므로 상상인증권 `11,04` → 1104 / `24,03` → 2403을 허용했다. 이제 숫자는 무쉼표 정수 또는 정확한 세 자리 천단위 쉼표 그룹과 소수부만 허용하며, 괄호 음수와 △ 부호를 보존한다. 잘못 병합된 값은 measure에서 제외하되 source rows/evidence는 그대로 유지한다.

9개 targeted tests pass, analyze 이상 없음. 실제 전수 금융 replay: 15,261문서, 1,166표, 11,329측정치, failures0. 교정 전 11,331에서 잘못된 2측정치만 제외됐다.

전체 기존 API snapshot의 숫자문법 진단은 19사 30측정치를 확정했다(단순 trailing punctuation comma 및 다른 정상 원문 숫자와 우연히 같은 값인 후보는 제외). `api-capture/numeric-before-*`에 이전 오류 증거를 보존했다. 숫자 토큰의 쉼표 문법도 검증하며, 원문값 단순 존재 검증을 셀 의미/회계 검산 전체 확인이라고 주장하지 않는다.
