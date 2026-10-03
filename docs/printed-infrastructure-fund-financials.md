# Exact printed infrastructure-fund current categories

This follow-up is separate from the frozen 225 HTML financial-source release. It adds only MKIF own 2023, 2024 and 2025 audits and KBIF own 2024 and 2025 audits. MKIF 2021/2022 scans are excluded. These are single-fund, own twelve-month fiscal periods, not consolidated/separate industrial-company financials or regular DART API reports.

Each source has eight selected current printed categories: assets, liabilities, equity, fund operating income, net profit, asset-management cash flow, loan acquisition and equity acquisition. The last two keep the original positive printed amounts with a distinct outflow direction. No synthetic XBRL identifiers, industrial CFO/PPE/revenue, FinancialReport/FinancialFact rows, TTM or stored derived metrics are created. Audit opinion remains unextracted.

The source profiles contain exact original-PDF, complete raw-text and transformed-text SHA-256 pins, issuer/period/unit, current/comparative token coordinates, equation coordinates and signs. They contain no monetary-value literals. Normal collection verifies the original PDF and full raw text before deriving any observations. Ordinary research feed import cannot submit numerical issuerFinancials. Public reads require the stored company, officialFile Source, provider and source-reference contract. Existing snapshots and Sources are immutable and repeated collection is idempotent.

## Bounded font recovery

Poppler 26.02.0 extracts the complete original PDF with `-layout -enc UTF-8` locally. Cloud only reads private `${pdfSHA}.pdf` and `${pdfSHA}.infrastructure.raw.txt`; no Python, Poppler or Docker/dependency change is required in Cloud. Prepare them locally with `tool/issuer_funds/prepare_infrastructure_private_cache.py`. The private files must be installed in the existing collector cache before normal collection can succeed. Missing or altered cache text is a failure with pending work; it is not success or no data.

At runtime the exact fixed mapping is applied only to original PDF pages 8–13 for MKIF and 9–12 for KBIF2025. KBIF2024 uses unchanged extracted text. Mapping order is U+0351–U+0371 minus 0x331, ASCII 71–126 minus 39, then code point plus 0x8ECC only when this yields a Korean syllable. Other code points are unchanged. The full transformed-text digest is independently pinned. Both original glyph lines and transformed printed lines are preserved with page/line/token coordinates.

This does **not** certify all fonts, note/footer text or complete statements. `fullStatementCollected`, `wholeFontMapVerified` and `notesDecodedOrVerified` remain false. UI makes this limit visible. Numerical BS/CF cash equality is verified; different MKIF cash labels are not declared semantically equivalent. No cash-scope reinterpretation or correction is performed.

## Independent evidence and checks

The independent Python proof reads the five original PDFs, then checks 40 selected current cells, 109 BS/PL/CF subtotal and roll-forward equations, plus component sums and current roll-forward/BS/profit checks for each equity statement. Dash components remain missing witnesses; they never become zero amount facts. Current own periods and original current columns are distinct from comparative printed witnesses.

The Dart unit tests compare all selected current cells and source coordinates against the independent Python proof and reject wrong PDF/text/issuer/period/basis/unit/current coordinates/signs, source-header changes, inconsistent glyph lines, fabricated completeness, duplicate sources and mixed issuers. These tests do not prove that every printed statement row or every note has been extracted.

The Flutter tests expand all three MKIF and both KBIF periods at 320px, retain source links, original investment outflow directions and visible font/note limits, and retain previous Mapps/IPO/design checks. Normal DB regression tests are written in `test/integration/infrastructure_fund_issuer_financials_sync_test.dart` for two actual originals: public source-bound reads, idempotency, numeric-import denial, missing/altered private text recovery, cancellation and zero regular financial/API/business ledgers. They must pass through the canonical test runner before merging or deploying. They were not run while the parent owns the shared DB test slot.
