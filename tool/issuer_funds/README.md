# Own fund PDF extraction proof

`extract_mapps.py` reads six exact official Mapps Realty audit PDFs already
pinned in `verified_fund_documents.json`: FY2021–2025 and the fund's own
January–June 2026 fiscal year. The last document is not relabeled as a DART
half-year filing. It requires Poppler's `pdftotext` on PATH.

```sh
python3 tool/issuer_funds/extract_mapps.py /absolute/path/audit.pdf --output /absolute/path/proof.json
python3 -m unittest discover -s tool/issuer_funds/tests
```

This is a read-only extraction proof. It does not call an API, write a database,
or complete cloud ingestion. Output keeps seven actual printed fund categories,
their signs, current and comparative cells, source byte hash, statement headers,
and original PDF page and extracted-line coordinates. It does not map fund
operating income to industrial revenue, asset-management cash flow to industrial
CFO, or investment-property acquisition to PPE. A printed dash stays missing.

Each document must satisfy six exact BS, equity and cash-flow checks. Equity
component totals are also checked. The 2021 and 2022 audits retain
`pendingCashScope`: their cash-flow cash conflicts with balance-sheet cash
equivalents in at least one column, despite a note defining them as equivalent.
The separately printed cash-and-deposits subtotal is recorded as a witness,
never substituted as a universal cash definition. No rounding allowance,
invented sign, or automatic posting resolves these contradictions.

Tests use excerpts of the five actual primary-statement pages from each PDF,
not complete reports. Fixture page coordinates refer to those excerpts; only
the CLI running against the complete pinned PDF returns original PDF page
coordinates. Notes are read from the complete PDF when running the CLI.
Validation of the six actual source PDFs produced 42 directly printed current
cells and 36 exact checks with zero differences. Two documents remain
quarantined for cash scope; none is claimed to be a complete statement dataset.

The initial equity-component tamper test exposed a missing component check.
That check was added and the corrected ten-test suite passed. Production
worker integration, persisted Source provenance, UI and remaining fund formats
still require separate implementation and verification.
