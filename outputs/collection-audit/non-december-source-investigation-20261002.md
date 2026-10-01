# Read-only investigation: non-December interim API year

2026-10-02. No API keys obtained; no API calls requiring keys; no database writes; no tracked-source edits.

## Confirmed official source evidence

OpenDART public single-company statement page says its year selector uses the year containing the final report's business-period end date:
https://opendart.fss.or.kr/disclosureinfo/fnltt/singl/main.do

The fnlttSinglAcntAll API guide only calls bsns_year a four-digit business year and does not separately explain non-December fiscal calendars:
https://opendart.fss.or.kr/guide/detail.do?apiGrpCd=DS003&apiId=2019020

The keyless public page's own list.do request demonstrates:
- SV 00599151, selectYear=2026/reportCode=11013/selectToc=0: iframe receipt20260813001312. 2027: no result.
- Teraview 01957282, same selectors year2026: iframe receipt20260923000617. 2027: no result.

Original XBRL and printed same-receipt statements agree:
- SV current 2026-04-01~2026-06-30. CFS assets94,135,633,463 KRW, OFS95,279,330,944 KRW. Context name CFY2026eFQA; instance entity00599151_2026-06-30.xbrl.
- Teraview current2026-05-01~2026-07-31. CFS assets19,915,269 GBP, OFS15,176,503 GBP. Context name CFY2026eFQA; instance entity01957282_2026-07-31.xbrl.

Our canonical fiscal-end year2027 describes these fiscal years; it is not the public query year2026. This strongly identifies conflation of canonical fiscal-year storage and request-year selection. The authenticated fnlttSinglAcntAll JSON response was not tested; exact returned receipt must still be validated before storing, particularly when trying requestYear2026 against historical canonicalFY2026 data.

## KONEX category, not an all-company conclusion

Official OpenDART regular financial data description lists KOSPI/KOSDAQ and major nonlisted IFRS filers, omitting KONEX:
https://opendart.fss.or.kr/guide/main.do?apiGrpCd=DS003

Representative annual noData receipts:
- 대동고려삼00910202 receipt20260922000230 annual2026.06: official download listing has no ifrs.do/ifrsPre.do links.
- 수프로00830447 receipt20260617000188 annual2026.03: same absence.

This supports a distinct source-unavailable-for-XBRL category; it does not prove all437 KONEX noData filings have no XBRL, and does not mean printed statements are missing. Of662 both-basis API noData filings in this audit,437 were KONEX. Broad resetting/fake completion is unjustified.

## Artifacts

/tmp/io-nondec-xbrl-evidence.json includes exact download/body URLs, SHA256, metadata/context and same-receipt printed-value checks.
/tmp/io-{SV,Teraview}-publicyear{2026,2027}.html preserve actual public year-selector result.
/tmp/io-konex-public-download-evidence.json preserves representative download listings.
