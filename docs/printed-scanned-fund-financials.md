# Exact MKIF scanned current fund categories

This follow-up adds only the original MKIF own 2021 and 2022 annual audits. Together with the separate MKIF2023–2025 text/font branch, the read feed may show five distinct own annual periods. Generic financial HTML rules and the six blocked-company guards are unchanged. There is no new RPC, model, generated code, migration, dependency, Docker change, paid API or Cloud OCR runtime.

## Source and extraction scope

Original PDFs are bound by the existing official-IR source URL and exact SHA-256. Locally, unchanged original physical PDF pages 8–13 are rendered with Poppler26.02.0 `pdftoppm -f page -l page -singlefile -scale-to scale -png`. Scale is4400, except MKIF2021 CE page11 at6600. No crop, pixel editing, OCR-string rewrite or digit substitution is performed. The renderer/pipeline, macOS26.5.2 build25F84, Swift6.3.3, both exact Swift-script hashes, page/image hashes and original raw OCR-JSON hashes are retained in the profile and private sidecar.

The same Apple Vision engine runs twice, once with ko-KR/en-US and separately with en-US, accurate recognition and language correction disabled. These are distinct recognition runs, not two different OCR engines or a measured-accuracy guarantee. Each selected numerical token preserves both raw strings, original observation indexes and bounding boxes.

A narrowly scoped `grouped-integer-comma-or-dot-v1` grammar interprets comma/dot as a thousands separator only with exactly three digits in every following group; whitespace is allowed only after a separator. Both OCR runs must yield the same digit sequence and the same sign representation. Raw strings remain unchanged. A g/9 substitution, actual digit disagreement, malformed or missing separator, decimal-looking invalid grouping, ambiguous number bbox and sign disagreement are rejected. This grammar is confined to the scanned-fund category and does not relax DART, HTML or other company rules.

The old 2200px OCR evidence and its confidence1 `53.50g,690,772` error remain unchanged in the audit artifact. New recognition from new original-page renders supplies separate evidence. The4400px MKIF2021 CE candidate had invalid `84.576,897348` grouping; it was rejected. The6600px full-page recognition yields valid grouped tokens in both runs. Re-rendering was not a text correction.

## Verified selected values and bounded equations

Eight current categories per own annual period are accepted: assets, liabilities, equity, fund operating income, net profit, asset-management cash flow, loan acquisition and equity acquisition. Loan/equity acquisition preserve positive printed values with a separate outflow direction. MKIF2021 negative asset-management cash flow retains its parentheses-derived negative sign despite the source label ending 현금유입액. Values are explicitly derived integers from dual raw OCR, not literal raw OCR punctuation or XBRL amounts.

The original 12 primary statement pages were visually read for current selected values, numeric witnesses, period/unit and statement/component layout. The independent Python proof checks35 integer equations in2021 and33 in2022: BS groups and identity, PL income/expense/profit, CF groups/net/roll/BS numeric cash match, and current CE component sums, three component roll-forwards, three BS component matches and PL net-profit match. All differences are exactly0; no tolerance, rounding or sign flipping is used.

CE dash/blank components are nullable missing witnesses, never zero amount facts. Some CF dashes have a Korean OCR witness while English misses the dash; they remain non-numeric witnesses and the equation records its missing-term count. The2021 PL tax dash is not emitted as a tax amount; a specifically named check compares the printed pretax and net-profit amounts. The source images establish these dash/blank positions. No missing term becomes a stored FinancialFact or a numeric zero. EPS, stock counts, prices and comparative-period values are not account observations.

BS 현금및예치금 and CF 현금및현금성자산 are only checked for printed numerical equality; their semantic cash scope is not declared equivalent. Audit opinion, notes, full statements, the whole document and comparison periods are unverified and visibly remain outside scope. `fullStatementCollected`, `notesDecodedOrVerified` and `wholeDocumentOcrReviewed` stay false.

## Normal storage and runtime

The local preparation/compiler tools produce private immutable `${pdfSHA}.pdf`, `${pdfSHA}.scanned-ocr.json` and six `${pdfSHA}.pXX.png` files per document. Cloud reads and verifies these artifacts against compiled original/image/sidecar/pipeline pins. Missing or modified artifacts fail normal collection with pending work; no live OCR is run. Install the complete prepared private package before collection. Test fixtures are not part of the production container.

Normal business collection stores separate immutable issuerFinancials snapshots and officialFile Sources with the exact source-document descriptors. Repeated writes are idempotent; ordinary research-feed imports cannot create these numerical snapshots. Public reads retain actual company/source binding. No FinancialReport, FinancialFact, API usage, regular filing completion, industrial revenue/CFO/PPE, TTM or derived financial metric is stored or substituted.

Pure tests compare all16 current values/coordinates with the independently computed original OCR proof and reject source changes, wrong issuer/period/basis, digit-letter/sign/grouping/bbox mutations, fabricated completeness, duplicates and mixed issuers. The UI test opens all five MKIF annual periods at320px and retains source links, original signs/outflow direction and source-scope notices. Normal DB regression tests for the two actual source PDFs cover idempotency/public reads/import denial, missing or changed sidecar/page images, recovery and cancellation with zero regular financial/API/business ledgers. DB tests are implemented and analyzed but are not claimed passed until the parent grants the shared DB slot and runs the canonical gate.
