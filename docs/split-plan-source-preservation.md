# Delegated split-company source preservation

NeoView (02038566) and Hanwha Machinery & Services Holdings (02042949) have
parent-submitted split securities registration statements. Neither filing is
an own-company annual financial report. The complete HTML bodies were retrieved
and their exact bytes are pinned; text review here covers the filer identity and
the section stating that the parent submits for the proposed split entity.
Full financial statements, notes and historical comparative tables are not
numerically extracted or marked complete.

| Target | Actual submitting parent | KIND receipt | Complete body bytes |
|---|---|---|---:|
| NeoView 02038566 | Tovis 00390365 | 20260421001384 | 3,344,163 |
| Hanwha M&S 02042949 | Hanwha 00160588 | 20260514003206 | 14,500,668 |

`SplitPlanDocuments` contains only these exact HTTPS URIs, SHA256s, lengths,
printed parent/target names and delegation quotes. It accepts one exact compiled
row and rejects changed fields, unrelated issuers, amounts and additional URLs.
`IssuerDocumentsCollector.ensureSplit` preserves the 20 MiB/no redirect/exact
response URI/whole-byte SHA boundary. Existing own-company DART shell actor guards
are unchanged. Compressed test fixtures expand to the actual complete bodies.
No public original-file mirror is created; the public response contains links only.

The existing normal scheduled business worker calls `SplitPlanDocumentsSync`.
It validates both current company master Source URLs/references and normalized
names, plus target establishment date, before collecting or storing. Separate
split-document counts and errors appear in its existing job message; financial
period/fact/API counts are not changed. Company-scoped failure does not prevent
the other split source from collecting. Cancellation prevents subsequent writes.
Startup eligibility checks the exact snapshot/Source and private cache SHA,
then schedules through the existing normal business job; no GET runs at startup
or during a public read. The separate kind is `splitPlanDocuments`, stored by the
internal worker only. Existing `research.data` returns it publicly after exact
source binding; `importFeed` rejects it even for an administrator.

The planned split dates (July 1 and August 1, 2026) are distinct from current DART
company-master establishment dates (July 1 and August 3). The latter were observed
in existing primary Source records retrieved September 17, 2026, not a fresh API
fetch. Source IDs 2728/2552 were checked read-only for the targets and 2658/2453 for
the parents; IDs are not hard-coded in runtime. Original body metadata preserves
profile URLs and retrieval timestamps. Legal reporting-duty exemption and total
five-year source absence remain unconfirmed. Pre-incorporation parent/segment
comparatives are never substituted for the target's own annual history.

Both complete HTML files must be available in the private persistent cache under
`<SHA256>.html` or retrieved through the normal fixed-source collector. Deployment
must verify file SHA, owner and private permissions as for other issuer sources.
Missing/corrupt cache is pending/failed, not a falsely completed source.

Validation in this branch: exact whole-body pure guards, metadata mutations and
320px UI tests. Isolated integration tests are written for normal storage,
replay, anonymous read, denied manual mutation, corrupt-first-source continuation,
master Source mismatch, cancellation, private-cache disappearance and zero changes
to regular ledgers. They require the parent's exclusive DB slot before execution.
