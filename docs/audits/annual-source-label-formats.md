# Actual annual source label formats

- Hantek 20250326000042 CFS: whole primary CIS `수익(매출액)(주30)` 155,880,764,900 KRW. Only this exact printed label and its unsuffixed form are null-ID revenue aliases. Printed name remains unchanged.
- Mason 20230621000034 CFS: primary CIS `Ⅰ. 영업이익(손실)` contains `1. 영업수익` 4,315,281,301 KRW and operating expenses. This is whole operating revenue, not a component interest/fee row. Existing 영업수익 mapping is preserved; no label is rewritten to 매출액. Whole `연결당기순이익(손실)` -3,834,733,467 is added, without owner/EPS/CE/CF substitutions.
- Korea Asset 20230622000218: exact official cover `2022.04.01부터2023.03.31까지` is accepted as explicit dates. Invalid dates or mismatched expected period still fail. Its CFS body is non-applicability and OFS statement proof remains a separate check: accepting the cover does not assert complete recovery.

All five read-only diagnostic source captures are preserved under test/fixtures/financial_html/label-formats with original URLs; no existing reports, amounts, Source IDs, API noData statuses or retries are changed by this patch.
