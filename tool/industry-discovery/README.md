# 전체 상장사 분류 점검

`fetch_census.py --output /tmp/industry-census-NEW` reads the existing public local
Serverpod API with two concurrent requests. A new directory fixes a new universe
snapshot. `--resume` continues that same snapshot after a fetch error. It does not
collect new filings, write database data, or invoke AI.

`python3 tool/industry-discovery/build_census.py --snapshot /tmp/industry-census-NEW/snapshot.json --corpus /tmp/industry-census-NEW/corpus.json --output outputs/industry-discovery/census`

The builder asserts that every listed issuer has exactly one source result and
emits all companies, every current activity evidence, missing classifications,
and counts. Verbatim evidence and classification presence do **not** establish
semantic accuracy, business completeness, or manual review of every filing.
Source texts are kept outside git. CSV and report outputs contain public filing
evidence only. Table keyword matching was rejected after whole-corpus inspection
found subsidiary attribution, merged-cell shifts and discontinued products.
