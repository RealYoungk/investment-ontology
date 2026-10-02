# Exact historical fiscal-period cache

The Aha annual filing `20210629000260` declares 2020-04-01 through 2021-03-31. Its immutable separate-statement package preserves the official shell, cover, issuer overview and financial body with byte digests. The compiled registry entry declares those dates; current company fiscal-month metadata is not used to infer historical dates.

Registry defaults remain January through December. A nondefault entry requires both exact ISO calendar dates, the matching annual report title month, immutable manifest dates and successful original-cover/body validation. Unknown entries, another receipt/company/year/month, changed source bytes, and a higher public-attempt count remain rejected.

Validation: 16 focused immutable-package checks passed; the actual normal-ingest/replay database test passed with API budget and attempts preserved. Existing reports and facts are not rewritten. Source periods are preserved rather than scaled to a calendar year.
