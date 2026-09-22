# 투자 온톨로지

한국 상장사 2,756곳의 재무·시세·지배구조·사업 내용을 1차 공시에서 받아 하나의 온톨로지로 엮고, 화면으로 탐색하는 1인용 도구입니다. Flutter Web 앱 + Serverpod 4 서버(내장 PostgreSQL).

세 가지 원칙이 모든 결정의 기준입니다.

1. **숫자는 1차 출처에서만.** DART OpenAPI, 공공데이터포털(금융위원회). 모든 값에 출처(`Source`)가 붙고, 정정 공시는 지우지 않고 대체 관계로 남깁니다.
2. **파생 지표는 저장하지 않고 화면에서 계산.** PER·ROE·TTM 같은 값은 앱이 원천 값으로 계산하고 계산식과 입력값을 같이 보여 줍니다. 화면마다 같은 기준(최근 12개월, 연결).
3. **사업보고서 본문은 스스로 검산되는 표만 규칙으로 읽는다.** 검산에 통과한 값만 저장하고 사람 검수는 없습니다. AI가 문장을 읽는 작업은 서버 밖에서만 하고(앱은 AI를 부르지 않음), 지금은 보류 상태입니다.

## 데이터 스냅샷 (2026-09-22, 실시간 수치는 데이터 화면 참고)

| 층 | 있는 것 | 진행 |
|---|---|---|
| 상장사 마스터 | 2,756개사 (DART 기업개황, KSIC 업종) | 완료, 30일마다 전체 갱신 |
| 재무제표 | 6,249,623 계정값 (연결·별도, 사업·분기·반기) | 정기보고서 46,391건 중 24,109건, 하루 18,000호출로 이틀쯤 더 |
| 시세·지수 | 전 종목 일별 시세 5년, 지수 170종 | 매일 18:00 전날 값 |
| 정기보고서 주요정보 28종 | 최대주주·임원·타법인출자·배당·자기주식 등 | 최신 사업보고서 핵심 항목 100%, 5개년 전체 7.5% |
| 관계 색인 | 83,069건 (임원·출자·주주·공급/매출·경쟁·제품), 인물 32,091명 | 주요정보가 들어올 때마다 다시 계산 |
| 본문 값 | 3,888건 (부문 매출·수주·생산능력·가동률·점유율·연구개발비), 244개사 | 본문 377개사, 하루 300건씩 |
| 테마 · 지분 묶음 | 테마 5개, 지분으로 이어진 상장사 묶음 | 완료 |

자동 수집(서버가 켜져 있는 동안): 18:00 시세·지수 → 18:30 재무 새 공시 → 19:00 주요정보 새 공시 → 다음 날 00:05 / 00:10 한도 소진분 이어받기. 새 본문이 들어오면 표 규칙이 바로 돕니다. 상태는 앱의 **데이터** 화면 맨 위 "지금 상태"에서 봅니다.

Serverpod 이메일 로그인을 사용합니다. 로그인 사용자는 공용 데이터를 조회하고, 관리자는 수집·테마·검수 데이터를 변경할 수 있습니다. 최초 관리자와 개발 모드 가입 방법은 [접근 제어 안내](docs/access-control.md)를 참고하세요. 테마의 계정 개인화는 아직 하지 않습니다.

인수인계 기준과 재현 절차: [마감 기록](docs/handoff-acceptance-2026-09-22.md).

## 화면

| 메뉴 | 주소 | 무엇 |
|---|---|---|
| 시장 | `/market` | 시장별 기업 수, 코스피·코스닥 지수 추이, 시가총액 추이·트리맵, 최근 정기보고서 |
| 기업 | `/companies`, `/company/:corpCode` | 목록(필터는 주소에), 상세: 개요 · 재무 · 사업의 내용 · 지배구조 · 주주환원 · 공시 항목 |
| 스크리너 | `/screen`, `/compare` | PER·PBR·ROE·성장률·부채비율·배당·FCF로 거르기, 최대 4곳 비교 |
| 관계망 | `/graph` | 지분·출자·임원·공급·경쟁 관계를 따라 넓히는 그래프 |
| 지분 묶음 | `/groups`, `/groups/:corpCode` | 지분으로 이어진 상장사 묶음, 보유 지분 가치와 시가총액 대비 |
| 테마 | `/themes` | 직접 고른 종목 묶음과 메모 |
| 데이터 | `/data` | 자동 수집 지금 상태, 층별 수집 현황, 수동 실행 |
| (인물) | `/person/:id` | 주주·임원으로 나오는 기업들 |
| (재무 원문) | `/reports/:id` | 재무제표 원문 표, 정정 이력 |

## 구조

```
investment_ontology_serverpod_server/     Serverpod 서버
  lib/src/ontology/
    models/        *.spy.yaml — 데이터 모델 (테이블과 화면용 DTO)
    endpoints/     company · financial · market · screen · governance · disclosure · group · theme · ingest · ai · review
    ingest/        수집 (company_master_sync, financial_facts_sync, market_snapshot_sync, disclosure_sync, ingest_schedule)
    disclosure/    본문 규칙 추출기와 관계 연결 (아래 표)
    dart/          DART OpenAPI 클라이언트, 28종 API 정의, 값 정규화
    ai/            서버 밖에서 읽은 결과를 받아 넣는 경로 (앱은 쓰지 않음)
  lib/src/generated/   생성 코드 — 손대지 않음
  test/unit/           규칙 추출기 등 단위 테스트 (개수는 실행 결과 기준)
  tool/                KSIC 자산 추출, 본문 요약 도구
investment_ontology_serverpod_client/     생성 코드 — 손대지 않음
investment_ontology_serverpod_flutter/    Flutter Web 앱
  lib/app/         router · app_shell(상단 메뉴, 검색) · ingest_monitor
  lib/design/      디자인 시스템 (tokens, components, brands) — 화면은 토큰만 쓴다
  lib/features/    화면별 코드
docs/              ontology-design · phase3-governance · handoff(작업 기록) · deploy
scripts/           host.sh(맥을 서버로), serve_web.py(정적 호스팅), watchdog.sh(지킴이), auth_proxy.py
deploy/            VPS용 docker-compose · Caddyfile
```

### 본문 규칙 추출기 (`disclosure/`)

각 규칙은 표 하나를 읽어 **스스로 검산**하고, 통과한 값만 저장합니다. 검산이 안 되면 버립니다.

| 파일 | 읽는 표 | 검산 |
|---|---|---|
| `segment_revenue.dart` | 부문별 매출 | 표에 적힌 비중 = 금액 ÷ 합계 |
| `order_facts.dart` | 수주상황 (표준·건설·흐름 세 꼴) | 수주총액 = 기납품액 + 수주잔고 (또는 기초 + 신규 − 납품 = 기말) |
| `production_facts.dart` | 생산능력·생산실적·가동률 (가로·세로·가동률만) | 가동률 ≈ 생산실적 ÷ 생산능력 |
| `market_share_facts.dart` | 연도별 시장점유율 | 연도 머리글, 당사 줄, % 값, 최근 7년 |
| `rnd_facts.dart` | 연구개발비용 | 표의 비율 = 연구개발비 ÷ 매출액 (표 또는 재무제표) |
| `supplier_rows.dart` + `supplier_relations.dart` | 원재료 매입처, 주요 매출처 | 머리글이 정확히 매입처/매출처인 칸만, 이름 정규화 후 상장사와 일치할 때만 연결 |
| `disclosure_links.dart` | 주요정보 → 관계 색인 | 이름이 상장사 하나와만 맞을 때, 임원은 이름+출생년월 |
| `ownership_groups.dart` | 지분 묶음 | 법인 주주 + 경영참여 15% 이상 출자 |

## 실행

```bash
# 서버 + 앱(개발, 8100). 파일이 바뀌면 코드 생성과 핫 리로드가 자동
cd investment_ontology_serverpod_server && serverpod start
```

```bash
# 정적 웹 빌드로 확인 (8101), 폰에서는 8110 (scripts/host.sh)
cd investment_ontology_serverpod_flutter && flutter build web --release
```

키는 `investment_ontology_serverpod_server/config/passwords.yaml`의 `shared:`에 `dartApiKey`, `dataGoKrServiceKey`(공공데이터포털 Decoding 키). 열어 보거나 출력하지 않습니다.

검사 순서 (코드를 고친 뒤): 자동 생성은 `serverpod start`가 담당합니다. 분석·포맷 후 모델 변경이 있으면 MCP로 마이그레이션을 생성·적용하고, 필요한 재시작과 테스트·로그 확인을 합니다. 전체 절차는 `AGENTS.md`를 따릅니다. 아래는 CLI 검사 명령이며 강제 생성은 일상 검사에 포함하지 않습니다.

```bash
cd investment_ontology_serverpod_server && dart analyze && dart format .
# 필요한 MCP 마이그레이션·재시작 뒤
dart test test/unit
```

```bash
cd investment_ontology_serverpod_flutter && dart analyze && flutter test
```

DB 직접 보기: `psql -h /tmp/iopg -U postgres -d investment_ontology_serverpod`.

## 운영 규칙과 함정 (실제로 겪은 것)

- **서버가 도는 동안 브랜치를 바꾸거나 pull하지 않는다.** 감시 생성기가 반쯤 바뀐 트리로 코드를 다시 만들어 엔드포인트가 사라진다. PR을 합친 뒤 작업 트리가 `main`으로 옮겨진 적이 있으니 병합 뒤 `git branch --show-current`를 확인한다.
- **자동 생성 결과를 검증한다.** 엔드포인트·FutureCall 변경 뒤 `dart test test/unit/generated_code_test.dart`로 누락을 확인한다. MCP 로그와 자동 생성 상태를 먼저 확인하며, 과거의 `serverpod generate --force` 복구 사례를 매번 실행하는 규칙으로 쓰지 않는다. CLI 복구 조건은 `AGENTS.md`를 따른다.
- **생성 코드는 손대지 않는다.** 모델은 `.spy.yaml`, 로직은 엔드포인트에서.
- **규칙을 바꾸면 다시 돌리고 눈으로 본다.** `ingest.rebuildProductionFacts`로 재실행하고 새로 들어온 행을 전부 확인한다. 느슨한 정규식 하나가 쓰레기 관계 1,135건을 넣은 적이 있다.
- **열은 머리글로 고르고 줄의 오른쪽 끝에서 다시 찾는다.** 공시는 당기·전기·전전기를 나란히 적으므로 마지막 칸을 집으면 3년 전 값이 검산을 통과한 채 들어간다.
- **단위 처리는 추출기별로 다르다.** 부문 매출·수주는 표 위 3줄 이내 단위를 한 번 쓰고 비운다. 생산능력·실적은 머리글·이름·구분 칸의 괄호와 앞 6줄의 단위도 탐색한다. 생산 추출기도 실제 가로형 머리글에서 앞 단위를 소비하고, 절·회사 경계에서는 단위와 미완성 세로형 값을 초기화한다. 경계 회귀 테스트를 유지한다. 단위를 못 찾으면 능력·실적은 버리되 검산된 가동률은 남길 수 있다.
- **화면 코드는 색·글꼴을 직접 쓰지 않는다.** `test/design_boundary_test.dart`가 막는다. 표는 `AppDataTable` — 남는 폭을 채우고 폰에서는 부수 열을 접는다.
- **앱은 AI를 부르지 않는다.** 화면은 저장된 것만 읽는다.
- 답과 기록은 한글로, 큰 금액은 "234조 9,034억" 꼴로.

## 문서 지도

- `AGENTS.md` — 코드를 고칠 때 지켜야 할 지침 전체 (가장 먼저 읽을 것).
- `docs/handoff.md` — 작업 기록: 결정, 함정, 남은 일. 항목 배치는 시간순이 아니므로 날짜·시각과 명시된 사용자 결정을 기준으로 읽는다. 현재 방침은 문서 상단을 먼저 본다.
- `docs/ontology-design.md`, `docs/phase3-governance.md` — 설계.
- `docs/deploy.md`, `deploy/README.md` — 맥+Tailscale, VPS, 공개 URL 세 가지 배포.
