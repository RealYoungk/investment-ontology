# Resume after actual annual public-source storage progress

The existing annual keyless recovery scheduler used 30seconds only when fresh
unattempted work or deferred metadata remained. A retried batch could store
financial reports yet wait15minutes because every remaining item already had
an attempt. This change adds only `annualPublic.stored > 0` to that annual
30second condition, inside the unchanged remaining>0 and not-cancelled guard.

Stored means this run's actual newly stored report-basis count from normal
fetch/store. It does not infer progress from pre-existing valid bases, checked
sources, noData audits, attempt/error counters, or job processed counts.
No storage and no fresh/deferred work keeps15minutes. Cancelled/no leftover
gets no annual resume. The existing requestResume aggregator still reserves
only the earliest time, once.

Annual limits remain unchanged: at most10 periods per run, normal public1s
pace, six-consecutive-failure circuit, three-public-attempt ceiling,
cancellation checks, existing API quota and normal auth/Source paths.
Half/metadata/market scheduling is unchanged; no API request is introduced.

Isolated DB regression uses the existing real Polred statement tables with
explicitly synthetic queue identities (the independent fetcher suite binds
real official shell identity). Cases cover existing-attempt11period queue:
10 processed/20 basis reports stored with stale leftover =>30second once;
allfailed circuit6 =>15minutes once and capped3attempts eventually no request;
cancellation => no reservation, no attempt consumption. Shared DART meter is
seeded at20,000 to cover actual exhausted-budget operation: financial/global
feed calls0, original meter unchanged. After public cap3, existing next-KST
midnight API resume remains; no fast public retry is introduced. Production
writes0.
