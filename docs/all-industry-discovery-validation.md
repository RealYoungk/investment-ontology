# 전 업종 탐색 적용 검증 — 2026-10-01

로컬 동결 데이터 기준, 운영 미배포.

상장사 2759곳, 분류 2759곳, 고유 기업 2759곳, 탐색 분야 39개. 활동 행 2779개로 복수 사업 기업은 분야 간 중복될 수 있다.

## 범위
- 모든 업종이 `/industries?industry=...` 공통 화면으로 진입한다. 사업군, 세부 분야, 검색, 시장 필터, 비교, 근거 펼치기를 공유한다.
- KSIC 등록 업종 분류와 공시 제품 분류는 별도 근거 유형이다. 공식 GICS 회사 배정이 아니다.
- KSIC 10·11의 모든 숫자 코드를 탐색 분야에 연결하는 검사를 통과했다. 정확한 해당 개정판에 존재하지 않는 기업 코드는 미분류로 유지한다.
- 반도체 외 업종의 제품 공시 추출은 이번에 새로 실행하지 않았다. CDMO·신약 플랫폼 등 등록 코드만으로 구별할 수 없는 사업은 추정하지 않는다.
- 서버/DB 쓰기와 외부 API 수집 없이 읽기 전용으로 계산한다. 신규 DTO 선택 필드는 자동 생성, DB 스키마 변경 없음.
- 목록은 처음 10개와 더 보기이며 현재 browse 응답은 전체 탐색용 1.5MB 데이터다. 이 화면의 10개 표시는 서버 페이지네이션을 의미하지 않는다.

| 분야 | 기업 수 |
|---|---:|
| 건설·인프라 | 60 |
| 게임 | 26 |
| 공공·생활 서비스 | 2 |
| 교육 | 12 |
| 금융·보험 | 154 |
| 기계·생산 장비 | 175 |
| 기업 서비스 | 67 |
| 농림·수산 | 4 |
| 미디어·콘텐츠 | 67 |
| 반도체 | 135 |
| 배터리 | 21 |
| 부동산 | 27 |
| 생활용품·가구 | 54 |
| 소프트웨어·IT 서비스 | 241 |
| 스포츠·여가 | 5 |
| 식품·음료 | 90 |
| 에너지·자원 | 5 |
| 여행·숙박·외식 | 9 |
| 연구·엔지니어링 | 103 |
| 운송·물류 | 29 |
| 유리·시멘트·건축 소재 | 36 |
| 유통·무역 | 171 |
| 의료기기·의료 서비스 | 76 |
| 의류·섬유·신발 | 52 |
| 자동차·부품 | 110 |
| 전기·가스·수도 | 13 |
| 전기장비 | 78 |
| 전자부품·IT 기기 | 232 |
| 제약·바이오 의약품 | 187 |
| 조선 | 13 |
| 지주회사 | 75 |
| 철강·금속 | 138 |
| 철도·기타 운송장비 | 5 |
| 측정·광학 기기 | 42 |
| 통신 | 14 |
| 항공·우주 | 12 |
| 화장품 | 29 |
| 화학·소재 | 202 |
| 환경·재활용 | 3 |

## 2026-10-01 business detail follow-up

- Broadened registered groups from KSIC level 3 to level 4, retaining level-5 product labels. Identical shortened parent/child labels now share one button.
- Added conservative self-statement rules for business models/products across pharma, software, batteries, cosmetics, medical devices, auto parts, electronics, food, electrical equipment and energy. Exact filing sentences and receipts retained; no database writes or AI extraction.
- Live `industry.browse`: 2,759 listed companies retained, 374 distinct industry/role groups, 584 industry/product keys. These totals combine registered classifications and filing-derived activities; they do NOT measure confirmed product peers.
- 159 distinct companies currently have filing-derived activities, including existing semiconductor rules. Other companies still use registered activities; exhaustive business-model classification remains unfinished.
- Audit explicitly removed acronym substring matches (Micro/CRO, Enterprise/ERP, Design/SI), equipment/customer versus product-maker confusion, upstream inputs misread as cathodes, and subsidiary statements. A conservative subsidiary boundary can omit later valid parent-company statements; prefer omission to attribution errors.
- Static analysis: no issues. 20 rule/taxonomy tests and the public-discovery integration test passed; final rerun of 5 new rules tests plus integration passed.
- Chrome verified pharma → contract development/manufacturing (7 companies) → biological drug CDMO (6 companies), and saved `outputs/industry-discovery/business-detail-cdmo.png`.
- Local only. Existing read-only DB housekeeping errors remain; browse succeeds. No production deployment performed.

## 2026-10-01 local v2 review build

Implemented in the actual Flutter/Serverpod app, not only the standalone design prototype:

- Separate public filing-backed business browsing and official registered-industry browsing. Keep all 2,759 company registered rows even when detailed activities exist. Counts across views overlap and are not additive.
- Normalize semiconductor IP/design services/foundry/OSAT, pharma offerings, and software products versus infrastructure/services. Preserve original evidence, product keys and receipt references.
- Remove industry-directory search too. Offer conditional visible product/process/target/method buttons, suppress invariant process controls, fold market options, add offering definitions and classification-method disclosure with official MSCI reference.
- Preserve legacy design/service and old business-role URLs without widening product scopes. Legacy q does not filter.
- 159 distinct companies still have filing-derived business evidence; this UI change does not claim exhaustive business coverage or add unverified technology facts. Other industries retain their available evidenced activity groups with a separate registered view.
- Server tests: 2 offering tests + 1 public browse integration passed. Flutter: 5 discovery tests (including responsive source switch, comparison and legacy scopes), 2 directory tests and 2 design-boundary tests passed across the final and immediately preceding runs. Targeted analyze clean.
- Browser observed actual local semiconductor → IP → interface IP → Qualitas filing evidence, and pharma → outsourced development/manufacturing → biological CDMO → 6 companies. Screenshots: local-v2-ip.png and local-v2-pharma.png.
- DTD health succeeded; driver navigation timed out, so UI verification used Chrome. No production deploy or database writes. Existing read-only database housekeeping limitations unchanged.
- Remaining infrastructure work from the design: persisted precomputed activities, real server result pagination (current 10-at-a-time display still uses the full cached catalog), broader extraction/coverage and complete technical terminology dictionaries. Do not present these as implemented.

## 2026-10-01 상장사 전수 누락 점검 (프로티나 지적 이후)

전체 명단 2,759곳을 실제 로컬 공개 API와 대조하고, 각 기업의 `disclosure.businessContent`를 동시 2건으로 조회했다. 본문 2,721곳, 미확보 38곳. 결과는 `outputs/industry-discovery/census/companies.csv`에 한 기업 한 행으로 남긴다. 명단 수와 기업 코드 집합 일치를 도구에서 강제한다.

프로티나는 미분류 전체가 아니라 신약 연구개발만 표시되고 단백질 상호작용 분석 사업이 누락돼 있었다. 공시 자기소개 문장으로 `protein_analysis`를 추가하고 `research_service`로 연결했다. S-OIL 정유 분류도 유지한다. 별도로 게임·물류·보험·교육 등 자기 영위 사업의 명시적 문장을 인식하는 규칙을 추가했다. 회사명이나 KSIC만으로 제품 근거를 만들지 않았다.

범용 제품 표 확장은 전수 결과에서 자회사 귀속, 병합 셀의 열 밀림, 과거 매출만 있는 제품 등 오분류가 드러나 **이번 변경에 포함하지 않았다**. 특히 한국타이어의 용도 열을 완성차로, 태림포장의 골판지 원단을 의류 원단으로 읽는 위험이 있었다. 기존 문장 규칙에서도 아나패스·도우인시스·에이직랜드를 디스플레이 패널 제조로 잡는 경로와 클라우드 보안을 인프라로 잡는 경로를 제외했다. 신규 규칙의 투자은행→은행, 전기자전거→전력 공급, 광고대행사 고객→광고업 오인도 회귀 테스트로 막았다.

규칙 v6 실제 API: 사업 분류가 하나 이상 있는 기업 219곳 / 2,759곳, 근거 242건. 이 242건은 조회한 동일 접수번호 공시 원문과 전부 일치했다. **원문 일치는 의미 검증 완료를 뜻하지 않는다.** 미분류 2,540곳(본문 있으나 미분류 2,428 / 지주회사 직접 분류 제외 74 / 본문 미확보 38). 전체 기업 정독·주력 사업·복수 사업 의미 검증은 미완료다. 분류가 하나라도 있는 기업도 모든 사업을 포괄한다고 볼 수 없다.

화면에는 전체 분류 기업 수와 등록 업종 수를 분리하고, 해당 등록 업종의 사업 미분류 기업 목록을 접어서 제공한다. 선택한 사업이 없다는 뜻이 아님을 명시한다. 검색창은 복원하지 않았다.

검증: 서버 규칙/정규화/반도체 회귀 26개, Flutter 업종 탐색/디렉터리/디자인 경계 9개 통과. 변경 Dart 정적 검사 통과. 실제 Chrome에서 프로티나의 연구·임상 지원 → 단백질 상호작용 분석 → 원문 근거를 열어 확인, `outputs/industry-discovery/census/protina-local.png` 저장. DB 변경·공시 재수집·유료 AI 호출 없음. 공개 배포 없음.

후속 작업은 `companies.csv` 미분류 명단에서 출발해야 한다. 모든 기업의 사업을 검증하지 않은 채 이 작업을 완료로 보고하면 안 된다. 지주회사와 연결 사업 귀속을 별도 모델로 설계하고, 표의 병합 셀 및 회사별 블록을 보존한 추출 경로를 구축하는 것이 남아 있다.

## 2026-10-01 제품 사전 확장과 단일 사업 보기

등록 업종 전환 버튼을 없애고, 디렉터리 수치도 공시 사업 분류만 센다. 이전 등록 업종 링크는 사업 보기로 해석한다. KSIC 원천 자료를 사업 근거로 승격하지 않는다.

73개 제품 어휘와 제한된 영위 문법을 추가했다. 초기 확장 후보264건을 대조하며 원재료/고객업종/단어 부분일치/중단사업 오분류 경로를 발견하고 제한했다. 최종 공개 API는 전자·부품6→44곳, 전체219→322곳, 근거365건(모두 동일 원문/접수번호 대조). 후보 문장 대조가 전체 공시의 완전한 의미 검증을 뜻하지 않는다. 2437곳에 사업분류가 없으며 기존 완전성 문제는 해결되지 않았다. 최신 전수 현황은 outputs/industry-discovery/census/summary.json 및 companies.csv에 기록했다.

검증: 변경 Dart 파일 정적 분석 통과, 서버15 tests, Flutter12 tests(320/640/900/1280/1920px), 실제 Chrome390px 및 데스크톱 광학 부품 필터 확인. 새 데이터베이스 쓰기나 운영 배포 없음.
