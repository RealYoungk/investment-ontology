import 'suntech_own_cf_scope.dart';
import 'financial_accounts.dart';
import 'financial_comparatives.dart';

/// Shared SQL for the company summary, screener and comparison universe.
/// Picks ONE basis, preserving available inputs when filling gaps; never splices consolidated and separate periods.
abstract final class FinancialBasis {
  /// Source-ledger periods only; missing periods are never inferred.
  /// The current DTO selects the latest closing month per fiscal year/type.
  /// Multiple REIT periods and their twelve-month TTM need a separate model.
  static const eligibleReportsCte = r'''
    eligible_reports AS (
      SELECT r.*, substring(r."reportName" from '\(([0-9]{4}\.[0-9]{2})\)$') AS actual_period
      FROM financial_report r
      JOIN source s ON s.id=r."sourceId"
      JOIN dart_filing f ON f."rceptNo"=r."rceptNo"
      JOIN company c ON c.id=r."companyId"
      -- Keep correlated provenance checks together. Independent selectivity
      -- estimates otherwise reduce 100k valid reports to one estimated row.
      WHERE CASE WHEN s.reference=r."rceptNo" AND s.kind='dartReport'
        AND f."companyId"=r."companyId" AND f."bsnsYear"=r."bsnsYear"
        AND f."reportCode"=r."reportCode" AND c."corpCode"=f."corpCode"
        AND substring(r."reportName" from '\(([0-9]{4}\.[0-9]{2})\)$')
        =substring(f."reportName" from '\(([0-9]{4}\.[0-9]{2})\)$')
        AND (r."reportCode"<>'annual' OR substring(r."reportName" from '\(([0-9]{4})\.[0-9]{2}\)$')=r."bsnsYear"::text)
        AND substring(r."reportName" from '\([0-9]{4}\.([0-9]{2})\)$') IN
          ('01','02','03','04','05','06','07','08','09','10','11','12') THEN true ELSE false END
    )
  ''';

  static String ctes({
    int? companyId,
    List<int>? companyIds,
    Set<int> blockedAnnualFlowReportIds = const {},
  }) {
    final ids = FinancialAccounts.accountIds.map((id) => "'$id'").join(',');
    final companyScope = companyId != null
        ? 'r."companyId" = $companyId'
        : companyIds == null
        ? null
        : companyIds.isEmpty
        ? 'false'
        : 'r."companyId" IN (${companyIds.join(',')})';
    // eligible_reports is referenced more than once and may be materialized.
    // Scope its input before provenance checks for a company detail request.
    final eligible = companyScope == null
        ? eligibleReportsCte
        : eligibleReportsCte.replaceFirst(
            'WHERE CASE WHEN',
            'WHERE $companyScope AND CASE WHEN',
          );
    return '''
      $eligible, rank_code AS (
        SELECT * FROM (VALUES ('q1',1),('halfYear',2),('q3',3),('annual',4)) AS t(code,rk)
      ), active_reports AS (
        SELECT DISTINCT ON (r."companyId",r."fsDiv",r."bsnsYear",r."reportCode") r.*
        FROM eligible_reports r
        WHERE r."supersededById" IS NULL
          ${companyId != null
        ? 'AND r."companyId" = $companyId'
        : companyIds == null
        ? ''
        : companyIds.isEmpty
        ? 'AND false'
        : 'AND r."companyId" IN (${companyIds.join(',')})'}
        ORDER BY r."companyId",r."fsDiv",r."bsnsYear",r."reportCode",r.actual_period DESC,r."rceptNo" DESC,r.id DESC
      ), candidate_periods AS MATERIALIZED (
        SELECT r.*,
          first_value(r."bsnsYear") OVER newest AS candidate_year,
          first_value(r."reportCode") OVER newest AS candidate_code
        FROM active_reports r
        WINDOW newest AS (PARTITION BY r."companyId",r."fsDiv"
          ORDER BY r.actual_period DESC,
            CASE r."reportCode" WHEN 'annual' THEN 4 WHEN 'q3' THEN 3 WHEN 'halfYear' THEN 2 ELSE 1 END DESC,
            r."rceptNo" DESC,r.id DESC)
      ), candidates AS (
        SELECT DISTINCT ON (r."companyId",r."fsDiv")
          r."companyId" AS id,r."fsDiv" AS fs,r."bsnsYear" AS y,r."reportCode" AS code,
          CASE r."reportCode" WHEN 'annual' THEN 4 WHEN 'q3' THEN 3 WHEN 'halfYear' THEN 2 ELSE 1 END AS rk,r.actual_period
        FROM candidate_periods r
        ORDER BY r."companyId",r."fsDiv",r.actual_period DESC,rk DESC,r."rceptNo" DESC,r.id DESC
      ), needed_reports AS MATERIALIZED (
        SELECT r.* FROM candidate_periods r
        WHERE CASE WHEN (r."bsnsYear"=r.candidate_year AND r."reportCode"=r.candidate_code
            OR r."bsnsYear"=r.candidate_year-1 AND r."reportCode" IN (r.candidate_code,'annual')) THEN true ELSE false END
      ), mapped_facts AS (
        SELECT f.id,f."reportId",f."companyId",f."bsnsYear",f."reportCode",f."fsDiv",
          f.statement,f."accountId",f."accountName",f."accountDetail",f."supersededById",
          f.currency,f.amount,f."cumulativeAmount",f."priorCumulativeAmount",f."priorQuarterAmount",
          f."sourceId",f.ord,f."periodName",f."priorAmount",f."beforePriorAmount",
          r.candidate_year, r.candidate_code, ${FinancialAccounts.resolvedIdSql('f')} AS resolved_id
        FROM needed_reports r
        JOIN financial_fact f ON f."reportId"=r.id
        WHERE CASE WHEN f."sourceId"=r."sourceId" AND f."companyId"=r."companyId"
          AND f."bsnsYear"=r."bsnsYear" AND f."reportCode"=r."reportCode"
          AND f."fsDiv"=r."fsDiv" AND f."supersededById" IS NULL AND f."accountDetail" IS NULL
          AND (f."accountId" IN ($ids) OR f."accountId" IS NULL) THEN true ELSE false END
      ), counted_facts AS (
        SELECT f.*, count(*) FILTER (WHERE f."accountId" IS NULL)
          OVER (PARTITION BY f."reportId",f.resolved_id) AS fallback_count,
          count(*) FILTER (WHERE f."accountId"='${FinancialComparatives.total}')
            OVER (PARTITION BY f."reportId",f.statement) AS total_count,
          count(*) FILTER (WHERE f."accountId"='${FinancialComparatives.minority}')
            OVER (PARTITION BY f."reportId",f.statement) AS minority_count,
          max(${FinancialComparatives.rawSql('f')}) FILTER (WHERE f."accountId"='${FinancialComparatives.total}')
            OVER (PARTITION BY f."reportId",f.statement,coalesce(f.currency,'KRW')) AS total_prior,
          max(${FinancialComparatives.rawSql('f')}) FILTER (WHERE f."accountId"='${FinancialComparatives.minority}')
            OVER (PARTITION BY f."reportId",f.statement,coalesce(f.currency,'KRW')) AS minority_prior
        FROM mapped_facts f
      ), picked_facts AS (
        SELECT DISTINCT ON (f."reportId",f.resolved_id) f.*
        FROM counted_facts f
        WHERE CASE WHEN f.resolved_id IN ($ids)
          AND (f."accountId" IS NOT NULL OR f.fallback_count=1)
          AND (
            f.resolved_id IN ('ifrs-full_Assets','ifrs-full_Liabilities','ifrs-full_Equity',
              'ifrs-full_EquityAttributableToOwnersOfParent') AND f.statement='balanceSheet'
            OR f.resolved_id IN ('ifrs-full_CashFlowsFromUsedInOperatingActivities',
              'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities') AND f.statement='cashFlow'
            OR f.resolved_id IN ('ifrs-full_Revenue','dart_OperatingIncomeLoss','ifrs-full_ProfitLoss',
              'ifrs-full_ProfitLossAttributableToOwnersOfParent') AND f.statement IN ('incomeStatement','comprehensiveIncome')
            OR f.resolved_id='ifrs-full_ProfitLoss' AND f.statement='cashFlow' AND (${SuntechOwnCfScope.sqlCondition('f', 'netIncome')})
          ) THEN true ELSE false END
        ORDER BY f."reportId",f.resolved_id,(f."accountId" IS NULL),(f."accountId" IS DISTINCT FROM f.resolved_id),CASE f.statement WHEN 'incomeStatement' THEN 0 ELSE 1 END,f.id
      ), basis_currency AS (
        SELECT "companyId" AS id,"fsDiv" AS fs,
          CASE WHEN count(DISTINCT coalesce(currency,'KRW'))=1
            THEN min(coalesce(currency,'KRW')) ELSE 'MIXED' END AS currency
        FROM picked_facts f
        WHERE CASE WHEN f.candidate_year=f."bsnsYear" AND f.candidate_code=f."reportCode" THEN true ELSE false END
        GROUP BY "companyId","fsDiv"
      ), raw_inc AS MATERIALIZED (
        SELECT f."companyId" AS id,f."fsDiv" AS fs,f.resolved_id AS acc,
          f."bsnsYear" AS y,f."reportCode" AS code,f.candidate_year,f.candidate_code,coalesce(f.currency,'KRW') AS currency,f.amount::numeric AS amt,
          CASE WHEN f."reportCode" IN ('annual','q1') OR f.statement='cashFlow'
            THEN coalesce(f."cumulativeAmount"::numeric,f.amount::numeric)
            ELSE f."cumulativeAmount"::numeric END AS cum, CASE WHEN f."accountId"='${FinancialComparatives.owners}'
              AND f.total_count=1 AND f.minority_count=1
              AND abs((${FinancialComparatives.rawSql('f')})+f.minority_prior-f.total_prior)
                > greatest(1000,abs(f.total_prior)/1000000)
            THEN NULL ELSE (${FinancialComparatives.rawSql('f')}) END AS prior_cum
        FROM picked_facts f
        WHERE f.statement IN ('incomeStatement','comprehensiveIncome','cashFlow')
          ${blockedAnnualFlowReportIds.isEmpty ? '' : 'AND f."reportId" NOT IN (${blockedAnnualFlowReportIds.join(',')})'}
      ), inc AS (
        SELECT id,fs,acc,y,code,candidate_year,candidate_code,currency,
          CASE WHEN acc='ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'
            THEN abs(amt) ELSE amt END AS amt,
          CASE WHEN acc='ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'
            THEN abs(cum) ELSE cum END AS cum,
          CASE WHEN acc='ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'
            THEN abs(prior_cum) ELSE prior_cum END AS prior_cum
        FROM raw_inc
      ), raw_ttm AS MATERIALIZED (
        SELECT i.id,i.fs,i.acc,
          CASE WHEN i.candidate_code='annual' THEN max(i.amt) FILTER (WHERE i.y=i.candidate_year)
            WHEN count(DISTINCT i.currency) FILTER (WHERE i.y=i.candidate_year OR i.amt IS NOT NULL OR i.cum IS NOT NULL)>1 THEN NULL
            ELSE max(i.amt) FILTER (WHERE i.y=i.candidate_year-1 AND i.code='annual')
              +max(i.cum) FILTER (WHERE i.y=i.candidate_year)
              -coalesce(max(i.cum) FILTER (WHERE i.y=i.candidate_year-1 AND i.code=i.candidate_code),
                max(i.prior_cum) FILTER (WHERE i.y=i.candidate_year AND i.code=i.candidate_code)) END AS v,
          CASE WHEN i.candidate_code='annual' THEN max(i.amt) FILTER (WHERE i.y=i.candidate_year)
            WHEN count(DISTINCT i.currency) FILTER (WHERE i.y=i.candidate_year OR i.amt IS NOT NULL OR i.cum IS NOT NULL)>1 THEN NULL
            ELSE max(i.cum) FILTER (WHERE i.y=i.candidate_year) END AS now_cum,
          CASE WHEN count(DISTINCT i.currency) FILTER (WHERE i.y=i.candidate_year OR i.amt IS NOT NULL OR i.cum IS NOT NULL)>1 THEN NULL WHEN i.candidate_code='annual' THEN max(i.amt) FILTER (WHERE i.y=i.candidate_year-1 AND i.code='annual')
            ELSE coalesce(max(i.cum) FILTER (WHERE i.y=i.candidate_year-1 AND i.code=i.candidate_code),
              max(i.prior_cum) FILTER (WHERE i.y=i.candidate_year AND i.code=i.candidate_code)) END AS ago_cum
        FROM inc i
        GROUP BY i.id,i.fs,i.candidate_year,i.candidate_code,i.acc
      ), ttm AS MATERIALIZED (
        SELECT id,fs,acc,
          CASE WHEN acc='ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'
            AND v < 0 THEN NULL ELSE v END AS v,
          now_cum,ago_cum
        FROM raw_ttm
      ), raw_bs AS MATERIALIZED (
        SELECT f."companyId" AS id,f."fsDiv" AS fs,f.resolved_id AS acc,f.amount::numeric AS v
        FROM picked_facts f
        WHERE CASE WHEN f.statement='balanceSheet' AND f.candidate_year=f."bsnsYear" AND f.candidate_code=f."reportCode" THEN true ELSE false END
      ), invalid_balance AS (
        SELECT id,fs FROM raw_bs GROUP BY id,fs
        HAVING abs(max(v) FILTER(WHERE acc='ifrs-full_Assets')
          -max(v) FILTER(WHERE acc='ifrs-full_Liabilities')
          -max(v) FILTER(WHERE acc='ifrs-full_Equity')) > greatest(1000,
            abs(max(v) FILTER(WHERE acc='ifrs-full_Assets'))/1000000)
      ), bs AS MATERIALIZED (
        SELECT b.id,b.fs,b.acc,CASE WHEN i.id IS NOT NULL THEN NULL ELSE b.v END AS v
        FROM raw_bs b LEFT JOIN invalid_balance i ON i.id=b.id AND i.fs=b.fs
      ), flow_coverage AS (
        SELECT id,fs,bit_or(CASE acc
          WHEN 'ifrs-full_Revenue' THEN 1 WHEN 'dart_OperatingIncomeLoss' THEN 2
          WHEN 'ifrs-full_ProfitLoss' THEN 4
          WHEN 'ifrs-full_ProfitLossAttributableToOwnersOfParent' THEN CASE fs WHEN 'consolidated' THEN 4 ELSE 0 END
          WHEN 'ifrs-full_CashFlowsFromUsedInOperatingActivities' THEN 8
          WHEN 'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities' THEN 16
          ELSE 0 END) AS mask,
          bool_or(acc='ifrs-full_ProfitLossAttributableToOwnersOfParent') AS owners_ready,
          bool_or(acc='ifrs-full_ProfitLoss') AS total_ready
          FROM ttm WHERE v IS NOT NULL GROUP BY id,fs
      ), balance_coverage AS (
        SELECT id,fs,bit_or(CASE acc
          WHEN 'ifrs-full_Assets' THEN 32 WHEN 'ifrs-full_Liabilities' THEN 64
          WHEN 'ifrs-full_Equity' THEN 384
          WHEN 'ifrs-full_EquityAttributableToOwnersOfParent' THEN CASE fs WHEN 'consolidated' THEN 128 ELSE 0 END
          ELSE 0 END) AS mask,
          bool_or(acc='ifrs-full_EquityAttributableToOwnersOfParent') AS owners_ready,
          bool_or(acc='ifrs-full_Equity') AS total_ready
          FROM bs WHERE v IS NOT NULL GROUP BY id,fs
      ), coverage AS (
        SELECT c.*,coalesce(f.mask,0)+coalesce(b.mask,0)
          + CASE WHEN (c.fs='consolidated' AND f.owners_ready AND b.owners_ready)
            OR (f.total_ready AND b.total_ready) THEN 512 ELSE 0 END AS mask
        FROM candidates c LEFT JOIN flow_coverage f ON f.id=c.id AND f.fs=c.fs
          LEFT JOIN balance_coverage b ON b.id=c.id AND b.fs=c.fs
      ), latest AS (
        SELECT DISTINCT ON (c.id) c.id,c.fs,c.y,c.code,
          CASE WHEN c.fs='consolidated' THEN 'consolidated'
            WHEN x.id IS NULL THEN 'separate_only'
            WHEN (x.actual_period,x.rk)<(c.actual_period,c.rk) THEN 'newer_separate'
            ELSE 'incomplete_consolidated' END AS reason
        FROM coverage c LEFT JOIN coverage x ON x.id=c.id AND x.fs='consolidated'
        ORDER BY c.id,c.actual_period DESC,c.rk DESC,
          (c.fs='separate' AND x.id IS NOT NULL AND x.actual_period=c.actual_period AND x.rk=c.rk
            AND (c.mask | x.mask)=c.mask AND c.mask<>x.mask) DESC,
          (c.fs='consolidated') DESC
      )
    ''';
  }
}
