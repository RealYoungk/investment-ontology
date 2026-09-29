import 'financial_accounts.dart';

/// Shared SQL for the company summary, screener and comparison universe.
/// Picks ONE basis, preserving available inputs when filling gaps; never splices consolidated and separate periods.
abstract final class FinancialBasis {
  static String ctes({int? companyId}) {
    final ids = FinancialAccounts.accountIds.map((id) => "'$id'").join(',');
    return '''
      rank_code AS (
        SELECT * FROM (VALUES ('q1',1),('halfYear',2),('q3',3),('annual',4)) AS t(code,rk)
      ), active_reports AS (
        SELECT DISTINCT ON (r."companyId",r."fsDiv",r."bsnsYear",r."reportCode") r.*
        FROM financial_report r
        WHERE r."supersededById" IS NULL
          ${companyId == null ? '' : 'AND r."companyId" = $companyId'}
        ORDER BY r."companyId",r."fsDiv",r."bsnsYear",r."reportCode",r."rceptNo" DESC,r.id DESC
      ), candidates AS (
        SELECT DISTINCT ON (r."companyId",r."fsDiv")
          r."companyId" AS id,r."fsDiv" AS fs,r."bsnsYear" AS y,r."reportCode" AS code,rc.rk
        FROM active_reports r JOIN rank_code rc ON rc.code=r."reportCode"
        ORDER BY r."companyId",r."fsDiv",r."bsnsYear" DESC,rc.rk DESC
      ), picked_facts AS (
        SELECT DISTINCT ON (r.id,f."accountId") f.*
        FROM candidates c JOIN active_reports r ON r."companyId"=c.id AND r."fsDiv"=c.fs
          AND (r."bsnsYear"=c.y AND r."reportCode"=c.code
            OR r."bsnsYear"=c.y-1 AND r."reportCode" IN (c.code,'annual'))
        JOIN financial_fact f ON f."reportId"=r.id
        WHERE f."supersededById" IS NULL AND f."accountDetail" IS NULL
          AND f."accountId" IN ($ids)
          AND (
            f."accountId" IN ('ifrs-full_Assets','ifrs-full_Liabilities','ifrs-full_Equity',
              'ifrs-full_EquityAttributableToOwnersOfParent') AND f.statement='balanceSheet'
            OR f."accountId" IN ('ifrs-full_CashFlowsFromUsedInOperatingActivities',
              'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities') AND f.statement='cashFlow'
            OR f."accountId" IN ('ifrs-full_Revenue','dart_OperatingIncomeLoss','ifrs-full_ProfitLoss',
              'ifrs-full_ProfitLossAttributableToOwnersOfParent') AND f.statement IN ('incomeStatement','comprehensiveIncome')
          )
        ORDER BY r.id,f."accountId",CASE f.statement WHEN 'incomeStatement' THEN 0 ELSE 1 END,f.id
      ), inc AS (
        SELECT f."companyId" AS id,f."fsDiv" AS fs,f."accountId" AS acc,
          f."bsnsYear" AS y,f."reportCode" AS code,f.amount::numeric AS amt,
          CASE WHEN f."reportCode" IN ('annual','q1') OR f.statement='cashFlow'
            THEN coalesce(f."cumulativeAmount"::numeric,f.amount::numeric)
            ELSE f."cumulativeAmount"::numeric END AS cum
        FROM picked_facts f WHERE f.statement IN ('incomeStatement','comprehensiveIncome','cashFlow')
      ), ttm AS MATERIALIZED (
        SELECT c.id,c.fs,i.acc,
          CASE WHEN c.code='annual' THEN max(i.amt) FILTER (WHERE i.y=c.y)
            ELSE max(i.amt) FILTER (WHERE i.y=c.y-1 AND i.code='annual')
              +max(i.cum) FILTER (WHERE i.y=c.y)
              -max(i.cum) FILTER (WHERE i.y=c.y-1 AND i.code=c.code) END AS v,
          CASE WHEN c.code='annual' THEN max(i.amt) FILTER (WHERE i.y=c.y)
            ELSE max(i.cum) FILTER (WHERE i.y=c.y) END AS now_cum,
          CASE WHEN c.code='annual' THEN max(i.amt) FILTER (WHERE i.y=c.y-1 AND i.code='annual')
            ELSE max(i.cum) FILTER (WHERE i.y=c.y-1 AND i.code=c.code) END AS ago_cum
        FROM candidates c JOIN inc i ON i.id=c.id AND i.fs=c.fs
        GROUP BY c.id,c.fs,c.y,c.code,i.acc
      ), bs AS MATERIALIZED (
        SELECT f."companyId" AS id,f."fsDiv" AS fs,f."accountId" AS acc,f.amount::numeric AS v
        FROM picked_facts f JOIN candidates c ON c.id=f."companyId" AND c.fs=f."fsDiv"
          AND c.y=f."bsnsYear" AND c.code=f."reportCode"
        WHERE f.statement='balanceSheet'
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
            WHEN (x.y,x.rk)<(c.y,c.rk) THEN 'newer_separate'
            ELSE 'incomplete_consolidated' END AS reason
        FROM coverage c LEFT JOIN coverage x ON x.id=c.id AND x.fs='consolidated'
        ORDER BY c.id,c.y DESC,c.rk DESC,
          (c.fs='separate' AND x.id IS NOT NULL AND x.y=c.y AND x.rk=c.rk
            AND (c.mask | x.mask)=c.mask AND c.mask<>x.mask) DESC,
          (c.fs='consolidated') DESC
      )
    ''';
  }
}
