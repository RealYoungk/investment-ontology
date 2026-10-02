# Direct net CFO after a blank section caption

Three separate annual statements for NovMetaPharma, receipts 20230317000745 (FY2022), 20240320001114 (FY2023), and 20250314001145 (FY2024), print an empty operating-cash-flow section caption and a later directly printed net cash outflow total. The parser previously tried to read the caption as an amount.

The common structural rule requires exactly one caption with all amount cells blank, exactly one later exact net-total label in the same already dated primary CF table, and complete unspanned numeric total cells. Current term, printed unit, company cover, whole balance sheet identity and mandatory core checks remain in force. No summation of components or previous-year fallback is used. The older FY2025 receipt-bound identity guard remains effective.

Pinned whole direct values (KRW):

| Fiscal year | Assets | Liabilities | Equity | Revenue | Operating profit | Net profit | Operating cash flow | Printed capex |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2022 | 3741971765 | 7979825138 | -4237853373 | 31480000 | -7455614938 | -6142413669 | -4030786230 | -29122440 |
| 2023 | 9285835747 | 3713546625 | 5572289122 | 13850728 | -7774251152 | -12555184897 | -5544572139 | -16520000 |
| 2024 | 4648526686 | 2891939029 | 1756587657 | 45315000 | -5540552457 | -5604649777 | -5117726193 | -16998764 |

The actual official shell/cover/OFS bytes and SHA-256/source coordinates are preserved in immutable source packages. Expected rows are pinned separately. Focused parser negatives and existing FY2025 identity/date/unit negatives: 22 passed. The normal admin ingest path recovered all three from both-basis-failed/public-attempt-3 with the DART budget exhausted; opposite-basis data, attempt counters and API usage remained intact, and replay created no duplicate reports/facts/audits (3 passed). Production deployment and live recovery are still pending.
