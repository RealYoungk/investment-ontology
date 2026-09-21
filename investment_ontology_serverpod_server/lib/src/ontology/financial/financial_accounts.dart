import '../../generated/protocol.dart';

/// 화면에 쓰는 핵심 계정.
///
/// 계정명이 아니라 XBRL 계정 ID로만 찾는다. 이름으로 비슷한 계정을 추측하지 않으므로
/// 표준계정을 쓰지 않은 회사(금융업의 "영업수익" 등)는 값이 비어 보일 수 있다.
class FinancialAccount {
  const FinancialAccount(
    this.key,
    this.label,
    this.accountIds,
    this.statements,
  );

  final String key;
  final String label;

  /// 우선순위 순서의 XBRL ID.
  final List<String> accountIds;

  /// 찾을 재무제표. 앞의 것을 우선한다 (손익은 손익계산서 → 포괄손익계산서).
  final List<FinancialStatementKind> statements;
}

abstract final class FinancialAccounts {
  static const _pl = [
    FinancialStatementKind.incomeStatement,
    FinancialStatementKind.comprehensiveIncome,
  ];
  static const _bs = [FinancialStatementKind.balanceSheet];
  static const _cf = [FinancialStatementKind.cashFlow];

  static const all = [
    FinancialAccount('revenue', '매출액', ['ifrs-full_Revenue'], _pl),
    FinancialAccount(
      'operatingIncome',
      '영업이익',
      ['dart_OperatingIncomeLoss'],
      _pl,
    ),
    FinancialAccount('netIncome', '당기순이익', ['ifrs-full_ProfitLoss'], _pl),
    FinancialAccount(
      'netIncomeOwners',
      '지배주주 당기순이익',
      ['ifrs-full_ProfitLossAttributableToOwnersOfParent'],
      _pl,
    ),
    FinancialAccount('assets', '자산총계', ['ifrs-full_Assets'], _bs),
    FinancialAccount('liabilities', '부채총계', ['ifrs-full_Liabilities'], _bs),
    FinancialAccount('equity', '자본총계', ['ifrs-full_Equity'], _bs),
    FinancialAccount(
      'equityOwners',
      '지배주주 자본',
      ['ifrs-full_EquityAttributableToOwnersOfParent'],
      _bs,
    ),
    FinancialAccount(
      'operatingCashFlow',
      '영업활동 현금흐름',
      ['ifrs-full_CashFlowsFromUsedInOperatingActivities'],
      _cf,
    ),
    FinancialAccount(
      'capex',
      '유형자산의 취득',
      [
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities',
      ],
      _cf,
    ),
  ];

  static final Set<String> accountIds = {
    for (final a in all) ...a.accountIds,
  };

  /// 한 보고서의 사실에서 핵심 계정을 고른다. 자본변동표 세부(accountDetail) 행은 쓰지 않는다.
  static List<FinancialLine> pick(List<FinancialFact> facts) {
    final lines = <FinancialLine>[];
    for (final account in all) {
      FinancialFact? found;
      search:
      for (final id in account.accountIds) {
        for (final statement in account.statements) {
          for (final f in facts) {
            if (f.accountId == id &&
                f.statement == statement &&
                f.accountDetail == null) {
              found = f;
              break search;
            }
          }
        }
      }
      if (found == null) continue;
      lines.add(
        FinancialLine(
          key: account.key,
          factId: found.id!,
          statement: found.statement,
          accountId: found.accountId,
          accountName: found.accountName,
          amount: found.amount,
          cumulativeAmount: found.cumulativeAmount,
        ),
      );
    }
    return lines;
  }
}
