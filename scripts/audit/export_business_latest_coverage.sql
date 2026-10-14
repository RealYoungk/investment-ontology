-- Public source inventory only; execute with export_local_readonly.py.
-- Report-name printed settlement month selects periods, not receipt chronology.
WITH listed AS (
 SELECT * FROM company WHERE market IN ('kospi','kosdaq','konex') AND "stockCode" IS NOT NULL
), filings AS (
 SELECT f.*, (regexp_match(f."reportName", '\(([0-9]{4})\.([0-9]{2})\)'))[1] AS period_year,
 (regexp_match(f."reportName", '\(([0-9]{4})\.([0-9]{2})\)'))[2] AS period_month
 FROM dart_filing f JOIN listed c ON c."corpCode"=f."corpCode"
 WHERE f."reportCode" IS NOT NULL
), dated AS (
 SELECT *, CASE WHEN period_year IS NOT NULL AND period_month::int BETWEEN 1 AND 12
 THEN (make_date(period_year::int,period_month::int,1)+interval '1 month - 1 day')::date END AS actual_period
 FROM filings
), annual AS (
 SELECT DISTINCT ON ("corpCode") * FROM dated WHERE "reportCode"='annual'
 ORDER BY "corpCode",actual_period DESC NULLS LAST,"rceptNo" DESC
), interim AS (
 SELECT DISTINCT ON (f."corpCode") f.* FROM dated f LEFT JOIN annual a ON a."corpCode"=f."corpCode"
 WHERE f."reportCode"!='annual' AND f.actual_period > COALESCE(a.actual_period,DATE '1900-01-01')
 ORDER BY f."corpCode",f.actual_period DESC NULLS LAST,f."rceptNo" DESC
), eligible AS (
 SELECT 'annual' AS expected_kind,a.* FROM annual a
 UNION ALL SELECT 'newerInterim',i.* FROM interim i
), expected AS (
 SELECT c.id AS company_id,c."corpCode",c.name,c.market,e.expected_kind,e.id AS filing_id,
 e."rceptNo",e."reportName",e."bsnsYear",e."reportCode",e.actual_period
 FROM listed c LEFT JOIN eligible e ON e."corpCode"=c."corpCode"
)
SELECT json_build_object('corpCode',e."corpCode",'name',e.name,'market',e.market,
 'expectedKind',e.expected_kind,'receipt',e."rceptNo",'reportName',e."reportName",'year',e."bsnsYear",'reportCode',e."reportCode",'actualPeriod',e.actual_period,
 'status',fs.status,'attempts',fs.attempts,'lastError',fs."lastError",'fetchedAt',fs."fetchedAt",
 'stored',s.stored,'storedReceipt',s.receipt,'storedDocumentId',s.doc,'storedSettlementDate',s.settlement,
 'coverage',CASE WHEN e.filing_id IS NULL THEN 'noEligibleFilingInLedger'
  WHEN s.receipt=e."rceptNo" THEN 'exactReceiptStored'
  WHEN s.receipt IS NOT NULL AND e."reportName" LIKE '%첨부정정%' THEN 'attachmentCorrectionEarlierOriginalStored'
  WHEN s.receipt IS NOT NULL THEN 'samePeriodEarlierReceiptStored'
  WHEN fs.status='noData' THEN 'fetchedNoBusinessSection'
  WHEN fs.status='failed' THEN 'failedBusinessSection'
  WHEN fs.status IS NOT NULL THEN concat('businessSection_',fs.status)
  ELSE 'businessSectionNotScheduled' END)
FROM expected e
LEFT JOIN dart_filing_section fs ON fs."filingId"=e.filing_id AND fs.section='businessContent'
LEFT JOIN LATERAL (
 SELECT true AS stored,d.id AS doc,d."rceptNo" AS receipt,r."settlementDate" AS settlement
 FROM business_document d JOIN disclosure_report r ON r.id=d."reportId"
 JOIN source src ON src.id=r."sourceId" AND src.reference=d."rceptNo" AND src.kind='dartReport'
 LEFT JOIN dated original ON original."rceptNo"=d."rceptNo"
 WHERE d."companyId"=e.company_id AND r.section='businessContent' AND r."supersededById" IS NULL
 AND r."reportCode"=e."reportCode" AND COALESCE(r."settlementDate"::date,original.actual_period)=e.actual_period
 ORDER BY (d."rceptNo"=e."rceptNo") DESC,d."rceptNo" DESC LIMIT 1
) s ON true
ORDER BY e."corpCode",e.expected_kind;
