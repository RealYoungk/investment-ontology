/// Active financial collection scope. Old ledger entries remain untouched.
abstract final class FinancialCollectionScope {
  /// Five fiscal years of annual reports and the latest interim, when newer
  /// than the latest annual. Keep only each period's final correction.
  static const cte = '''
    period_filings AS (
      SELECT DISTINCT ON (f."companyId", f."bsnsYear", f."reportCode") f.*
      FROM dart_filing f JOIN company c ON c.id=f."companyId"
      WHERE c."stockCode" IS NOT NULL
        AND f."reportCode" IN ('annual','q1','halfYear','q3')
      ORDER BY f."companyId", f."bsnsYear", f."reportCode", f."rceptNo" DESC
    ), annual_years AS (
      SELECT "companyId", max("bsnsYear") AS latest_year
      FROM period_filings WHERE "reportCode"='annual' GROUP BY "companyId"
    ), latest_period AS (
      SELECT DISTINCT ON ("companyId") id, "companyId", "reportCode"
      FROM period_filings
      ORDER BY "companyId", "bsnsYear" DESC,
        CASE "reportCode" WHEN 'annual' THEN 4 WHEN 'q3' THEN 3
          WHEN 'halfYear' THEN 2 ELSE 1 END DESC, "rceptNo" DESC
    ), financial_scope AS (
      SELECT p.* FROM period_filings p
      LEFT JOIN annual_years a ON a."companyId"=p."companyId"
      WHERE p."reportCode"='annual' AND p."bsnsYear">=a.latest_year-4
        OR p.id IN (SELECT id FROM latest_period WHERE "reportCode"<>'annual')
    )
  ''';
}
