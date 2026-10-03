# Curachem FY2023 own OFS: current seven, explicit own restatement chain

Receipt 20240306000708, corporation 01205514, statement SHA 65e7498523d663f364a989637fd90ea092f72c727580d89d15bda93c129673be. Current FY2023 is column 3 of ascending 2021/2022/2023 headers. Its own cover and BS/CIS/CE/CF dates and four won units are pinned. Only seven direct current rows are imported: A 14,574,281,323; L 5,756,258,642; E 8,818,022,681; revenue 6,884,433,210; OP 961,059,995; whole NI 714,973,677; CFO -101,930,996 won. PPE acquisition total remains absent, and no component sum or eighth fact is inserted.

The prior BS printed closing equity 7,706,474,644 differs from current CE opening 8,103,049,004. The source actually prints two `회계변경효과` whole-column cells: +652,793,591 at CE row 5 and -256,219,231 at row 8. The exact source guard checks the entire printed chain:

- Original 2022 CE opening + first accounting change = printed modified opening.
- Original 2022 CE NI + second accounting change = printed modified NI.
- Modified opening + modified NI = printed 2022 closing = actual current 2023 opening.
- Prior BS closing = original 2022 CE opening + original CE NI.
- Prior BS closing + both actual accounting changes = current CE opening.

The 396,574,360 difference is calculated only as diagnostic evidence. No adjustment cell is inferred, no prior fact is rewritten, and no current Source receipt/year is changed. Current whole BS, NI/CE/CF, equity roll, cash activity/roll and current/prior cash checks are exact. Independent physical current-component evidence is bundled in `independent-current-proof.json`.

The raw comparative BS itself retains an A-L-E residual of 396,574,360, because its asset column incorporates the restatement while its equity column does not. This inconsistency is preserved in `ownPrintedRestatement.comparativeBalanceResidualWon`; comparative amounts are not imported or approved. Current BS `결손금` details print positive magnitude 481,982,319 while CE retains negative retained earnings. The diagnostic component equation subtracts the explicit deficit magnitude, but no detail amount is sign-transformed into a fact. Full statement, detail-row collection and note scope remain false.

Seven normal source-cache unit tests pass. Public-read integration is written but not run under the parent's occupied DB slot. The earlier two written DB tests are corrected to the actual endpoint contract: exactly seven summary lines and no capex line. No fact with a synthetic ID is added. Flutter's existing metric reader treats the absent line as null, displays the missing-account reason, and leaves capex/FCF null. Three actual receipt/value contracts are covered by the new Flutter test. Browser production validation remains pending.
