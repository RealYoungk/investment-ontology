WITH latest AS (
 SELECT DISTINCT ON(d."companyId") d.* FROM business_document d
 JOIN disclosure_report r ON r.id=d."reportId" WHERE r."supersededById" IS NULL
 ORDER BY d."companyId",d."bsnsYear" DESC,d."rceptNo" DESC,d.id DESC
)
SELECT json_build_object('corpCode',c."corpCode",'name',c.name,'stockCode',c."stockCode",'industryCode',c."industryCode",'divisionCode',c."divisionCode",'sectionCode',c."sectionCode",'documentId',d.id,'year',d."bsnsYear",'receipt',d."rceptNo",'text',d.text,'products',p.products)
FROM company c LEFT JOIN latest d ON d."companyId"=c.id LEFT JOIN business_profile p ON p."documentId"=d.id
WHERE c.market IN ('kospi','kosdaq','konex') ORDER BY c."corpCode";
