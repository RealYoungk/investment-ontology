/// Active financial collection scope. Old ledger entries remain untouched.
abstract final class FinancialCollectionScope {
  /// Five fiscal years of annual reports and the latest interim, when newer
  /// than the latest annual. Keep only each period's final correction.
  // Availability requires source-receipt ledger period binding and source-bound
  // facts. This is ledger evidence, not independent original-cover verification.
  static const cte = '''
    source_periods AS (
      SELECT f.*, COALESCE(
        substring(f."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$'),
        f."bsnsYear"::text || '.' ||
          CASE f."reportCode" WHEN 'annual' THEN '12' WHEN 'q3' THEN '09'
            WHEN 'halfYear' THEN '06' ELSE '03' END) AS actual_period
      FROM dart_filing f JOIN company c ON c.id=f."companyId"
      WHERE c."stockCode" IS NOT NULL
        AND f."reportCode" IN ('annual','q1','halfYear','q3')
    ), period_filings AS (
      SELECT DISTINCT ON (f."companyId", f."reportCode", f.actual_period) f.*
      FROM source_periods f
      ORDER BY f."companyId", f."reportCode", f.actual_period, f."rceptNo" DESC
    ), annual_years AS (
      SELECT "companyId", max("bsnsYear") AS latest_year
      FROM period_filings WHERE "reportCode"='annual' GROUP BY "companyId"
    ), latest_period AS (
      SELECT DISTINCT ON ("companyId") id, "companyId", "reportCode"
      FROM period_filings
      ORDER BY "companyId", actual_period DESC, "rceptNo" DESC
    ), financial_scope AS (
      SELECT p.*,
        EXISTS (SELECT 1 FROM financial_report r
          JOIN source rs ON rs.id=r."sourceId" AND rs.reference=r."rceptNo"
          WHERE r."companyId"=p."companyId" AND r."bsnsYear"=p."bsnsYear"
            AND r."reportCode"=p."reportCode" AND r."fsDiv"='consolidated'
            AND substring(r."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$')=p.actual_period
            AND EXISTS (SELECT 1 FROM dart_filing sf
              WHERE sf."rceptNo"=r."rceptNo" AND sf."companyId"=r."companyId"
                AND sf."corpCode"=p."corpCode" AND sf."bsnsYear"=r."bsnsYear"
                AND sf."reportCode"=r."reportCode"
                AND substring(sf."reportName" from '[0-9]{4}[.][0-9]{2}')=p.actual_period)
            AND EXISTS (SELECT 1 FROM financial_fact v
              WHERE v."reportId"=r.id AND v."companyId"=r."companyId"
                AND v."bsnsYear"=r."bsnsYear" AND v."reportCode"=r."reportCode"
                AND v."fsDiv"=r."fsDiv" AND v."sourceId"=r."sourceId"
                AND v.amount IS NOT NULL)) AS consolidated_period_stored,
        EXISTS (SELECT 1 FROM financial_report r
          JOIN source rs ON rs.id=r."sourceId" AND rs.reference=r."rceptNo"
          WHERE r."companyId"=p."companyId" AND r."bsnsYear"=p."bsnsYear"
            AND r."reportCode"=p."reportCode" AND r."fsDiv"='separate'
            AND substring(r."reportName" from '\\(([0-9]{4}\\.[0-9]{2})\\)\$')=p.actual_period
            AND EXISTS (SELECT 1 FROM dart_filing sf
              WHERE sf."rceptNo"=r."rceptNo" AND sf."companyId"=r."companyId"
                AND sf."corpCode"=p."corpCode" AND sf."bsnsYear"=r."bsnsYear"
                AND sf."reportCode"=r."reportCode"
                AND substring(sf."reportName" from '[0-9]{4}[.][0-9]{2}')=p.actual_period)
            AND EXISTS (SELECT 1 FROM financial_fact v
              WHERE v."reportId"=r.id AND v."companyId"=r."companyId"
                AND v."bsnsYear"=r."bsnsYear" AND v."reportCode"=r."reportCode"
                AND v."fsDiv"=r."fsDiv" AND v."sourceId"=r."sourceId"
                AND v.amount IS NOT NULL)) AS separate_period_stored
      FROM period_filings p
      LEFT JOIN annual_years a ON a."companyId"=p."companyId"
      WHERE p."reportCode"='annual' AND p."bsnsYear">=a.latest_year-4
        OR p.id IN (SELECT id FROM latest_period WHERE "reportCode"<>'annual')
    )
  ''';
}
