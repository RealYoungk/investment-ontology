# 투자 온톨로지 설계 (v0.1)

개인 투자자(1인)가 국내 상장사를 중심으로 기업·산업·지배구조·공급망·테마 관계를 쌓고, Flutter Web에서 탐색·시각화하는 도구.

## 1. 원칙

1. **숫자는 원천에서만.** 재무·시세·지분율 같은 수치는 DART OpenAPI / KRX(공공데이터포털) 응답을 그대로 저장한다. AI가 숫자를 만들거나 고치지 않는다.
2. **모든 사실에는 출처.** 엔티티를 제외한 모든 사실(관계·수치)은 `Source`(공시 접수번호, API 호출, URL)를 반드시 가진다. 출처 없는 사실은 저장 불가.
3. **AI는 텍스트 → 관계 추출에만.** 사업보고서 본문에서 공급망·제품·경쟁 관계를 뽑되, 원문 인용(evidence)을 붙이고 `draft` 상태로 넣는다. 사람이 검수해야 `verified`.
4. **시점을 가진다.** 관계와 수치는 `asOf`(기준일) 또는 회계기간을 가진다. 덮어쓰지 않고 이력으로 쌓는다.
5. **스키마가 형식을 정한다.** 원천 데이터를 스키마 형식(날짜는 DateTime, 월은 1~12 정수 등)으로 정규화해서 넣는다. 형식에 맞지 않는 값은 추측하지 않고 비워 둔다.
6. **식별자는 공식 코드.** 기업 = DART `corp_code`(8자리), 종목 = 단축코드(6자리)·ISIN, 산업 = KSIC(한국표준산업분류).

## 2. 클래스 (노드)

| 클래스 | 식별자 | 주요 속성 | 원천 |
|---|---|---|---|
| **Company** 기업 | `corp_code` | 회사명, 영문명, 법인등록번호, 사업자번호, 대표자, 설립일, 결산월, 시장구분(KOSPI/KOSDAQ/KONEX), 본사주소, 홈페이지 | DART `corpCode.xml`, `company.json` |
| **Security** 종목 | 단축코드, ISIN | 종목명, 주식종류(보통/우선), 상장일, 상장주식수 | DART, KRX 상장종목정보 (2단계. 1단계는 Company.stockCode에 대표 종목만) |
| **Industry** 산업 | KSIC 코드 | 분류명, 레벨(대·중·소·세·세세), 상위 코드 | 통계청 KSIC 10차 (`assets/ksic/ksic_10.json`, FinanceData/KSIC 재배포본 — 통계청 원본 파일로 교체 예정) |
| **Person** 인물 | 내부 ID (이름+생년월 조합으로 동일인 추정) | 이름, 생년월 | DART 임원·최대주주 현황 |
| **Segment** 사업부문 | 기업+부문명 | 부문명 | 사업보고서 (AI 추출) |
| **Product** 제품·서비스 | 내부 ID | 이름, 설명 | 사업보고서 (AI 추출) |
| **Theme** 테마 | 내부 ID | 이름, 설명 | 사용자 직접 정의 |
| **Source** 출처 | 내부 ID | 종류(dart_report / dart_api / krx_api / manual), 공시 접수번호(`rcept_no`), 보고서명, 제출일, URL, 수집 시각 | — |

## 3. 관계 (엣지)

모든 관계는 공통 속성을 가진다: `source`, `asOf`(또는 기간 `validFrom~validTo`), `extractedBy`(api / ai / manual), `status`(draft / verified / rejected), AI 추출 시 `evidence`(원문 인용)와 `confidence`.

| 관계 | 주어 → 목적어 | 추가 속성 | 원천 | 신뢰 수준 |
|---|---|---|---|---|
| `ISSUES` | Company → Security | — | DART/KRX | 구조화 API |
| `CLASSIFIED_AS` | Company → Industry | — | DART `company.json`의 `induty_code` | 구조화 API |
| `PARENT_OF` | Industry → Industry | — | KSIC | 공식 분류 |
| `LARGEST_SHAREHOLDER_OF` | Person·Company → Company | 지분율, 보유주식수, 관계(본인/특수관계인) | DART `hyslrSttus.json` | 구조화 API |
| `EXECUTIVE_OF` | Person → Company | 직위, 등기여부, 상근여부, 담당업무 | DART `exctvSttus.json` | 구조화 API |
| `INVESTS_IN` | Company → Company | 지분율, 장부가액, 출자목적 | DART `otrCprInvstmntSttus.json` | 구조화 API |
| `HAS_SEGMENT` | Company → Segment | 매출액, 매출비중 | 사업보고서 부문정보 | 원문 수치 + AI 매핑 |
| `PRODUCES` | Company·Segment → Product | 매출비중 | 사업보고서 "주요 제품" | AI 추출 + 검수 |
| `SUPPLIES_TO` | Company → Company | 품목 | 사업보고서 "주요 매출처/원재료 매입처" | AI 추출 + 검수 |
| `COMPETES_WITH` | Company ↔ Company | 경쟁 분야 | 사업보고서 "경쟁 현황" | AI 추출 + 검수 |
| `EXPOSED_TO` | Company·Product → Theme | 노출도 메모 | 사용자 | 수동 |

타법인출자에서 상대 회사가 비상장이면 `corp_code`가 없을 수 있다 → 이름만 가진 **미확인 Company**로 만들고 나중에 병합한다.

## 4. 수치 데이터 (시계열)

그래프 엣지가 아니라 별도 테이블로 저장한다(건수가 많고 집계 쿼리가 필요하므로).

**FinancialFact** — DART `fnlttSinglAcntAll.json` (단일회사 전체 재무제표)
- 기업, 사업연도, 보고서코드(`11011` 사업 / `11012` 반기 / `11013` 1Q / `11014` 3Q), 연결/별도(`CFS`/`OFS`), 재무제표 구분(BS/IS/CIS/CF/SCE)
- 계정 ID(XBRL, 예: `ifrs-full_Revenue`), 계정명, 당기 금액, **원 단위 정수(BigInt)**, 통화
- `source` = 해당 보고서 `rcept_no`
- 정정공시가 나오면 새 행으로 추가하고 이전 값은 `supersededBy`로 연결 (삭제하지 않음)

**MarketSnapshot** — 공공데이터포털 금융위원회 주식시세정보
- 종목, 기준일, 종가, 시가총액, 상장주식수, 거래량
- `source` = API 호출 기록

화면에 보여주는 파생 지표(PER, 영업이익률 등)는 저장하지 않고 위 원천 값으로 계산한다. 계산식도 화면에 표시한다.

## 5. 저장 방식

PostgreSQL + Serverpod ORM. 1인·상장사 약 2,700개 규모라 별도 그래프 DB는 필요 없다.

- 노드: 클래스별 테이블 (`company`, `security`, `industry`, `person`, `segment`, `product`, `theme`, `source`)
- 엣지: 공통 `relation` 테이블 (주어 타입·ID, 술어, 목적어 타입·ID, 속성 JSON, source, 기간, status) — 새 관계 종류를 스키마 변경 없이 추가
- 수치: `financial_fact`, `market_snapshot`
- 변경 이력: `company_change` (필드, 이전 값, 새 값, 출처, 시각) — 다시 수집했을 때 바뀐 필드만 기록. 바뀐 게 없으면 출처도 새로 만들지 않는다
- 수집 작업: `ingest_job` (무엇을, 언제, 성공/실패, 호출 수) — DART 일일 호출 한도(키당 약 20,000건) 관리
- 수집 장부: `dart_corp_status` (고유번호별 마지막 상장 구분·변경일) — 온톨로지 엔티티가 아니라, 저장하지 않는 상장폐지 기업을 매번 다시 조회하지 않기 위한 기록

## 6. 단계별 계획

| 단계 | 내용 | 화면 |
|---|---|---|
| **1. 상장사 마스터** | `corpCode.xml`로 상장사 목록 → `company.json`으로 기업개황 → KSIC 분류표 적재 | 전체 상장사 테이블(검색, 시장·업종 필터), 기업 상세 페이지 |
| **2. 재무·시세** | 최근 3개년 사업보고서 + 분기 재무 수집, 시세 스냅샷 | 기업 상세에 재무 추이 차트, 업종별 시총 트리맵 |
| **3. 지배구조 그래프** | 최대주주·임원·타법인출자 수집 | 기업 중심 네트워크 그래프 (출자·지배 관계) |
| **4. AI 관계 추출** | 사업보고서 "II. 사업의 내용" → 제품·공급망·경쟁 추출, 인용문 첨부 | 검수 큐 (원문 옆에서 승인/거절), 공급망 그래프 |
| **5. 테마** | 사용자 테마 생성·연결 | 테마별 기업 지도 |

## 7. 준비물

- **DART OpenAPI 인증키** — https://opendart.fss.or.kr (무료)
- **공공데이터포털 서비스키** — 금융위원회_주식시세정보, 금융위원회_KRX상장종목정보 활용 신청 (2단계부터)
- 키는 `config/passwords.yaml`에 저장 (git 제외됨)

## 8. 열린 결정

- 인증: 1인 사용이라 1단계는 로그인 없이 로컬 전용으로 두고, 외부 배포 시 Serverpod 기본 인증(이메일)을 켠다.
- 상장폐지 기업 포함 여부: 기본은 현재 상장사만, 과거 이력은 3단계 이후.
- 재무 수집 범위: 전 계정(`fnlttSinglAcntAll`) vs 주요 계정만(`fnlttMultiAcnt`, 호출 수 절약). 기본은 전 계정.
