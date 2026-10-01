# Full-dated annual BS duration with independent CE proof

This rule supports an annual balance-sheet title printed as the full annual
from/to interval instead of an instant title. It does not annualize values or
infer a duration from year-only headers. Inclusive cover duration must be
365/366 days; this rule does not broaden short-period annual support.

Every matched current title must contain the cover term and exact declared
start/end. BS/CIS/CF each require their local full date title, explicit unit,
and unique same-term current money column. `YYYY연도(제N기)` is an exact printed
header alternative to `YYYY년도(제N기)`.

An independently scoped CE table must have one explicit current interval,
flat whole-total header, one actual opening and closing date in order, and one
current profit row between them. Printed CE closing equity equals BS equity;
printed CE profit equals CIS profit. All seven mandatory whole accounts and
Assets = Liabilities + Equity remain required. No component addition,
subsidiary table, arbitrary note, missing amount, or prior column substitution
is permitted. Supporting dates/totals/source/unit enter html_provenance and
normal Source audit without changing printed account names or inventing IDs.

Fixtures preserve official URLs and original SHA in proof.json:
- Bioten 01352575 / 20250318000596 / OFS / 2024-01-01..2024-12-31.
- EMT 00925967 / 20260320001385 / OFS / 2025-01-01..2025-12-31.

EMT's two whole-CIS labels `영업손익(손실)` and `당기순손익(손실)` map exactly
in both Dart and generated SQL fallback logic. Printed positive/negative
signs are retained; pure-loss guards are unchanged. Segment, owner,
discontinued-operation, notes and non-CIS names do not match these aliases.

Actual rejection sources remain unmodified:
- Curachem 20260309001820: cover/current term conflict.
- Rootloc 20250321000725: cover term mismatch and CE closing discrepancy.
- Logismon 20250318000780: reversed CF current duration.
- Daejoo ENT 20250407004206: missing fully dated primary titles and monetary
  unit discrepancy.

Source download count in this change: 0. Production database writes: 0.
Normal ingest integration uses isolated admin sessions and an embedded test
DB, checks raw rows/Source audit/summary/SQL mapping/screener using the same
actual official statement fixtures. Retrieval and source validation do not
claim full financial-statement recovery: stored rows are printed core values.
