-- Shared public-source data only. The caller enforces a read-only transaction.
-- Export existing documents; this does not collect or widen the collection scope.
SELECT json_build_object(
  'documentId',d.id,'corpCode',c."corpCode",'name',c.name,
  'stockCode',c."stockCode",'market',c.market,'industryCode',c."industryCode",
  'year',d."bsnsYear",'text',d.text,'receipt',d."rceptNo",
  'reportCode',r."reportCode",'role',CASE WHEN r."reportCode"='annual' THEN 'annual' ELSE 'interim' END,
  'reportPeriod',concat(d."bsnsYear",' ',CASE r."reportCode" WHEN 'annual' THEN '연간' WHEN 'halfYear' THEN '반기' WHEN 'q1' THEN '1분기' ELSE '3분기 누적' END),
  'settlementDate',r."settlementDate",'source',json_build_object('id',s.id,'kind',s.kind,'reference',s.reference,'url',s.url),
  'sourceChars',length(d.text))
FROM business_document d
JOIN company c ON c.id=d."companyId"
JOIN disclosure_report r ON r.id=d."reportId" AND r."companyId"=c.id AND r."rceptNo"=d."rceptNo" AND r."bsnsYear"=d."bsnsYear"
JOIN source s ON s.id=r."sourceId" AND s.reference=d."rceptNo"
WHERE c.market IN ('kospi','kosdaq','konex') AND c."stockCode" IS NOT NULL
  AND r."supersededById" IS NULL AND s.kind='dartReport'
ORDER BY c."corpCode",d."bsnsYear" DESC,d."rceptNo" DESC;
