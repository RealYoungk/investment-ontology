# Optional annual capex dash

Actual 안지오랩 source 01115044/20260318000962 declares OFS fiscal period 2025-01-01 through 2025-12-31 and won units. Its current 유형자산의 취득 group prints a dash and blank cell. The finite annual parser treats this as unavailable optional information, not zero or the prior-year amount. All seven mandatory core account values, source company/document/period, current column, monetary span, currency and balance guards remain required.

Skipped optional cells are recorded under unavailableOptionalAccounts in html_provenance, including printed label/current cells/table index/source URL. Normal financial ingest already stores that provenance in its Source audit. Only numeric rows are stored as FinancialFact. No capex fact is fabricated and downstream free cash flow remains unavailable.

Malformed nonblank amounts and multiple numeric current cells still fail. The actual 퓨쳐메디신 20230323001133 CFS/OFS fixtures print a dash in mandatory current 영업수익; both remain rejected. Their prior revenue 1,000,000,000 is never substituted. No six-core or inferred-zero policy is introduced.

The official shell, cover, statements, exact URLs and SHA hashes are preserved in test/fixtures/financial_html/optional-capex. This supports a bounded subset of core accounts and does not assert full-statement recovery.

The actual printed whole CIS revenue label `Ⅰ.매출액(주5)` is preserved. Its exact normalized alias `매출액(주5)` is shared by Dart account selection and SQL resolution. Costs, non-CIS rows and notes/segment details remain excluded. Regression tests verify source-normal numeric storage, company summary and screener revenue, absent capex and unavailable FCF.
