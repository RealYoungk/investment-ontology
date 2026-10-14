# Stored order fact read revalidation (2026-10-13)

DB rows and source originals remain unchanged. `StoredOrderFactProjection.revalidate(facts,text)` revalidates API order facts only. Documents without API order facts return immediately. Manual/AI facts are preserved. Source/year/company identity validation remains in the endpoint owned by the root agent.

`OrderFacts` now selects explicit money columns before quantities, retains signed backlog, rejects malformed comma grouping through `literalTableNumber`, maps delivered/revenue by its header rather than assuming the penultimate numeric cell, and includes signed FX/other changes in flow reconciliation. A missing money subheader on quantity/money mixed or six-value rows is ambiguous; it never uses the largest numeric triple. Currency units do not cross section boundaries. The existing relative tolerance is 0.5% (minimum one printed unit), explicitly stated in read projection provenance. A successful reconciliation is approximate within that tolerance, not an exact-equality claim.

Source examples:

- 영풍 doc10932 / fact380179: `-32,318` is quantity. Monetary fields 1,239,960 / 1,507,386 / 267,426 do not reconcile. The old 32,318 백만원 fact is withheld; the raw source row and explicit cash observations remain in a table marked equation-unverified. No sign or amount is guessed.
- 노루페인트 doc14834 / fact412480: 79,022 − 79,300 = −278 백만원. The historical +114 was quantity, not the money backlog. Read projection returns −278.
- 서연탑메탈 docs7889/1317/4811: FX is after 공사수익인식액. Historical delivered values 71 / 211,262 / 241,852 were FX. Correct header-selected delivered values are 94,523,059 / 166,227,395 / 79,217,927 천원. Their corresponding before-delivery totals are 160,701,446 / 291,800,197 / 200,280,486.
- STX엔진 doc361: `2024년말 + 기수주총액 − 기납품액 + 기타 = 수주잔고`; −115 is 기타, backlog is 4,645억원.
- 수산아이앤티 doc13150: total72,030 / delivered62,742 / backlog9,288 are quantity. Money fields are 4,734 / 4,171 / 563 백만원.
- 현대에버다임 doc1924: closed contract delivered17,820백만원 / backlog0. The former 24 was quantity; selecting the largest matching triple incorrectly substituted 17,820 as backlog.

## Two distinct audit cohorts

`order-projection-audit.json`: the 54 earlier `unresolvedSourceValue` findings. 34 source equations confirmed, 11 explicit Korean currency scalings confirmed (조/억원 to the already-stored unit), 8 header-selected corrections, and 1 incompatible cash-column value moved out of verified arithmetic facts. These are not 54 incorrect facts.

`order-projection-all-audit.json`: all 10,821 primary/API order facts found in the whole 108k fact snapshot corpus. This is independent of the 54 finding subset:

| Result | Facts |
|---|---:|
| Current source equation confirmed | 9,286 |
| Header-selected cash value corrected | 866 |
| Quantity/cash column correspondence ambiguous: raw only | 270 |
| Existing cash literal correct but equation fails: source observation only | 18 |
| Stored value differs from cash column and equation fails: source observation only | 189 |
| No admissible scalar/equation proof: raw source retained | 6 |
| Current parser shape unsupported: historical value retained unconfirmed | 186 |

The 213 equation/grammar failures are not all characterized as false source values. In particular, the 18 literal cash values remain visible through `OrderUnreconciledSourceTables` with explicit equation-unverified wording. These do not retain a false arithmetic-verified `DocumentFact` provenance. The 270 ambiguous rows have no monetary measures; raw source rows remain visible. Missing/unsupported evidence is not automatically rejected: the 186 historical values retain their numbers and prior approval status, with read-only `reviewedBy/reviewNote` stating that the current rule did not re-confirm the equation. They are not counted as newly validated values. All 186 evidence strings are present in their active original documents; the limitation is current parser support, not source absence. This does not by itself prove their values or money-column roles are correct.

Helpers return `BusinessTableInsight` topics `orderSourceUnreconciled` and `orderSourceAmbiguous`; they never save facts. The source-only delivered observation keeps the original parenthetical/negative sign. Root passes the actual fiscal/calendar `reportPeriod` when registering the helper.

Validation: 27 targeted tests pass, including quantity greater than money, closed zero backlog, negative backlog, FX after revenue, explicit source-only cash observations, ambiguous six-number rows, and source unit boundaries. Targeted analyze has no findings.

Run from the server package:

```sh
dart run tool/business_tables/audit_order_read_projection.dart ../tmp/business-universe-audit-2026-10-13/fact-number-audit.json ../tmp/business-universe-audit-2026-10-13/capture/corpus.jsonl ../tmp/business-universe-audit-2026-10-13/order-projection-audit.json

dart run tool/business_tables/audit_order_read_projection.dart ../tmp/business-universe-audit-2026-10-13/fact-number-audit.json ../tmp/business-universe-audit-2026-10-13/capture/corpus.jsonl ../tmp/business-universe-audit-2026-10-13/order-projection-all-audit.json ../tmp/business-universe-audit-2026-10-13/api-capture
```

The audit's selected rows and projected values are evidence artifacts, not a persisted-data repair. Public API recapture and Flutter rendering are performed after the root integrates and freezes all related helpers.

Representative unresolved shapes among the 186 (all source-present): inline quantity units such as `456 만톤` plus trailing 사업/비고 cells (E1/LS네트웍스); `$31,673,120` currency prefixes (한국비티비); rowspan/blank cells or trailing pipes (티앤엘/3S/만도/피엔티엠에스/한국지역난방공사/휴림에이텍/이엔플러스); and subsidiary/scope or unit-window constraints where the matching row alone does not establish the accepted current table context. The retained status means historical approval is preserved, not that these types have been newly supported or re-proved. Existing original HTML examples and stored plain text are used; no DART document fetch is performed to repair flattened cells.

### Final capture counterexample: missing cash markers

Fresh full-API capture was interrupted after 350 completed companies when an independent holding-company scope bug required a source change. The partial capture also found 강스템바이오텍 (`01025644`): two source-only order tables emitted six `0 원` observations from rows containing only `-`. These are missing markers, not printed numeric zero.

`OrderFactPrintedValues` now retains nullable monetary components. `-`, `—`, and explicitly selected blank monetary cells do not become scalar observations. All-missing rows remain raw source cards. A standard balance with a missing primary monetary component cannot become an arithmetic-verified order tuple; explicit numeric components remain in the source-only card. Flow-table ancillary adjustments may still use missing markers as arithmetic placeholders, while delivered/backlog missing components prevent verification. An actual printed `0` remains numeric zero. Continuation labels survive a preceding missing row.

The Gangstem all-missing, partially missing, blank, and explicit-zero counterexamples are covered by the source-table fixture test. Existing SK이터닉스 and 현대에버다임 tests now assert missing semantics rather than fabricated zero backlog. Three order test files passed 28 tests; targeted analysis reported no issues. Database rows were not mutated.

### Remaining 150 historical order facts: complete source classification

`order150-source-classification.json` independently maps all 150 facts (10 companies, 31 documents) to explicit monetary columns in the stored source. 147 values match the source monetary column; 3 한국비티비 (`01031229`, document 13083, IDs 398084–398086) instead match the quantity column and were stored with `$` unit. The source cash triple is `$31,673,120 − $4,900,803 = $26,772,317`; the old quantity triple was `19,343,200 / 386,803 / 18,956,397`. Strict parsing now accepts the dollar prefix only when the table's selected monetary unit is `$`, and the read projection corrects those three without changing persisted rows.

The 150 concrete source shapes are: mixed-currency wood-pellet tables with quantity suffixes and notes (36), a truncated final amount subheader (3), repeated summary/detailed tables (18 + 6), product versus end-user duplicate totals (24), dollar-prefixed amount pairs (3), counterparty/note cells after three cash columns (3), two quantity/amount pairs plus a single backlog and note (21), and explicit subsidiary IT-service tables (36). 135 fact components belong to exact equations; 15 have source rounding or residuals within the existing 0.5% printed-unit tolerance. A matching printed cash value remains separate from current parser support.

54 facts have explicit other-company source scope: E1's LS네트웍스 wood-pellet tables (18) and 이마트's named 신세계아이앤씨 IT-service tables (36). These are not 54 numerical errors. `ScopedOrderFactProjection` preserves the values and adds the source company's name to labels and review notes, avoiding an unqualified parent-company total. Scope comes only from an explicit nearby business heading or named order statement, or an explicit section-local `회사명(이하 “당사”)` alias. Own-company names normalize away, and a new `##` boundary ends alias scope. The old `StoredOrderFactProjection` delegates to this implementation for compatibility.

Source-only replay of the current 9,171 projected API order facts gives 9,021 source equations confirmed, 147 supported-source-mapping limitations retained with annotations, and 3 corrected dollar amounts. This cohort differs from the immutable earlier 10,821 stored-order baseline and is recorded separately in `order-all-after-dollar-scope-audit.json`. The source evidence classification resolves numeric/column meaning for the 150, while the 147 generic-parser limitations remain explicitly documented. Duplicate totals are not additive. Tests cover dollar/quantity correction, unchanged persisted objects, E1/이마트 scope, own-company scope, and section boundaries.
