# GA·오건 고정 공식 원문 재검증

기준 fbac28a1. 운영897 읽기 스냅샷에서 두 접수 모두 CFS failed/OFS failed, public attempt=3이다. 따라서 새 발행인 proof만 추가해 일반 HTTP 재시도하는 방식으로는 수집되지 않는다. 기존 compiled immutable cache replay에 각 OFS 한 항목을 추가했다. 47→49항목이며 CFS는 등록하거나 숫자로 재사용하지 않았다.

- 오건: 01085442 / 20230714000217 / FY2022.12 / OFS. 실제 보고서 이름은 [기재정정]사업보고서 (2022.12). 과거 인쇄 법인명 주식회사휴벡셀.
- GA: 00321204 / 20240319000287 / FY2023.12 / OFS. 당시 인쇄 법인명 관악산업주식회사.

각 패키지는 실제 shell·표지·OFS 3개 원문과 1개 manifest이다. 원형 바이트 SHA 및 manifest digest를 모두 고정하고, unique corp/원접수/6좌표/표지 실제기간/4개 재무표 발행인·whole7·BSCE를 정상 parser로 재검증한다. 금액은 기존 fixture의 7개 직접 인쇄값 그대로이며 선택 CAPEX 총행은 없다. manifest와 각 원문 변조를 거부한다.

기존 4문서 패키지 및 SPAC에는 공식 회사개요 선언이 필수다. 신규 primary-caption proof가 개요를 건너뛰어 기존 계약을 바꾸는 회귀를 막기 위해 fetchAnnual의 새 모드는 기본 false이고, 신규 두 패키지의 정확 ruleVersion만 opt-in한다. 기존 requiresIssuerOverview/요청수/documentCount/전체 원문 SHA 검증을 삭제하거나 완화하지 않았다. 감사첨부 경로도 유지했다.

정상 queue는 기존 한번뿐인 cache audit reference와 transaction/store를 사용한다. public attempt3·일반 attempts·API 예산·일반 ordering/limit/circuit/cancel guard를 변경하지 않았다. OFS 저장 후에도 CFS failed는 그대로이므로 해당 filing 전체 완료라고 주장하지 않는다. 기존 반대 기준 Source/report/facts JSON 보존 테스트 및 실제 both-failed→OFSstored/CFSfailed 재실행 불변 테스트를 작성했다.

검증: 신규2와 기존 ITcen/Redwoods/SPAC2 포함 선택 순수 회귀132 PASS. 실제 3문서만 사용하는 양성/변조/identity rejection 포함. DB 회귀는 슬롯 제약으로 작성·정적 분석만 했으며 실행하지 않았다. API/GET/운영 쓰기0.
