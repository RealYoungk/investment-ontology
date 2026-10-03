# Own annual primary financial observations

The internal normal business-document worker stores `issuerAnnualFinancials`
ResearchSnapshots independently of current IPO observations and regular DART API
FinancialReports/Facts. Existing public `research.data` reads only stored,
source-validated snapshots; even admin import is blocked for this numeric kind.
No new endpoint, generated model, migration or paid extractor is introduced.

Twenty source-specific profiles produce 156 directly printed current-period
cells for five issuers. Every profile pins the own receipt, immutable body/shell
URI/SHA, official issuer, annual cover dates, BS/IS/CF context including printed
won unit, exact headers/current cell coordinates/row labels and row length.
All 20 current balance sheets pass assets = liabilities + equity. Comparatives
are not extracted and not substituted for missing own reports.

GlobalTechnology's 2021–23 own audits and NeoSapiens's 2024 own audit retain
Korean-GAAP; later KIFRS comparative restatements do not overwrite them. Other
sources retain their own printed KIFRS basis. Each observation includes the
independent own audit opinion's exact official node URL/SHA, independently read
in the raw proof ledger. `audited` records document assurance type, not an
inference that every audit opinion is unqualified. Complete notes are unread.

SkyLabs 2021/22 prints PPE acquisition amounts positively inside its explicit
cash-outflow section. The positive printed amount is preserved with
positiveOutflowMagnitude and outflow metadata. The four GAAP sources have only
component PPE acquisition lines, so the missing total cell stays unextracted.
No invented zero or manually summed total is provided.

The source-bound normal worker stores whole company annual groups atomically,
checks company identity, resumes on missing/different observations or cache,
isolates annual failures from IPO failures, reports separate annual counts, and
preserves cancellation/regular report ledgers. Replay retains unchanged immutable
snapshots. The company financial tab presents a separate annual panel, five-year
own-source coverage, accounting standard, direct source and audit-opinion links,
and explicit partial/full/TTM limits. Fields from these sources do not enter
screening or valuation metrics.

Validation: all 156 actual cells and 20 balance equations, source counterpart/
SHA/period/accounting-standard/audit-opinion/coordinate mutations, positive cash
magnitude and non-synthesis cases. All five company panels and existing Brils/
IPO panels pass 320px widget checks. The integration test exercises the normal
25-document worker, public reads, 20 annual groups/156 cells, 8 current IPO groups,
replay with zero additional GETs, cancellation, counterpart binding rejection,
admin import denial and no regular ledger/API usage writes. It must run only
when the shared isolated DB slot is free.
