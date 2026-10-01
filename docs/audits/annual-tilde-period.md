# Explicit annual start~end title

Actual Apex00832700 receipt20260318000509 OFS publishes term29 BS2025.12.31現在 and PL/CF2025.01.01~2025.12.31. The parser now accepts ASCII ~ between two fully printed dates alongside 부터/까지. No date inference or fiscal-year relabeling. 부터 still requires까지. Exact current term/start/end, source/company/basis, units, duplicate amount groups, whole account selection, BS equality remain required.

Actual8 core rows pass. Printed names/null account IDs, original period and KRW are unchanged. Source fixture metadata preserves official URI/dcm/corp/receipt/SHA; normal Source audits already preserve raw provenance. Actual BS31486896644=22767608491+8719288153; revenue20015837872/op-522428137/net-441935211/CFO-174395793원. This is partial core, not full statement.

Unit27 pass including quarter/cumulative/partial/reversed date, bad currency/equality/company/receipt/source/basis and incomplete 부터 rejection; isolated DB1 pass actual8 facts/source provenance/summary account selection. WiworldBS duration without현재 remains rejected. Annual/interim collection budgets, scheduling, auth and numeric history unchanged. No new GET/operating writes.

Follow-up finite queue priority: verified00832700/20260318000509/OFS joins the existing receipt priority list. Priority affects order only, never resets attempts. Public recovery marker attempts must remain <3; exhausted public3 stays excluded. Legacy API attempts≥3 do not by themselves prevent remaining public attempts1/2 under the existing separate rule. Read-only live audit found APIattempt1/publicattempt1/CFSnoData/OFSfailed, so two public opportunities remain. UnverifiedCFS has no priority proof.
