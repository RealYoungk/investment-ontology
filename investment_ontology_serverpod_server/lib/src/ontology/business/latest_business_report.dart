/// Latest known regular filing, ordered by its actual reporting period first.
/// Select the filing BEFORE joining its body: an uncollected newer filing must
/// never cause an older product profile to masquerade as the current one.
abstract final class LatestBusinessReport {
  static const sql = '''
    SELECT k."companyId", k."bsnsYear", k."reportCode", k."rceptNo",
      k."reportName", d.id AS "documentId", d."rceptNo" AS "sourceReceipt"
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
    LEFT JOIN LATERAL (
      SELECT candidate.* FROM disclosure_report candidate
      LEFT JOIN dart_filing original ON original."companyId"=candidate."companyId"
        AND original."rceptNo"=candidate."rceptNo"
      WHERE candidate."companyId"=k."companyId"
        AND candidate."reportCode"=k."reportCode" AND candidate."bsnsYear"=k."bsnsYear"
        AND candidate.section='businessContent' AND candidate."supersededById" IS NULL
        AND EXISTS (SELECT 1 FROM business_document body WHERE body."reportId"=candidate.id
          AND body."companyId"=candidate."companyId" AND body."rceptNo"=candidate."rceptNo"
          AND body."bsnsYear"=candidate."bsnsYear")
        AND (candidate."rceptNo"=k."rceptNo" OR
          (k."reportName" LIKE '%첨부정정%' AND candidate."rceptNo"<k."rceptNo"
            AND (to_char(candidate."settlementDate",'YYYY.MM')=k.actual_period
              OR substring(original."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$')=k.actual_period)
            AND NOT EXISTS (SELECT 1 FROM dart_filing intervening
              WHERE intervening."companyId"=k."companyId" AND intervening."reportCode"=k."reportCode"
                AND intervening."bsnsYear"=k."bsnsYear"
                AND intervening."rceptNo">candidate."rceptNo" AND intervening."rceptNo"<k."rceptNo"
                AND intervening."reportName" NOT LIKE '%첨부정정%'
                AND substring(intervening."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$')=k.actual_period)))
      ORDER BY candidate."rceptNo" DESC LIMIT 1
    ) r ON true
    LEFT JOIN business_document d ON d."reportId"=r.id AND d."companyId"=k."companyId"
      AND d."rceptNo"=r."rceptNo" AND d."bsnsYear"=k."bsnsYear"
  ''';
}
