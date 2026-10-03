# Eight IPO issuers: source-bound current financial observations

This extension uses the eight already compiled and privately preserved financial chapters. Each company has a separate immutable URI/SHA, issuer shell, caption/header/cell profile and actual printed period. Monetary values are extracted at runtime from detailed primary statements. The production profiles contain positions, labels, period/unit context and auditor cells, never monetary literal values. The existing business worker and startup pending check collect these separate `issuerFinancials` snapshots; public `research.data` only reads stored validated observations. No regular `DartFiling`, `FinancialReport`, `FinancialFact`, XBRL ID or API usage is manufactured, and no TTM/screener adapter is installed.

| Company | Corporate code | Current basis groups | Printed current opinion | Direct cells | Period |
| --- | --- | --- | --- | --- | --- |
| 글로벌테크놀로지 | 01564514 | OFS | Not stated in read chapter | 8 | 2026-01-01–06-30 |
| 스카이랩스 | 01586923 | OFS | 태성회계법인(검토) | 8 | 2026-01-01–06-30 |
| 빅웨이브로보틱스 | 01722066 | CFS and OFS | 이정회계법인(검토) | 16 | 2026-01-01–06-30 |
| 와이즈플래닛컴퍼니 | 01867688 | CFS and OFS | 삼도회계법인(적정), as printed | 16 | 2026-01-01–06-30 |
| 네오사피엔스 | 01876251 | CFS and OFS | 삼정회계법인, 검토 | 16 | 2026-01-01–06-30 |
| 한국제17호기업인수목적 | 02029258 | OFS | Current opinion not stated | 6 | 2026-05-08–06-30 |
| 엔에이치기업인수목적34호 | 02030166 | OFS | 서우회계법인(적정), as printed | 6 | 2026-05-06–06-30 |
| 케이비제34호기업인수목적 | 02032155 | OFS | Body explicitly says reviewed | 6 | 2026-05-26–06-30 |

Eleven current basis groups have 82 directly printed core cells and eleven exact balance equations. BigWave summaries print thousand-won, but the detailed primary statements print won; only the latter cells are used. SPAC periods are since incorporation, not six full months. Their dash revenue and absent primary PPE acquisition cells remain explicitly unextracted, never zero. Korea17 prints operating/net loss magnitudes as positive integers; `incomeDirection: lossMagnitude` preserves that meaning separately from the unchanged printed sign. No comparative period is presented as a company's own annual document. The per-document current opinions above are not inferred from incorporation-date opinions or prior-year opinions.

Every amount retains label, literal, integer, statement/scope/direction and exact raw table/row/column/header/row proof. Colspan layouts use individually bound raw cell coordinates; header and amount rows can have different raw cell counts. The original financial chapter remains partial, not a whole original report. Full statements/notes, five-year own annual coverage and numerical fund extraction remain incomplete. Existing issuerDocuments remain link-only, numericState notExtracted; this numerical layer has separate partialCore state.

Tests read actual immutable shell/chapter fixtures, check all 82 independently inspected printed proof cells, exact source and basis differences, detailed won versus rounded summary values, incorporation dates, loss magnitude and missing accounts. Counterpart bytes, company/source/basis/period/currency/report-code/current-column/direction/scope mutations fail closed. UI pins the exact twelve approved chapter URIs and checksums across the nine supported corporations, labels opinion/period differences, preserves printed values and links each source separately. Browser deployment/normal worker database verification remain separate gates.
