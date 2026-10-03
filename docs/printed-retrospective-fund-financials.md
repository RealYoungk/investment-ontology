# KBIF corrected retrospective source

This source is the official issuer's **2024-11-15 corrected prospectus**, not an
original own-year audit report. PDF SHA-256:
`f156281de6902b32ca7773eaad4cb5ba3b03869cffea9edba81371cb7f9f7e8a`.
Its first page supplies the correction date. Physical pages265–269 supply the
issuer, printed audited fiscal terms and detailed financial tables. Those pages
were text-read and visually inspected; other pages, notes and the entire original
audit documents were not reviewed. Local download time is not claimed; the
manifest records the actual local verification time separately.

The metadata period2021-07-01 to2023-12-31 describes the range of historical
tables in this source, **not one fiscal duration**. Numerical rows have their own
printed periods, separate from source publication:

| Printed term | Own fiscal period | Selected categories | Verification scope |
| --- | --- | --- | --- |
|35|2023-01-01 to2023-12-31|6|24 fully numeric equations;7 partial missing-witness subtotals|
|34|2022-07-01 to2022-12-31|6|21 fully numeric equations;10 partial missing-witness subtotals|

Categories are assets, liabilities, equity, fund operating income, net profit and
asset-management cash flow. Neither fiscal duration is synthesized. Six-month
own fiscal years remain distinct from historical interim reports. There is no
revenue, industrial CFO, acquisition, XBRL, regular financial report or TTM
mapping. EPS, share counts, prices, notes and the unaudited2024 interim values
are not amount facts. Blank/dash terms participate only as explicit missing
non-amount witnesses; partial subtotal differences must not be presented as
fully numeric accounting equalities or missing values as zero amounts.

31 checks per published group cover the printed BS/PL/CF groups and roll,
current CE component sums/rolls and CE-to-BS/PL crosschecks. They are source
validation, not stored financial metrics. Printed tokens and exact physical
page/line/character-span/column coordinates are compiled directly from immutable
full `pdftotext -layout` output. The worker verifies both original PDF and full
extracted-text SHA before parsing. The stored/public contract reconstructs the
exact source-bound row and rejects modified numbers, fields, coordinates,
publication dates, fiscal periods and missing/conflicting evidence. There is no
server-side Poppler/Python dependency or OCR installation.

## Source conflicts and unregistered periods

Twelve summary-versus-detailed table conflicts are preserved with both original
tokens and coordinates. The detailed2023 equity794,860,065,364 now satisfies BS
identity and agrees with detailed CE. That does not remove other source errors.
These categories explicitly select the detailed tables and display the source
conflicts rather than replacing or correcting the summary.

- 2022-01-01 to2022-06-30 is an own audited six-month fiscal period, but its CE
  is not provided in the reviewed financial section. Its accounts remain empty.
- 2021-07-01 to2021-12-31 is also an own audited six-month fiscal period. Its CE
  is absent and its printed CF financing-outflow components differ from printed
  total by3,672,767,716won. Physical269lines10–14 visibly print both repeated
  3,672,767,716 components. The CF is quarantined; no component is deleted,
  repaired or guessed, and no amounts are published as this period's categories.
- 2021H1 is not supplied in this section. Absence from this reviewed section is
  not a claim that an original audit filing is legally absent or unavailable.

The Source descriptor distinguishes original own audit documents from the one
retrospective prospectus. It records two excluded fiscal periods and one CF
quarantine, deduplicated across the two published rows. The normal worker returns
two stored category groups and separately counts the excluded CF quarantine;
it never subtracts that excluded period from already stored groups or changes
regular-report completion ledgers. `fullStatementCollected`, full-document,
notes, standalone-own-audit and TTM flags stay false.

## Reproducibility and verification

`python3 tool/issuer_funds/compile_kbif_retrospective.py` reads the exact committed
original PDF/text fixtures and emits source profiles/manifest metadata. It
preserves an existing verification timestamp. The independent audit ledger is
used to bind source-conflict evidence, while runtime amounts are parsed from
printed tokens; no free-form numerical input or external numeric import is
allowed. The public metadata permits this **single exact officialIR prospectus**
with all fields and proof pinned, not arbitrary officialIR prospectuses. Existing
Generic6 blocked issuers and regular source contracts remain unchanged.

Backend pure tests independently compare12 selected cells to the earlier
physical-page ledger, reject original/text/metadata/numeric/coordinate/false
completeness mutations, and require both private cache files. UI tests show
existingKB2024/25 plus the two retrospective groups at320px, expand source
conflicts, and reject changed public contracts. Four normal-worker DB tests are
written for actual PDF success/idempotence/public-read/import-block,
missing/altered-text recovery and cancellation, with regular ledgers untouched.
Those DB tests require the separately coordinated DB gate; writing/analyzing
them is not a claim that they passed or production was deployed.
