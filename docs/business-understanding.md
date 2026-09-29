# 기업의 사업을 이해하는 공통 구조

사용자 요청(2026-09-29): 탐방 준비 중 제품·매출·공정 위치를 이해하지 못해 AI와 다른 서비스로 이동했다. 기가비스 한 곳에 문구를 넣는 대응이 아니라 반복 가능한 시스템이 필요하다.

## 데이터 흐름

`BusinessDocument → BusinessProductRules → BusinessProfile → disclosure.understanding → BusinessGuidePanel`

- 회사 코드·이름에 따른 분기 없이 모든 기업이 같은 계약을 사용한다.
- 제품 귀속은 해당 회사 공시의 주요 제품 절/제품 열에서 확인한다. 공정·용도·고객 효용은 제품군별 공통 설명 사전과 연결한다. 회사 제품 근거(evidence)와 일반 원리(referenceUrl)는 별도 필드다.
- 신규 본문 수집 시 저장하고, 서버 시작 시 미처리/이전 규칙 문서를 보완한다. 같은 문서는 잠금 후 upsert하여 중복 실행을 직렬화한다.
- 제품 사전 버전과 PeerRules 버전을 결합해 저장 결과를 무효화한다. 공시 정정, 최신 문서, 상장 상태, 지주회사 제외는 기존 활성 문서 선택과 일치시킨다.
- 조회는 저장 결과만 읽는다. 요청 중 AI/외부 검색/추출/쓰기 없음. 비용 있는 AI 배치와 사람 검수 대기열을 만들지 않는다.
- no_document, pending, stale, unsupported, ready와 네트워크 실패를 구별한다. 공정 설명이 없는 제품은 source_only로 제품명과 공시 근거만 표시한다.
- 기존 API 공개 조회/관리자 변경 경계는 변경하지 않았다.

## 현재 설명 사전과 한계

설명 사전은 기판 AOI/VRS/AOR, MLCC, 반도체 패키지기판을 지원한다. 검사장비는 제품 소제목과 바로 뒤의 작동 설명(기판/회로형성/검사, 영상/확인, 쇼트·돌기/수리)이 함께 있어야 연결한다. 경쟁사·개발 예정·자회사 등의 문구는 제외한다. 일반 제품은 기존 제품 열 분류를 이용한다.

모든 기업의 공정을 설명하는 시스템이 완성된 것은 아니다. 회사별 고객명·성능·양산 채택·성장성·신규시장 매출을 일반 원리에서 유추하지 않는다. WLP/PLP/유리기판의 기업별 사업화 단계는 이번 사전의 범위 밖이다. 신규 제품군은 출처가 있는 원리, 회사 귀속 조건, 오인 방지 음성 사례를 추가한 뒤 버전을 올리고 범위를 다시 측정한다.

### 확인한 일반 원리 자료 (2026-09-29)

- [기가비스 AOI](https://gigavis.com/kr/product/aoi/contents)
- [기가비스 VRS](https://www.gigavis.com/kr/product/vrs/contents)
- [기가비스 AOR](https://www.gigavis.com/kr/product/aor/contents)
- [삼성전기 MLCC](https://www.samsungsem.com/kr/product/passive-component/mlcc.do)
- [삼성전기 패키지기판](https://www.samsungsem.com/kr/product/substrate/package-substrate.do)

위 자료는 제품 원리의 참고 자료다. 다른 기업의 설명에 연결되어도 해당 참고 기업의 고객·성능·매출을 다른 기업에 귀속시키지 않는다. 화면의 사진 링크도 일반 제품 참고 링크다.

## 매출 연결

`RevenueComposition`은 기존 검증된 `DocumentFact.segmentRevenue`를 읽는다. 최신 기준연도와 동일 문서만 고르고, 원문 첫 금액이 저장 값과 같을 때만 그 옆에 인쇄된 비중을 표시한다. 병합된 분류 셀을 포함한 원문 이름을 유지해 ‘제품매출 · AOI’가 드러난다. 원본 fact나 원문의 금액 단위를 변경하지 않는다. 부분 추출·중복 부문 가능성이 있어 부문을 합산해 총매출로 간주하지 않는다. 재무 기준 선택과 사업보고서 부문 기준은 구분한다.

이 방식은 기존 추출의 연도/대상 정확성을 재보증하지 않는다. 원문 비중의 재표시와 과거 숫자/다른 문서 혼합 방지가 검증 범위다. 미수집/실패/빈 값은 0 매출과 구분한다.

## 범위 감사

서버 패키지의 `tool/business/coverage.sql`에 현재 `BusinessProductRules.version`을 넘긴다. 읽기 전용이며 최신 활성·최근 3개 사업연도·상장사·비지주회사 조건이다.

2026-09-29 규칙 20007: 대상 문서 2,651, 현재 프로필 2,651, 제품명 연결 907개사, 설명 연결 2개사(기가비스·삼성전기), 원문에 존재하지 않는 근거 0건. 이는 커버리지·문자열 일치 검사이며 전수 의미 정확도 점수가 아니다.

## 검증 / 적용 상태

- 새 테이블 `business_profile`만 추가하는 migration. 기존 데이터 파괴 없음.
- 서버 규칙/생성/DB 수명주기/비교 회귀 23개 통과. 보완 실행은 작업 기록 참조.
- Flutter 매출 표시/320·1280px 카드/근거 펼치기/디자인 경계 6개 통과.
- 전체 dart analyze, git diff --check 통과.
- 로컬 화면 및 API 반영. 공개 웹 번들은 별도 배포하지 않음. 기존 미배포 변경이 함께 있어 공개 범위를 혼동하지 않는다.

최종 후속 검증: 공시 수집/예약 회귀 20개 추가 통과(서버 합계 43, Flutter 6). 실제 Chrome 데스크톱 AOI/VRS/AOR 선택·근거 펼치기, 390px 모바일 AOR 선택·매출 행 줄바꿈, 삼성전기 MLCC→카메라 모듈 미지원 전환 확인. DTD 연결/get_health 성공; driver tap은 응답 timeout이었지만 브라우저 상태에서 선택 변경을 확인했고 나머지 상호작용은 CUA로 검증했다. 뷰포트 변경 직후 Flutter 캔버스 배율이 어긋나 모바일 크기에서 새로고침 후 정상 배율을 확인했고, 검증 후 뷰포트 override를 해제했다. 최종 MCP 서버/Flutter 로그에 이번 변경의 실행 오류 없음.

## 2026-09-29: explanation rejected and revised

The user rejected the initial product chips and two-line circuit drawing as not helping them understand. Previous passing technical checks do **not** constitute successful explanation or usability validation.

Replaced that drawing with a product-family lesson: physical object (official FC-BGA cutaway), manufacturing location (substrate circuit formation before chip assembly), and observed defect/repair (official before/after pattern images). The lesson is selected by stored substrate AOI product evidence, never a corpCode. Company attribution stays in the stored filing profile; common technical explanation and credited manufacturer examples stay separate. Source-only products remain explicitly incomplete.

System acceptance criterion: the reader can explain what physical object the customer handles, where the equipment enters its workflow, what visible problem it addresses, and why the customer pays. A glossary match or more extracted product names is not success. Additional product families need comparable explanatory evidence; do not substitute the substrate story into unrelated businesses. This is one revised family lesson, not an automated explanation solution for all companies. User comprehension remains unvalidated.

Local frontend only: no new ingestion, model migration, publication or AI extraction in this revision. The official images used in this revision were subsequently removed; see the rights and diagram update below. Flutter tests cover lesson navigation and image loading at 320/1280 widths, existing revenue/provenance behavior, and design boundaries.


## 2026-09-29: labels and media rights

User found the revised explanation much improved, requested leader lines identifying IC and other parts, and raised third-party image rights. Replaced embedded Samsung and GigaVis images with original Flutter vector schematics; removed copied assets and their bundle registration. Manufacturer pages remain reference links. No permission to republish their images has been established; attribution alone was not a sufficient basis to assume permission.

`PackageStructureDiagram` uses independently laid-out schematic geometry and actual text labels connected by red leader lines: IC (integrated circuit), package substrate/copper routing, solder balls, motherboard. It is explicitly a conceptual connection diagram, not an actual layer stack or scale drawing. The repair diagram is likewise illustrative, not measured evidence; actual manufacturer photos open at the source.

For future product-family lessons: explain unfamiliar abbreviations at their point of use; connect labels to exact objects; distinguish original conceptual diagrams from actual evidence images; require recorded permission or an applicable licence for bundled third-party images. Referencing technical facts does not authorize copying a source illustration, and merely tracing or restyling an existing image is not the intended original-diagram workflow.

## Overview / financial tab responsibility

User approved removing both the financial trend-chart block and the subsequent one-line annual revenue/operating-income summary from overview. Overview focuses on business, products and revenue composition; annual totals, basis labels, trends, collection coverage and statements belong in the financial tab. Price history remains on overview.

## Final overview layout (2026-09-29)

- Four question-led sections share one column: products/use, revenue composition, price history, company information. Section gaps are 24px, heading-to-card gaps 12px, and card padding 16px. Company information is always visible; only change history can collapse.
- Revenue rows show compact amounts/shares and filing-supported names for FA, software, after-sales services and rental. Rule version 30007 keeps exact filing evidence internally. These support categories do not inherit the AOI process explanation.
- Removed the filing-evidence accordion, redundant business-source button, bottom ontology/industry comparison cards, and the first lesson's Samsung reference link and separate FC-BGA paragraph. The second lesson uses a numbered manufacturing flow.
- Header valuation/profitability metrics show matching industry medians when the financial basis agrees. Labels explicitly say median; these are not handpicked direct competitors or arithmetic averages.
- Pre-commit validation: 235 server tests and 110 Flutter tests passed. Local changes are not a public deployment.
