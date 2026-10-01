import 'financial_collection_scope.dart';

/// Body coverage counts actual documents, never an empty API response.
abstract final class BusinessCollectionScope {
  static const cte = '${FinancialCollectionScope.cte}, $bodyCte';
  static const bodyCte = '''
    business_scope AS (
      SELECT f.*, coalesce(s.status,'pending') AS body_status,
        coalesce(s.attempts,0) AS body_attempts,
        EXISTS (
          SELECT 1 FROM business_document b
          JOIN disclosure_report d ON d.id=b."reportId"
          LEFT JOIN dart_filing source_filing
            ON source_filing."rceptNo"=b."rceptNo"
            AND source_filing."companyId"=f."companyId"
          WHERE b."companyId"=f."companyId" AND d."companyId"=f."companyId"
            AND d."bsnsYear"=f."bsnsYear" AND d."reportCode"=f."reportCode"
            AND d.section='businessContent'
            AND (b."rceptNo"=f."rceptNo" OR
              (f."reportName" LIKE '%첨부정정%' AND b."rceptNo"<f."rceptNo"
                AND (d."settlementDate"::date =
                  (to_date(f.actual_period || '.01','YYYY.MM.DD')
                    + interval '1 month' - interval '1 day')::date
                  OR substring(source_filing."reportName" from
                    '\\(([0-9]{4}\\.[0-9]{2})\\)\$')=f.actual_period)))
        ) AS body_stored
      FROM financial_scope f LEFT JOIN dart_filing_section s
        ON s."filingId"=f.id AND s.section='businessContent'
    )
  ''';
}
