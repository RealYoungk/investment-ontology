/// Latest known regular filing, ordered by its actual reporting period first.
/// Select the filing BEFORE joining its body: an uncollected newer filing must
/// never cause an older product profile to masquerade as the current one.
abstract final class LatestBusinessReport {
  static const sql = '''
    SELECT k."companyId", k."bsnsYear", k."reportCode", k."rceptNo",
      k."reportName", d.id AS "documentId"
    FROM (
      SELECT DISTINCT ON (p."companyId") p.* FROM (
        SELECT f."companyId", f."bsnsYear", f."reportCode", f."rceptNo", f."reportName",
          coalesce(substring(f."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$'),
            f."bsnsYear"::text || '.' || CASE f."reportCode"
              WHEN 'annual' THEN '12' WHEN 'q3' THEN '09'
              WHEN 'halfYear' THEN '06' ELSE '03' END) AS actual_period
        FROM dart_filing f JOIN company c ON c.id=f."companyId" AND c."corpCode"=f."corpCode"
        WHERE f."reportCode" IN ('annual','q1','halfYear','q3') AND f."bsnsYear" IS NOT NULL
        UNION ALL
        SELECT r."companyId", r."bsnsYear", r."reportCode", r."rceptNo", f."reportName",
          coalesce(substring(f."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$'),
            to_char(r."settlementDate",'YYYY.MM'),
            r."bsnsYear"::text || '.' || CASE r."reportCode"
              WHEN 'annual' THEN '12' WHEN 'q3' THEN '09'
              WHEN 'halfYear' THEN '06' ELSE '03' END) AS actual_period
        FROM disclosure_report r LEFT JOIN dart_filing f
          ON f."rceptNo"=r."rceptNo" AND f."companyId"=r."companyId"
        WHERE r.section='businessContent' AND r."supersededById" IS NULL
          AND r."reportCode" IN ('annual','q1','halfYear','q3')
      ) p ORDER BY p."companyId", p.actual_period DESC, p."rceptNo" DESC
    ) k
    LEFT JOIN disclosure_report r ON r."companyId"=k."companyId"
      AND r."rceptNo"=k."rceptNo" AND r."reportCode"=k."reportCode"
      AND r."bsnsYear"=k."bsnsYear" AND r.section='businessContent'
      AND r."supersededById" IS NULL
    LEFT JOIN business_document d ON d."reportId"=r.id AND d."companyId"=k."companyId"
      AND d."rceptNo"=k."rceptNo" AND d."bsnsYear"=k."bsnsYear"
  ''';
}
