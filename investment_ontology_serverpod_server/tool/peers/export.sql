-- Read-only audit input. Pass -v rule_version=<PeerRules.version>.
SELECT json_agg(x) FROM (
 SELECT c."corpCode", c.name, c."industryCode", p.signals
 FROM (
  SELECT DISTINCT ON (d."companyId") d.*
  FROM business_document d JOIN disclosure_report r ON r.id=d."reportId"
  WHERE r."supersededById" IS NULL
  ORDER BY d."companyId", d."bsnsYear" DESC, d."rceptNo" DESC, d.id DESC
 ) d
 JOIN company c ON c.id=d."companyId"
 JOIN peer_profile p ON p."documentId"=d.id
 WHERE p."ruleVersion"=:'rule_version' AND d."bsnsYear">=EXTRACT(YEAR FROM CURRENT_DATE)-2
 AND c.market IN ('kospi','kosdaq','konex') AND COALESCE(c."industryCode",'')<>'64992'
 AND json_array_length(p.signals)>0
) x;
