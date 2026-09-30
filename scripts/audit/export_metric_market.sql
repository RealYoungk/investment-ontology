COPY (
 WITH days AS (
 SELECT s."companyId" AS id,max(m."baseDate") AS day
 FROM security s JOIN market_snapshot m ON m."securityId"=s.id GROUP BY s."companyId"
 ) SELECT json_build_object('corpCode',c."corpCode",'date',d.day,'marketCap',CASE WHEN bool_and(m."marketCap" IS NOT NULL) THEN sum(m."marketCap"::numeric)::text END,'quotes',json_agg(json_build_object('securityId',s.id,'marketCap',m."marketCap",'closePrice',m."closePrice",'listedShares',m."listedShares")))
 FROM days d JOIN company c ON c.id=d.id JOIN security s ON s."companyId"=d.id JOIN market_snapshot m ON m."securityId"=s.id AND m."baseDate"=d.day WHERE c.market IN ('kospi','kosdaq','konex') GROUP BY c."corpCode",d.day
 ) TO STDOUT;
