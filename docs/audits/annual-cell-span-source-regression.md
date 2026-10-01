# Existing CE exclusion handles two recorded span failures

Exact official source fixtures:
- Medizencare corp01023822 receipt20250321001022, annual2024-01-01..12-31 OFS.
- DuchemBio corp00867034 receipt20240322000131, annual2023-01-01..12-31 OFS.

The former recorded Unsupported cell span errors refer to CE tables (colspan7 and colspan10). On baseline590be688 both exact sources already parse. The dated CE pre-grid exclusion recognizes the current term and excludes the equity-change table; prior terms are not matched by the current-term title regex. No parser, source identity or numeric guard modification is necessary.

Actual 6 pure-parser tests and 2 isolated normal-ingest DB regressions pass: exact current core amounts stored with null fabricated account IDs, source raw cell provenance and summary availability; wrong current dates and excessive core-table spans reject. Medizencare optional capex dash remains unavailable, not zero. Eight official read-only GET requests; no OpenDART API or production mutation. Raw shell/cover/CFS/OFS SHA and URLs are in fixture proof manifests.

These two periods can be retried under the current parser (OFS), after normal receipt/company/period guards. Passing these fixtures does not prove all ten historical span failures or all statement accounts are recovered.
