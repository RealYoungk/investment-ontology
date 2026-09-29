-- Read-only audit. Pass current BusinessProductRules.version as rule_version.
WITH latest AS (
 SELECT DISTINCT ON (d."companyId") d.id, d."companyId", d."bsnsYear", d."rceptNo", d.text
 FROM business_document d JOIN disclosure_report r ON r.id=d."reportId"
 JOIN company c ON c.id=d."companyId"
 WHERE r."supersededById" IS NULL AND c.market IN ('kospi','kosdaq','konex')
 AND (c."industryCode" IS NULL OR c."industryCode" <> '64992')
 ORDER BY d."companyId",d."bsnsYear" DESC,d."rceptNo" DESC,d.id DESC
)
SELECT json_build_object(
 'eligibleDocuments',count(*),
 'currentProfiles',count(*) FILTER (WHERE p."ruleVersion"=:rule_version),
 'companiesWithProducts',count(*) FILTER (WHERE p."ruleVersion"=:rule_version AND json_array_length(p.products)>0),
 'companiesWithExplanation',count(*) FILTER (WHERE p."ruleVersion"=:rule_version AND
   EXISTS (SELECT 1 FROM json_array_elements(p.products) x WHERE x->>'explanationKind'='reference_and_filing')),
 'nonVerbatimEvidence', (SELECT count(*) FROM latest a JOIN business_profile b ON b."documentId"=a.id,
   json_array_elements(b.products) x WHERE b."ruleVersion"=:rule_version AND position(x->>'evidence' IN a.text)=0)
)
FROM latest l LEFT JOIN business_profile p ON p."documentId"=l.id
WHERE l."bsnsYear">=extract(year FROM current_date)-2;
