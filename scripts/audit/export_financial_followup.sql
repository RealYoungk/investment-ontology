COPY (
 WITH canonical AS (
 SELECT DISTINCT ON (r."companyId",r."fsDiv",r."bsnsYear",r."reportCode") r.* FROM financial_report r JOIN company c ON c.id=r."companyId" WHERE r."supersededById" IS NULL AND c.market IN ('kospi','kosdaq','konex') ORDER BY r."companyId",r."fsDiv",r."bsnsYear",r."reportCode",r."rceptNo" DESC,r.id DESC
 )
 SELECT json_build_object('report',row_to_json(r),'corpCode',c."corpCode",'facts',coalesce(json_agg(row_to_json(f)) FILTER(WHERE f.id IS NOT NULL),'[]'::json))
 FROM canonical r JOIN company c ON c.id=r."companyId" LEFT JOIN financial_fact f ON f."reportId"=r.id AND f."supersededById" IS NULL AND f."accountDetail" IS NULL AND (
 f."accountId" IN ('ifrs-full_Revenue','ifrs-full_RevenueFromContractsWithCustomers','ifrs-full_ProfitLossFromOperatingActivities','dart_OperatingIncomeLoss','ifrs-full_ProfitLoss','ifrs-full_ProfitLossAttributableToOwnersOfParent','ifrs-full_CashAndCashEquivalents','ifrs-full_ShorttermDepositsNotClassifiedAsCashEquivalents','ifrs-full_ProfitLossAttributableToNoncontrollingInterests','ifrs-full_NoncontrollingInterests','ifrs-full_AdjustmentsForDepreciationAndAmortisationExpense','ifrs-full_AdjustmentsForDepreciationExpense','ifrs-full_AdjustmentsForAmortisationExpense','ifrs-full_Assets','ifrs-full_Liabilities','ifrs-full_Equity','ifrs-full_EquityAttributableToOwnersOfParent','ifrs-full_CashFlowsFromUsedInOperatingActivities','ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities')
 OR f."accountId" IS NULL AND regexp_replace(f."accountName",'[[:space:]\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF]','','g') IN ('자본총계','영업활동현금흐름','매출액','현금및현금성자산','감가상각비','무형자산상각비','총차입금(리스부채포함)','차입금및사채및리스부채합계','당기순이익(손실)','반기순이익(손실)','분기순이익(손실)','당기순이익','반기순이익','분기순이익','영업이익(손실)','영업이익','유형자산의취득','유형자산취득'))
 GROUP BY r,c."corpCode"
) TO STDOUT;
