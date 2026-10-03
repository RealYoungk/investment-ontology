# Fund sources outside the DART regular-report body pipeline

On 2026-10-03, the two unresolved official fund sites were inspected live, after independent built-in web and Exa searches. Search extraction was stale/incomplete: Mirae's root page only opens its actual main page, and KB's list is populated by its documented read-only list.ajax request. Actual current listing parameters and original PDF bodies were inspected, rather than treating a failed search extraction as absence.

Original bytes, SHA-256, URLs, extracted text, official listing pages and period-verification state are preserved in the user's workspace at `outputs/filing-collection-priority/fund-official-source-20261003/retrieval-ledger.json`.

- Mirae Maps Realty: official FY2021–FY2025 audit bodies, the FY2026 first-half audit body, and 2026Q2 asset-management body retrieved. Current audit covers directly name both current Maps Realty and former Asia Pacific fund. The FY2026 auditor explicitly states the accounting period changed from 12 to 6 months; this period must not be represented as a 12-month annual value or compared as equivalent duration.
- KB Balhae Infrastructure: official FY2024/FY2025 audit bodies and 2026Q2 asset-management body retrieved. FY2025 PDF cover visually confirms 2025-01-01 through 2025-12-31 and company identity. Its text layer has a corrupt font mapping; text extraction length is not successful numeric validation. FY2021–FY2023 coverage is still unresolved.
- Macquarie Infrastructure: 2026Q2 official asset-management body was previously retrieved and remains preserved in the separate non-financial audit directory.

These are separate document types. No fund PDF was injected as a DART annual filing, no stored DART failure was cleared, no report amount inferred, and no production write made. Automated ingestion/financial validation for these alternative documents remains unfinished. Raw retrieval is distinct from all-table numeric validation and production coverage.
