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

## 2026-09-29: 성호전자 적용 실험 — DB 이관 보류

사용자는 설명 콘텐츠의 DB 이관을 당장 진행하지 않고 다음 탐방 기업인 성호전자에 같은 접근을 적용하도록 요청했다. 설명 문구·자체 도식은 Flutter 코드에 둔다. 이번 변경은 DB 쓰기·스키마 변경·AI 추출·공개 배포를 포함하지 않는다.

- `PowerComponentsGuide`: 전원 보드와 콘덴서의 크기/위치 관계 → 증착형 필름콘덴서 내부 → 재료·부품·전원 모듈의 판매 관계. 빨간 지시선과 한글 라벨로 설명하며 외부 이미지는 복제하지 않는다.
- `PowerProductLesson.resolve`: 기존 저장 프로필에서 SMPS 제품이 확인되면 기존 `businessContent`를 읽는다. ready 프로필과 본문의 사업연도·접수번호가 일치하고, 주요 제품 절의 `주요 제품 매출 비중` 표에 PSU·필름콘덴서·증착필름 세 행과 100% 합계가 있을 때만 연결한다. 기업명·기업 코드 분기는 없다. 지원 범위는 이 제품 조합/표 형태로 좁으며 모든 전원장치 기업으로 확장됐다는 뜻은 아니다.
- 기존 검증 금액 매출이 없을 때 이 표의 해당 사업연도 열 비중만 표시한다. 금액은 다른 매출 총액에서 역산하지 않는다. 공시 본문 주요 제품 비중의 연결/별도 범위가 명시되지 않아 연결 전체 구성으로 표시하지 않는다. 이 클라이언트 표시용 해석은 영속 검증 사실이나 서버 추출기의 확장이 아니다.
- 일반적 제품 원리와 해당 회사의 실제 전방 매출은 구별한다. 자사 제품 간 내부 투입 비중, 전기차/ESS의 실제 매출 비중, 고객별 현황은 추정하지 않는다. 연결 자회사 전체 사업 설명이나 탐방 실사 전체를 다룬 것은 아니다.

확인 자료:
- 성호전자 2025 사업보고서, 접수번호 [20260320001361](https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260320001361). 저장된 II 본문 11,637자를 읽고 주요 제품·용도·매출 비중·별도 매출표를 대조했다. 주요 제품 비중 PSU 66.3%, 필름콘덴서 31.2%, 증착필름 2.5%; 별도 사업부 금액표와는 별개로 취급한다.
- [성호전자 공식 제품 소개](http://www.sungho.net/): 필름콘덴서·전원공급장치 사업 및 적용처. 기본 웹 fetch 실패 후 Exa fetch로 본문 확인.
- [TDK 필름콘덴서 원리](https://www.tdk.com/en/tech-mag/electronics_primer/7), [TDK 제품/용도](https://www.tdk-electronics.tdk.com/en/529492/products/product-catalog/film-capacitors): 절연 필름·금속 증착 전극, 권취/적층, 잡음 제거/평활 용도. 원리만 참고했으며 TDK 성능을 성호전자에 귀속하지 않았다.

검증: 신규 해석/반응형 테스트와 기존 기판 안내/디자인 경계 합계 12개 통과(320·1280px). 최신 연도 열 재배치, 공시 불일치, 다른 콘덴서 종류, 합계 누락·불일치 거부를 포함한다. DTD 연결 및 driver 단계 이동 성공, 로컬 성호전자 화면에서 세 단계와 실제 비중 표시 확인.

### 성호전자 도식 재작업

사용자가 첫 도식이 깨져 보이고 이해되지 않는다고 지적했다. 가로 폭에 따라 늘어나던 판/사각형과 분리된 필름 선을 폐기했다. 동일 비율의 독립 그림으로 프린터 → 전원 보드 → 표시된 콘덴서를 확대하고, 콘덴서 케이스 → 권취한 속심 → 증착필름의 재료층을 연결한다. 화살표는 전류가 아니라 확대/분해 순서다. 좁은 화면에서는 세로 순서로 바뀌며 라벨은 캔버스 바깥의 일반 텍스트로 표시한다. 두 재료층을 띄워 그린 이유도 명시한다. 이전 테스트 통과는 설명의 이해 가능성을 보장한 것이 아니었다.

### 2026-09-29: 기업별 변화와 탐방 질문

제품 설명과 매출 구성 사이에 `CompanyDevelopmentSection`을 추가했다. `CompanyDevelopment`의 기업 코드별 정적 리서치 스냅샷을 공통 UI로 표시한다. 제품군이 같다고 인수 사실을 다른 기업에 적용하지 않는다. DB 저장/자동 최신화는 하지 않으며, 지원하지 않는 기업에는 섹션을 표시하지 않는다.

성호전자 근거: 2026 반기보고서(2026-08-14 접수, `20260814003108`) II 사업의 내용 및 III 연결재무제표 주석 실제 본문을 읽었다. 주석 1은 어매이징홀딩스를 통한 ADS테크 지분 취득 및 연결 편입, 사업결합 표는 2026-02-13 취득(간주 02-01)을 기재한다. II는 광통신 모듈·칩의 조립·정렬·접합·검사 장비 및 렌즈/광섬유 정렬 장비를 설명한다. 기사별 지분율 표현은 혼재하므로 UI에서 경제적 지분율을 추정하지 않았다. 특정 고객명·CPO 양산 매출·주가 상승 원인은 확인 사실로 표시하지 않는다. 설비투자→수주→연결 매출은 조건부 실적 경로이며, CPO 사업 단계와 인수자금 비용은 탐방 질문이다. 아래 2025년 제품 비중과의 시점 차이를 명시한다. 확인일은 2026-09-29이나 내용 기준은 반기보고서이며, 이후 공시를 포괄한 실시간 분석이 아니다.

### 2026-09-30: 산업 배경과 공통 판단 기준

사용자 피드백: 광통신 인수 사실만으로는 데이터센터 배경을 모르는 독자가 이해하기 어렵다. 개인용 탐방 질문은 공통 개요에서 제외한다. 설명을 AI 분산 계산 → 광통신의 역할 → 광부품 정렬/접합/검사 장비의 3단계로 바꿨다. 별도 배경의 `핵심 판단 기준`에는 실제 주문, 양산 매출, 이익·현금 전환이라는 조건과 확인 지표를 표시한다. 확인되지 않은 ADS테크의 CPO 양산 매출은 확정적으로 표현하지 않는다.

산업 원리 참고: Broadcom의 2024-04-10 공식 설명 https://www.broadcom.com/company/news/articles/ai-infrastructure/how-to-scale-the-optical-interconnect-using-co-packaged-optics-cpo (Exa 본문 검색 추출 확인; 웹 직접 열기는 JS 셸). AI GPU 클러스터 통신, 광연결 확대, 스위치 ASIC과 광엔진의 동일 기판 집적을 참고했다. 산업 기술 설명이며 Broadcom과 ADS테크의 거래 관계 근거로 사용하지 않는다. 기업 인수 근거일은 기존 반기보고서 확인일을 유지한다.

- 2026-09-30 후속: 내용이 길다는 피드백에 따라 기본 화면은 요약 문장과 주문·양산·수익 세 줄로 압축했다. 데이터센터/CPO 배경은 접힌 설명으로 유지한다. 개인화된 탐방 질문은 복원하지 않는다.
- 2026-09-30 후속 결정: 공통 개요가 투자 판단 기준을 제시하는 것은 과하다는 사용자 피드백. 주문·양산·수익 기준과 데이터 필드를 제거했다. 질문형 섹션 제목 아래 산업 수요와 회사의 사업 연결을 짧은 투자포인트로만 표시한다. 산업 수요 증가는 가능성 표현을 유지하고, 세부 배경은 펼침으로 유지한다.
- 2026-09-30 성호전자 우선 보완: 제품 안내 첫 단계에 ADS테크 광통신 모듈·칩 제조용 정렬/접합·경화/검사 장비를 추가했다. 기존 제품군 안내에는 자동 전파하지 않고 성호전자 코드에서만 명시적으로 활성화한다. 기존 전원장치·콘덴서, 증착필름, 전자부품 고객은 2~4단계. 공통 단계 이동은 count를 받도록 확장(기본 3). 근거는 앞서 확인한 2026 반기보고서 II 및 연결주석이며 2025 제품 매출 비중에는 신규 편입 사업이 없다는 설명 유지.
- 2026-09-30: 사용자 요청으로 성호전자 설명의 반복적인 방어 문구(특정 공급/양산을 뜻하지 않음, 그림과 실물 차이, 자사 투입 아님, 매출표 해석 경고)를 제거. 제품/원리 설명과 공시 연도·출처는 유지. CPO 설명은 일반 원리만 남기며 회사 양산 실적을 새로 주장하지 않는다.
- 2026-09-30: 광통신 설명의 텍스트 공정 상자를 자체 제작 인터랙티브 송신부 개념도로 교체. 칩→렌즈→광섬유 광경로와 라벨 지시선, 위치 조정/고정/검사 단계 선택에 따른 그림·설명 변경. 외부 제품 사진은 사용하지 않으며 특정 ADS 장비 외관으로 표현하지 않는다. 로컬 넓은 화면 및 390px 단계 전환을 시각 확인했다.
- 2026-09-30: 4번 전자부품 고객 설명을 제품 그림→판매→구매자 아이콘/용도 세 행으로 교체. 증착필름→콘덴서 제조사, 콘덴서→전원장치/전자기기 제조사, PSU→완성 기기 제조사의 개별 판매 관계를 보여준다. 앞 단계의 자체 도식을 재사용했다. 넓은 화면과 390px에서 세 행과 마지막 단계 버튼을 시각 검수했다. 사용자는 설명에서 시각화를 적극적으로 활용하기를 요청했다.

### 2026-09-30: 최근 소식 — 사건 단위 시범 적용

사용자는 공시 목록보다 뉴스·공시·회사 발표를 합쳐 회사의 최근 변화를 파악하는 흐름을 요청했다. 성호전자에 `CompanyNews` 정적 사건 카탈로그와 `CompanyNewsSection` 공통 렌더러를 적용했다. 수주/납품, 자금조달, 연결 실적 3개 사건으로 묶고 요약→경과→원문 구조로 표시한다. 원문 링크는 펼친 상세에만 둔다. 지원하지 않는 기업은 기존 최근 공시를 유지한다. DB/자동 수집/자동 갱신 구현은 없으며 화면에 2026.09.30 정리 시점을 표시한다. 사건 선택은 전수 뉴스 목록이 아닌 편집된 요약이다.

확인 원문:
- https://www.nbntv.co.kr/news/articleView.html?idxno=4024035 : 회사 발표 인용 CPO 장비 PO 보도. 웹 직접 열기 실패 후 Exa fetch 본문 확인. 검색 메타는 9/26이나 기사 입력은 8/20이므로 8/20로 표시. 회사 발표를 인용한 보도로 귀속, 실현 매출로 바꾸지 않는다.
- https://www.newspim.com/news/view/20260915000080 : 9/15 기사 본문, 신한투자증권 분석의 부품 부족/납품 제약/향후 예상. 주문 부정이 아니라 후속 일정 분석으로 같은 사건에 묶었다. CB 관련 후속 분석도 동일 기사에서 확인. 숫자 전망/기업가치 목표는 표시하지 않는다.
- https://spn.stockplus.com/news/api/v1/disclosure_views/koscom/502227 : 8/31 제21회 CB 발행결정 공시 전문(미러). 130억원·채무상환 목적 확인. 발행 완료로 표현하지 않음.
- https://www.mt.co.kr/stock/2026/08/18/2026081809283784418 및 반기보고서 20260814003108: 연결 매출1512.44211억원/영업이익100.96억원의 반올림 표기, 신규 연결 편입과 기사 해석을 연결.

동일 보도자료를 인용한 기사 수를 독립 검증 횟수로 취급하지 않는다. IPO 관련 7월 보도가 검색 메타에서 9월로 잡히는 사례도 발견했으며 최근 신규 사건으로 넣지 않았다. 사용자용 개인 탐방 질문/판단 기준은 추가하지 않았다.

### 2026-09-30: 조회 시점 API로 전환

`CompanyNewsEndpoint.recent`는 인증된 화면 요청 시 네이버 뉴스 검색과 DART 최근 90일 공시 목록을 병렬 조회한다. 기업별 5분 메모리 캐시, 동일 요청 공유, 실패 시 15초 재시도 간격, 최대 256개 캐시를 사용한다. 뉴스 내용은 DB에 저장하지 않으며 예약 수집과 AI 호출도 없다. DART 호출 수만 기존 API 사용 장부에 기록한다.

정적 `CompanyNews` 카탈로그는 제거했다. 뉴스 제목·검색 요약의 HTML을 정리하고 URL 또는 48시간 이내 매우 유사한 제목을 묶는다. 다른 숫자와 정정·취소 제목은 보수적으로 분리한다. 공시와 기사를 억지로 하나의 사건으로 묶지 않는다. 분류는 제목 키워드 기반이며 주가 등락 기사는 뒤로 배치한다. 검색은 현재 기업명/종목명 기준이며 자회사명만 등장하는 기사까지 포괄하지 않는다. 검색 API 최신 100건/공시 최신 100건 중 최대 12건을 표시한다.

서버 설정: `config/passwords.yaml`의 `shared`에 `naverClientId`, `naverClientSecret`, 또는 `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET` 환경변수. 값 변경 후 Serverpod MCP 재시작. 기존 DART 키를 재사용한다. 현재 작업 환경에서 네이버 키 미설정으로 실제 뉴스 응답 검증은 미완료다. 로딩·실패·소식 없음·연결 미설정·로그인 필요를 구분하고 부분 성공 결과는 보존한다. 출처 링크와 검색 요약은 펼친 상세에 둔다.

### 2026-09-30: NAVER API HUB 연결 완료

이전 5분 뉴스 캐시/중복 묶기/뉴스·공시 통합 정렬 설명을 대체한다. 신규 검색 API는 API HUB로 이전되어 뉴스 전용 alfinder-news 앱을 등록했다. 새 호스트 `naverapihub.apigw.ntruss.com`의 `/search/v1/news`와 NCP 인증 헤더를 사용한다. 키는 gitignored passwords.yaml의 실제 shared 절에만 저장했다. 실호출 HTTP 200, 10개 결과와 필수 필드 존재를 확인했으며 기사 본문은 로그에 기록하지 않았다.

네이버 결과는 검색 응답 순서와 URL을 유지하고 별도 NAVER 뉴스 검색 영역에 표시한다. 뉴스 중복 묶기, 재정렬, 서버 결과 캐시를 제거했다. 동시 요청만 공유하며 공시는 별도 영역이다. 사용자 동의가 API 가공 조건을 면제하는 것은 아니다. 화면/문구 브랜드 적합성과 전체 운영 조건에 대한 법적 인증을 의미하지 않는다.
