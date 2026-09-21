# Flutter & Serverpod project

This project is a Flutter app (frontend) backed by a Serverpod server (backend). Always build the app's backend with Serverpod.
Build for multiple users, use Serverpod's built-in authentication, which is already set up in `lib/server.dart`.

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `investment_ontology_serverpod_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

Checklist after doing changes, in this order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `investment_ontology_serverpod_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.

## About this app: 투자 온톨로지

A single-user tool for building an investment ontology of Korean listed companies and exploring it visually (Flutter Web). Design doc: `docs/ontology-design.md`.

Principles: numbers come only from primary sources (DART OpenAPI, KRX); every fact carries a `Source`; AI is used only to extract relations from text, with evidence and human review.

Current state (phase 1 — listed-company master, phase 2 — financials and market data, phase 3 — 정기보고서 주요정보 and governance graph):

- Server code lives in `investment_ontology_serverpod_server/lib/src/ontology/`:
  - `models/` — `Company` (key: DART `corpCode`), `Industry` (KSIC 10), `Source`, `IngestJob`, view DTOs.
  - `dart/dart_client.dart` — DART OpenAPI client (`corpCode.xml`, `company.json`), throttled to ~5 calls/s.
  - `ingest/` — `CompanyMasterSync` (run as `CompanyMasterFutureCall`; incremental by DART change date, full refresh every 30 days), `KsicSeeder` (loads both KSIC 10 and 11 from `assets/ksic/`), `KsicRevision` (decides which KSIC revision DART's industry codes follow, from codes unique to one revision; cached, invalidated after each sync).
  - `tool/ksic/` — reproducible extraction of the KSIC assets from the official 국가데이터처 notices. Never hand-edit `assets/ksic/*.json`.
  - `endpoints/` — `company` (overview, divisions, list, detail) and `ingest` (startCompanyMaster, cancel, latest).
- Phase 2 (financials and market data), also in `lib/src/ontology/`:
  - `models/` — `FinancialReport` (one DART filing × consolidated/separate) and `FinancialFact` (every amount column of a `fnlttSinglAcntAll` row, BigInt won, corrections linked by `supersededBy`, never deleted), `Security`/`MarketSnapshot` (공공데이터포털), ledgers `DartFiling`, `DartFilingScan`, `MarketSnapshotDay`, `ApiCallUsage`, view DTOs.
  - `ingest/financial_facts_sync.dart` — filing list scan → fetch pending reports newest first, daily DART budget 18,000, resumes next day; `corpCode` fetches one company. The history window fills the latest 5 fiscal years first and widens to 10 once nothing is pending (once widened it stays, since narrowing would re-scan the whole filing list). `ingest/market_snapshot_sync.dart` — daily prices + listing (crno → `Company.jurirNo`).
  - `ingest/ingest_schedule.dart` — the only place that references generated `futureCalls` dispatchers, and only `lib/server.dart` imports it. Endpoints and FutureCall files schedule through `ingest/ingest_hooks.dart` (`IngestHooks`, installed by `IngestSchedule.onServerStart`) and must never import `ingest_schedule.dart`: when a new FutureCall's generated getter does not exist yet, the `serverpod start` generator marks every file that (even transitively) references it as broken and drops it from generated code — and its stale analyzer keeps doing so. After adding a FutureCall method, run `serverpod generate --force`, then `dart test test/unit/generated_code_test.dart`.
  - `financial/financial_accounts.dart` — key accounts by XBRL ID only (매출·영업이익·순이익·자산·부채·자본·영업활동현금흐름·유형자산취득).
    `endpoints/` — `financial` (summary, report), `market` (industryTreemap), `screen` (list). The screener computes PER·PBR·ROE·영업이익률·성장률·부채비율·배당수익률·FCF 수익률 for every listed company on the same TTM basis as the company page, caches the whole universe per data version and filters in memory.
    현금흐름표는 분기·반기에도 누적만 공시하므로 `amount`가 곧 누적이다 (앱 `FinancialView.cumulative`와 `ScreenEndpoint`의 `inc` CTE가 같은 규칙).
  - Derived metrics (PER, margins, Q4, TTM) are computed in the app (`lib/features/financials/financial_metrics.dart`) and shown with their formula and inputs; never store them.
- Phase 3 (정기보고서 주요정보 28종, governance graph; design `docs/phase3-governance.md`), also in `lib/src/ontology/`:
  - Three layers. Raw: `DartFilingSection` (ledger: annual report × section, `yearRank` 0 = the company's latest report), `DisclosureReport` + `DisclosureRow` (every response row as JSON, all 28 sections). Typed: `ShareholderEntry`, `ExecutiveEntry`, `InvestmentEntry`, `DividendEntry`, `TreasuryStockEntry` (add a typed table only when a screen needs it; the other sections stay raw). Index: `OntologyRelation` (graph edges rebuilt from the typed layer; AI relations in phase 4 go here with status draft), `Person`, `PersonLinkRejection`.
  - `dart/dart_sections.dart` — the 28 APIs (path, label, group, tier 0 = core 9) and Korean column labels. Units differ per API: 타법인출자 amounts come in won (DART converts), 배당 keeps the unit in the row label — never convert units you have not verified against the filing.
  - `ingest/disclosure_sync.dart` — per section, latest report per company and core sections first. While the financial backfill has work left, only core sections of each company's latest report, up to 9,000 calls/day. Company runs (`corpCode`) use the full DART limit. Empty rows (all `-`) are counted, not stored. Corrections supersede.
  - `disclosure/disclosure_links.dart` — names → listed companies only when exactly one listed company matches after normalization; executives → `Person` by (name, birth year-month); shareholders → same-report executive (확정) or ownership cluster (추정, shown dashed, rejectable). Rebuild without API calls: `ingest.rebuildDisclosureLinks`.
  - `endpoints/` — `governance` (summary, person, rejectPersonLink), `disclosure` (sections, table, shareholderReturn).
- Phase 4 (AI relation extraction):
  - `DartSection.businessContent` (tier 2) — `DisclosureSync` downloads the filing's original `document.xml` (1 call) and `disclosure/business_text.dart` keeps only "II. 사업의 내용" as text (tables → ` | ` lines, sub-sections → `## ` lines) in `BusinessDocument`. Attachment-only corrections have no file (014): fall back to the same year's earlier rcept.
  - `DocumentFact` kinds: 수주총액·기납품액·수주잔고 · 생산능력·생산실적·가동률 · 시장점유율 · 투자계획·투자집행. Values keep the unit printed in the filing. Facts are keyed by (document, kind, label, asOf), so one table can carry several years. `disclosure/production_facts.dart` reads the 생산능력·생산실적·가동률 table by rule (no AI, `extractedBy: api`, auto-verified) when 가동률 ≈ 생산실적 ÷ 생산능력; it runs on every new document and can be replayed with `ingest.rebuildProductionFacts`. Everything else is read from the text and reviewed.
  - When filling a series by hand from past filings: take each year's value from that year's own filing (companies restate), normalize the label across years (㈜·"및 종속회사" break a series into fragments), and cross-check overlapping columns between filings before approving. `disclosure.factTrends` feeds the per-year charts on the 사업의 내용 tab; the chart's x axis is `asOf`'s year, so a plan for next year lands in the right place.
  - `ai/` — `AnthropicConfig` (`anthropicApiKey` in `passwords.yaml` `shared:` or `ANTHROPIC_API_KEY`; model `ANTHROPIC_MODEL`, default `claude-sonnet-5`), `RelationExtractor` (prompt, JSON parse, **drop any candidate whose evidence quote is not verbatim in the source**), `AiExtractionService` (drafts per document; re-runs keep human decisions), `AiExtractionFutureCall` (batch, started from the data page; never automatic — it costs money).
  - **AI runs only ahead of time, never during a request.** Screens read stored results. Besides the API batch, relations can be prepared outside the server (in a Claude Code session on the user's subscription) and posted in: `ai.pending` (unread documents, shortest first) → `ai.documentText` (the same excerpt the model would see) → `ai.submit(documentId, answerJson, model:)`, which runs the same verbatim-evidence check and stores drafts. `AiExtractionService.offline(session).store(...)` is the shared path; no API key needed. Any future precomputed field (business summary, risk factors) follows the same shape: evidence kept, human review, stored.
  - **본문 값** (`DocumentFact`, `ai/document_facts.dart`): 수주잔고·수주총액·기납품액·생산능력·생산실적·가동률·시장점유율 — DART API에는 없고 사업보고서 본문·표에만 있는 값. Numbers keep the filing's own unit (백만원, 백만 달러, %, 대, 배치); never convert. Same discipline as relations: verbatim evidence, draft → human review (`review.facts` / `review.decideFact`), verified ones show in the 사업의 내용 tab (`disclosure.facts`). Submit with `ai.submitFacts(documentId, json, model:)`.
  - For the subscription-session path (no paid key), read documents with `ai.pending` → `ai.documentTexts` (several companies in one call, relation-dense sections first, `maxChars` per company) and submit with `ai.submit` / `ai.submitFacts`.
  - AI relations live in `OntologyRelation` (`extractedBy: ai`, `status: draft`, `evidence`, `confidence`, `extractorModel`, `factKind: businessDocument`). `DisclosureLinks.rebuild` only replaces `extractedBy: api` rows. Endpoints: `ai` (status, extractCompany, startBatch, pending, documentText(s), submit, submitFacts), `review` (list, decide, decideMany, facts, decideFact, decideFactsMany, recordCheck, checks, forCompany). Every decision records `reviewedBy` (null = the person clicked it). `ReviewCheck` holds the **measured** accuracy — how many of N drafts actually matched the source when checked one by one — which is not the model's own `confidence`; the review screen shows it. Check a batch against the source, decide the clear ones with `decideMany`, leave judgment calls to the person, and record the count with `recordCheck`.
- Phase 5 (themes): `InvestmentTheme` (table `theme`; the class is not `Theme` to avoid clashing with Flutter's `Theme`) and `ThemeMember` (company ↔ theme, a note on why, a `manual` `Source`). `endpoints/theme_endpoint.dart`; market caps come from `market/market_caps.dart` (latest snapshot day, sum of the company's securities).
- The DART API key is read by `dart/dart_api_key.dart`: `session.passwords['dartApiKey']` (`config/passwords.yaml` under `shared:`, or `SERVERPOD_PASSWORD_dartApiKey`), falling back to the `DART_API_KEY` environment variable.
- The 공공데이터포털 service key is read by `data_go_kr/data_go_kr_service_key.dart`: `session.passwords['dataGoKrServiceKey']` (`shared:`), falling back to `DATA_GO_KR_SERVICE_KEY`. Store the Decoding key; never write it into a `Source` URL.
- No authentication: local single-user use only. Add auth before deploying anywhere public.
- Source values are normalized to the schema's types at the ingest boundary (`dart/dart_values.dart`); invalid values become null. Re-fetches record field-level diffs in `CompanyChange` (`ingest/company_changes.dart`).
- Flutter UI:
  - `lib/design/` — design system. `tokens.dart` (semantic `AppColors`/`AppTypography`/`AppShape` theme extensions, `AppSpace`, `AppMotion`; read via `context.colors` / `context.typo` / `context.shape`), `components/` (reusable widgets), `brands/` (concrete colors and fonts), `app_theme.dart`.
  - `lib/app/` — `router.dart` (go_router; all screen addresses), `app_shell.dart` (top menu 시장 · 기업 · 관계망 · 지분 묶음 · 테마 · 검수 · 데이터; global search for companies and persons — `company.list` sorted by market cap + `governance.searchPersons` — as a field ≥1100px wide, else an icon opening a dialog), `ingest_monitor.dart` (the one app-wide watcher of ingest jobs; screens listen to its `dataVersion` to reload after any job finishes — don't add per-screen job polling for that).
  - `lib/features/<feature>/` — screens. Use only tokens and components: never hard-code colors (`Color(0x…)`, `Colors.*`) or fonts here or in `lib/app/`. `test/design_boundary_test.dart` enforces this. Rebranding = add a brand in `design/brands/` and switch it in `main.dart`.
  - `market_map/` — `/market` (market counts, market-cap treemap, industry distribution). `companies/` — `/companies` list; filters live in the URL (`CompanyFilter`). `company_detail/` — `/company/:corpCode`, header with key metrics (tap → formula in the 재무 tab) + tabs 개요, 재무, 지배구조, 주주환원, 공시 항목 (`?tab=`). Add a tab only when its data exists. `financials/` — the 재무 tab and `/reports/:reportId` statement table. `governance/` — 지배구조 tab (graph + tables) and `/person/:personId`. `shareholder_return/` — 주주환원 tab. `disclosures/` — 공시 항목 tab (raw tables of all 28 sections). `business/` — 사업의 내용 tab (TOC, text, tables, AI relations of this company). `review/` — `/review` AI relation review queue (approve/reject with evidence). `themes/` — `/themes` and `/themes/:themeId` (members, market-cap treemap, add companies); the company header shows theme chips and "테마에 추가". `groups/` — `/groups` and `/groups/:corpCode` 지분 묶음 (listed companies linked by corporate shareholders and 경영참여 investments ≥15%, from each company's latest annual report; server `disclosure/ownership_groups.dart`, same rule as `DisclosureLinks.ownershipClusters`, cached by data version; endpoint `group`). `data_sync/` — `/data` ingest status and 수집 현황 (`ingest.coverage`). `common/formatters.dart` — shared formatting.
  - Navigate between top menus with `context.go`; open a detail with `context.push` (the list stays mounted, so back restores scroll and filters).
  - Charts live in `lib/design/components/charts/` and use the `chart*` color tokens. If a brand changes those colors, re-run the dataviz palette validator against the brand's surface.
