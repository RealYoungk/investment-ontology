# 코스나인 FY2025 원문 미제시 실패 증거

이 후속은 접수20260324000091 / corp00442455 / FY2025 연결·별도 원문에만 적용한다. cover와각primary statement URL 및원문SHA,2025-01-01..12-31 날짜가모두일치해야 `KnownAnnualSourceNotPresented`로분류한다. 기본parser가다른회사·기간·basis·URL·바뀐byte를이분류로인정하지않는다.

primary BS/PL/CE/CF가 제25기당기값을공란으로인쇄한다. 감사첨부는경영진이해당재무제표를제시하지않아첨부하지않았다고인쇄했다. 감사첨부URL/SHA/quote는사전독립원문검토증거로분리하고 runtime에서다시받았다고주장하지않는다.

normal fallback에해당원문이도달하면별도 `financial-source-not-presented:<receipt>:<basis>` immutable Source(action `verified-primary-statements-not-presented`)를advisory transaction lock으로1회기록한다. 기존 Source와비교기간금액은변경하지않는다. 이분류는sourceConflict,연결작성비대상,noData,0원,완료가아니다. financial 실패와기존재시도한도는그대로남는다. 숫자보고서/금액fact를만들지않는다.

## 이번구현범위와남은작업

기존 운영ledger는attempts3의고갈건이므로normal FinancialFactsSync.run에서별도negative-evidence cache를검증한다. 활성scope의exactreceipt/corp/2025annual/failed/attempt>=3 basis만대상이다. manifest와원문6개byteSHA를모두검증하고API/HTTP호출없이분류한다. Source+실패reason갱신은advisorylock/jobrowlock/filingrowlock/최신scope재검사transaction으로원자적이다. failed상태/기존attempt수/금액/기존Source는그대로다. 반복실행은Source존재를확인하여cache읽기/추가쓰기0이다. jobmessage의분류건수만별도로명시하고updated=0을유지한다. cache누락/변조는실패상태를유지하고숫자나완료를만들지않는다.

CompanyFinancials에optional `statementAvailabilitySources: List<Source>?`를추가했다. 정상primary Serverpod watcher가생성한server/client CompanyFinancials2파일만복사했으며generated코드를직접작성하거나forcegenerate하지않았다. 공개summary는현재activefailedledger/corp/basis/receipt/period/exactURL·SHA/미제시proof와일치하는Source만전달한다. UI는2025해당basis원문미제시와수집실패유지를설명하고공식재무제표·감사첨부링크/immutableJSON을제공한다. 320px에서도안내와출처를검증한다. unknown/foreign/sourceConflict/noData/전체검증claim을미제시Source로인정하지않는다.

Generated2파일과.spy의primary동일SHA는외부영구artifact generated-company-financials-provenance.json에보존했다. server/client 각각nonempty/empty/nullSources실제JSONroundtrip검증을수행했다. DB회귀의정상worker→비로그인summary→failedSources/숫자0검사는작성만했으며아직실행하지않았다. 이후속의운영배포나Sourceclassification실행을완료했다고주장하지않는다.

순수원문/cache검증5 PASS,기존sourceConflict순수10 PASS(통합12 PASS에서새2포함). normalAPI0실패감사Source idempotency/opposite보고서·Source·금액불변/attemptcap회귀4cases(normalfallback2+고갈분류·stale-scope2)는작성만했고DB실행하지않았다. 실제원문5fixture와negative-runtime-cache6원문은cover/CFS/OFS 및사전독립감사본문2개,HTTPshell이아니다.
