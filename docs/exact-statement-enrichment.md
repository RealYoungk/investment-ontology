# Exact current statement enrichment

This optional normal-worker extension is limited to the nine independently verified source/basis profiles below. It does not widen the most recent five annual years and latest interim scope. Counts are individual directly printed current monetary coordinates, including individual CE components, rather than economically distinct account names.

| Source receipt | Issuer / FY / basis | Additional monetary coordinates | Local normal DB verification |
|---|---|---:|---|
| 20250320000036 | Aone2024 OFS | 116 | Passed |
| 20230321000015 | Aone2022 OFS | 115 | Passed |
| 20220310001159 | SamsungFire2021 CFS | 204 | Passed |
| 20220310001159 | SamsungFire2021 OFS | 174 | Passed |
| 20240320001114 | NovMetaPharma2023 OFS | 103 | Not run; parent owns DB slot |
| 20250314001145 | NovMetaPharma2024 OFS | 91 | Not run; parent owns DB slot |
| 20250321000964 | TheContentsOn2024 OFS | 166 | Not run; parent owns DB slot |
| 20250321001653 | LukenTechnologies2024 CFS | 105 | Not run; parent owns DB slot |
| 20250321001825 | Redwoods2024 OFS (printed 뿌리깊은나무들) | 94 | Not run; parent owns DB slot |

The first four contain609 additional coordinates. The next five contain559, for1168 across nine source/basis profiles. Each retains its existing own eight core facts. This is not all financial collection completion, whole statements for all periods, notes, attachments, or an entire filing. All enrichment Source payloads retain `fullStatementCollected:false`, `allStatementRowsVerified:false`, and `notesCollected:false`. Original partial-core notices remain valid.

The existing strict annual source verifier binds issuer, original receipt, year, basis, printed current dates, official URI and immutable package SHA. An additional exact body SHA and physical table/current-row/current-column mapping is compiled for each profile. Amount literals are not compiled into eligibility. Labels, printed headers, raw rows, cells, units, component header paths and source coordinates remain in the immutable Source ledger. XBRL IDs remain null. EPS rows keep their original raw text in the nonmonetary ledger and never become KRW facts. Dashes and blank/unprinted cells remain null; a diagnostic equation cannot turn them into known zero.

CE opening and closing cells retain the actually printed point dates. Movements carry the actual annual interval. The new Luken CFS body has three one-cell section-label rows at exact coordinates(5,22),(5,24),(5,28); these retain a structural-label-only ledger record without invented monetary columns. Header text from independent HTMLParser and the existing Dart HTML stripper is compared without HTML BR whitespace for header words only; amount cells and physical columns are compared exactly.

The five new bodies were independently read from the actual cached bytes with Python HTMLParser. The fixture `next-five-current-row-proofs.json` preserves all selected current row/cell witnesses, original eight rows, units, URIs/SHA, EPS and290 source-coordinate hierarchy diagnostics. There are269 printed numeric identities and21 all-blank/dash diagnostics, explicitly distinguished. BS hierarchies and individual capital components, PL profit/subtotal chains, current CE row/component rollforwards, CF subgroup/adjustment/investing/financing/cash rolls and same-basis BS/CE/CF/whole-NI cross-checks all have zero residual among the printed numeric terms. The terms and omitted printed nulls remain inspectable; zero residual does not assert an amount for those nulls.

The worker's dedicated enrichment phase queries only approved receipt/basis profiles already stored and active in financial scope. It retains the job, filing, period and report locks. Original core facts, their immutable Source, report source and correction lineage are not overwritten. A new immutable enrichment Source owns only additional facts. A transaction verifies all mapped facts or rolls back. Physical ord is emitted as the DART string contract accepted by FinancialRows; all appended ord values remain nonnull and unique within their report. Real duplicate labels/amounts at different printed coordinates are retained. Replays verify exact coordinates and append zero; cancellation, core conflict or a newer final filing prevent additions. No general parser, basis or sign tolerance is added.

## Source exclusions retained

- Aone2021 CE table11,row17,col3 prints `2,108,790,91`. It remains null rather than reconstructed from the opposite component. Aone2023 investing CF subtotal differs from its printed current leaves by900,000won. Neither receives detail eligibility; exact evidence remains in `aone-blocked-current-expansion.json`.
- TheContentsOn2025 CIS table3,row35,col1 prints `(주석18)` in the current monetary cell. Omitting this invalid cell from the printed SG&A summands leaves333,333won. That residual is diagnostic, never an inferred fact and never replaced by a prior amount.
- Luken2024 OFS CF table7,row33 labels1,000,000,000won as 유상증자 while its own current CE table5,row24,col5 prints999,996,000won:4,000won difference. Its current CF 차입/상환 label arrangement is also retained. CFS values are not transplanted to repair OFS. Only independently consistent CFS is added.
- MoneyMove2023/2024 print the operating-loss magnitude as positive. Existing core sign normalization is a separate contract; these sources are not admitted to literal-current-row enrichment. The2024 body's prior CE total also has a26,070won discrepancy; it remains out-of-scope prior evidence.
- IKSemicon2024 has an independently verified seven-core contract. It remains outside this eight-core append extension; the printed PPE increase cell does not authorize inventing an eighth metric or broadening the generic parser.

Exact original body URI/SHA and raw coordinates for these additional exclusions remain in `next-current-row-exclusions.json`. Bukuk rounding/cash scope conflicts, RookRak sign/whole-NI conflicts, Plumline cash conflicts and unapproved generic partial-six sources are also not authorized by this change.

## Verification and release state

The original four profiles passed16 actual DB scenarios plus a real simultaneous SamsungFire CFS/OFS test:212/182 total facts,378 additions, independent Source bodies, unchanged original16 core facts, API0 and successful replay0. The replay status assertion exposed and repaired an integer-ord adapter mismatch. Existing tests now require replay `succeeded`, not merely unchanged rows.

For the next five, pure verification passed37 tests:16 new source/identity/exclusion cases,18 original exact-source regressions and3 normal generated-registration tests. The final exclusion case was strengthened to verify actual source bytes/digests and preserved failures. Twenty new normal-worker DB scenarios are written into the existing integration matrix:normal/idempotent,cancelled,core-conflict,newer-final for each new profile. Those20 have not been executed while the parent runs the full release gate. No new production append or completion claim follows from these pure tests.

No data model or generated file changes are included in the next-five extension. The optional report-detail `sources` DTO was already normally generated for the preceding cohort; it remains unchanged. Existing canonical core summaries remain on their original source.
