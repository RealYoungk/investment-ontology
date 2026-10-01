# Exact CFS non-applicability literals

Three official annual CFS bodies contain only a heading and an explicit statement. Raw shell, cover, CFS and URL/SHA evidence are preserved under `test/fixtures/financial_html/cfs-explicit-none/`.

| Receipt | Corporate code | Cover period | Literal |
|---|---|---|---|
| 20260331001824 | 00610861 | 2025-01-01..2025-12-31 | 당사는 본 보고서 작성기준일 현재 연결대상 종속회사가 없어 해당사항이 없습니다. |
| 20260323001144 | 01293388 | 2025-01-01..2025-12-31 | 당사는 본 보고서 작성기준일 현재 해당사항 없습니다. |
| 20230622000218 | 00304915 | 2022-04-01..2023-03-31 | 당사는 보고서 작성기준일 현재 해당사항이 없습니다. |

The existing exact annual receipt/corporate shell/company/declared-period guards are unchanged. Only a full-body literal match, with one BODY and no table/script/style, produces the typed non-applicability exception. Additional conditions, references, numbers, another heading or identity conflicts reject. This is not evidence that OFS data is absent and does not convert a technical failure into noData.

The normal financial recovery integration verifies API 0 requests, source audit evidence/SHA and actual period, CFS noData, and preservation of an already stored OFS report, fact, amount and source IDs. The finite retry priority changes only these three verified CFS receipts (the existing Korea OFS entry is preserved).

No production mutation, paid API request, new endpoint, generated file or scheduling change was made.

Validation: 26 actual-literal/adversarial unit tests, 37 existing annual/attachment fetch unit tests, and 70 FinancialFactsSync integration tests passed (133 total). Targeted analyze reports no issues; format and diff checks pass; fixture raw SHA values match their proof manifests.
