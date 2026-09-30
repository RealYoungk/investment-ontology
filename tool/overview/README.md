# Listed-company overview catalog

The catalog is a **static explanation layer**, separate from live financials, prices and news. It makes every currently listed company navigable without a model call or a database migration. It is not a claim that every issuer has received bespoke research.

## Rebuild

1. Export `export.sql` against the local application database in read-only mode with `psql -At -f tool/overview/export.sql > /tmp/overview-corpus.jsonl` (use the existing connection settings; never commit passwords).
2. Run `python3 tool/overview/test_build.py`.
3. Run `python3 tool/overview/build.py /tmp/overview-corpus.jsonl`.
4. Inspect `outputs/overview-rollout/classification.tsv`, especially changed classifications, new issuers and sources with no usable introduction.
5. Run the Flutter catalog/layout tests before shipping the changed asset.

The committed asset is `investment_ontology_serverpod_flutter/assets/overview/companies.json`. The full filing corpus is deliberately not committed.

## Content contract

- `catalog.py`: reusable business-model explanations and conceptual three-stage diagrams. These are industry economics, **not issuer-specific catalysts, forecasts or recommendations**.
- `build.py`: deterministic KSIC/name classification, with narrowly scoped refinements from the issuer's first self-description. A competitor mention does not become the company's product.
- `curated.py`: company-specific summaries and multi-business cases. Every evidence phrase must exist in that company's exported filing or the build fails. Phrase matching verifies provenance, not the meaning of the authored summary; changes still need editorial inspection.
- Original Gigavis and Seongho lessons retain their richer illustration/investment-point UI.
- Short source statements are verbatim; the builder does not search later subsidiaries just to find a convenient short statement. This is particularly important for holding-company reports.
- Product labels retain their original evidence from the existing source-validated product profiles.
- All records retain document ID, receipt and fiscal year; no fixed market prices or forecasts are embedded. Refresh is explicit, not scheduled and not AI at request time.
- Companies without usable source descriptions show **업종 이해**. Newly listed companies outside the snapshot retain the existing API fallback. Their inclusion requires a rebuild.

## Financial presentation

The company header emphasizes market cap, PER, PBR and ROE for banks, insurance, securities, credit/card firms and financial holding companies. Ordinary manufacturing-style FCF, FCF yield, debt ratio and operating margin are omitted from that header; the underlying financial statements and calculations remain accessible in the financial tab. Ordinary non-financial holding companies are not swept into this rule. REITs, infrastructure investment vehicles and SPACs omit the manufacturing-style FCF pair from the header too.

Rationale: Aswath Damodaran, [Valuing Financial Service Firms](https://pages.stern.nyu.edu/~adamodar/pdfiles/valn2ed/ch21.pdf), distinguishes financial firms' debt/reinvestment from non-financial firms. This is a UI selection rule, not a new valuation model.

Other model references: [IFRS 17](https://www.ifrs.org/issued-standards/list-of-standards/ifrs-17-insurance-contracts/), [FDA drug development](https://www.fda.gov/patients/learn-about-drug-and-device-approvals/drug-development-process). Issuer facts use the exported original DART business documents, with receipts in each record.

## Known boundaries

KSIC can be broad or lag a change in business. The catalog provides an initial business-model match, not a semantic accuracy certificate for all companies. A single generic model cannot capture every conglomerate, revenue mix, research stage, acquisition or turnaround. The explicit multi-model exceptions are examples for subsequent expansion. Current news remains separate and live. Do not turn generic industry drivers into dated issuer-specific investment theses.

`coverage.json` counts data availability, not human-audited accuracy. Layout tests cover every model at 320, 768 and 1280 logical pixels and 1.3x text scale; browser evidence covers representative live pages, not all 2,756 companies.
