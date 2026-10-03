# Own annual audit source collection

Adds exactly 20 own annual statement appendices: GlobalTechnology OFS 2021–25,
SkyLabs OFS 2021–25, BigWave OFS 2023–25, WisePlanet OFS/CFS 2024–25,
NeoSapiens OFS 2024–25 and CFS 2025. Wise CFS 2024 uses its corrected 2026
submission, while the reporting period remains 2024. Global's earlier legal name
is preserved as printed; the official shell's unique corporation code binds it.

Original retrieval, saved bytes and independent audit opinion proof are in the
read-only root `outputs/filing-collection-priority/source-completeness-20261003/remaining_source_validation/ipo-history-nine`.
The reproducible `outputs/own-audit-source-validation/prepare.py` checks all 60
shell/statement/opinion hashes and own actor, cover dates and OFS/CFS markers
without network or database access. The ledger records source URLs and evidence,
not complete reading of financial notes. New provenance records fileSavedAt from
retrieved file metadata and explicitly states that exact GET completion time was
not captured. It does not invent a downloadedAt timestamp.

The normal scheduled business worker now accepts the fixed 47-source roster and
its exact approved subsets. Unpinned manifests retain the previous maximum 30.
The larger roster requires exact compiled metadata, unique URIs, bounded total
size, and at most six approved source documents per company. Existing company
iteration validates and caches all company documents before one complete company
metadata snapshot; failures are isolated by company, cancellation is checked per
document, and startup compares expected whole-company rows and cache SHA. No new
RPC, direct startup GET or manual SQL bypass is introduced. Existing fund sources
and all latest IPO sources remain present.

The public representation remains linkOnly / financialValues null /
numericState notExtracted. These 20 raw appendices do not create FinancialReport,
FinancialFact or DartFiling records and do not claim 5-year numeric completion.
Latest IPO numeric profiles are restricted to their own document type to prevent
annual appendices entering the latest-period parser. Annual numerical extraction
needs separate actual-source profiles. Missing own annual years for other issuers,
Brils 2021–22, fund gaps and split-issuer source binding remain unresolved.
