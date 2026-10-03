# Immutable official metadata fixtures

These are byte-for-byte copies of previously retrieved DART original files from primary outputs/filing-collection-priority/titleperiod-fourth-ten-cfs-readonly/20260709000400/ (shell.html and cover.html). No new network retrieval or document edits occurred. This fixture proves only actor/report-family/printed period metadata, not financial amounts or full original verification.

- Shell: https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260709000400
- Cover: https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=1&offset=951&length=4480&dtd=dart4.xsd

provenance.json records each raw byte SHA and independently computed combined digest. PublicFinancialPeriodMetadata.fetch calculates SHA256(shell + newline + cover), so raw cover SHA differs from that metadata digest. The test independently executes the actual provider on these bytes; it does not copy business metadata or equate a cover digest with a financial body digest. Existing DB-test amount placeholders in the bounds-only file are explicitly counterfactual/unverified and never approved or imported by the provider.
