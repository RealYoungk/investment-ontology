import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:test/test.dart';

FinancialFact fact(
  String name, {
  String? accountId,
  String? detail,
  FinancialStatementKind statement = FinancialStatementKind.comprehensiveIncome,
}) => FinancialFact(
  id: 1,
  reportId: 1,
  companyId: 1,
  bsnsYear: 2026,
  reportCode: FinancialReportCode.halfYear,
  fsDiv: FsDiv.separate,
  statement: statement,
  accountName: name,
  accountId: accountId,
  accountDetail: detail,
  amount: BigInt.from(-601318468),
  cumulativeAmount: BigInt.from(-680203867),
  sourceId: 1,
);

void main() {
  test(
    'alternate IFRS operating ID and Unicode spaces resolve consistently',
    () {
      expect(
        FinancialAccounts.pick([
          fact(
            '영업이익',
            accountId: 'ifrs-full_ProfitLossFromOperatingActivities',
          ),
        ]).single.key,
        'operatingIncome',
      );
      expect(
        FinancialAccounts.pick([
          fact('유형자산의　취득', statement: FinancialStatementKind.cashFlow),
        ]).single.key,
        'capex',
      );
    },
  );
  test('material balance conflict keeps source values but blocks derived balance inputs', () {
    final lines = FinancialAccounts.pick([
      for (final entry in {
        'ifrs-full_Assets': 1000000,
        'ifrs-full_Liabilities': 100000,
        'ifrs-full_Equity': 100000,
      }.entries)
        fact(
          entry.key,
          accountId: entry.key,
          statement: FinancialStatementKind.balanceSheet,
        ).copyWith(amount: BigInt.from(entry.value), currency: 'USD'),
    ]);
    expect(lines.every((l) => l.amount != null && l.currency == 'USD'), isTrue);
    expect(
      lines.every((l) => l.unavailableReason?.contains('합계 불일치') == true),
      isTrue,
    );
  });

  test(
    'exact total fallbacks exclude subtotals and expired standard facts',
    () {
      expect(FinancialAccounts.pick([fact('매출액')]).single.key, 'revenue');
      for (final name in ['제품매출액', '상품매출액', '매출원가']) {
        expect(FinancialAccounts.pick([fact(name)]), isEmpty);
      }
      expect(
        FinancialAccounts.pick([
          fact('현금및현금성자산', statement: FinancialStatementKind.balanceSheet),
        ]).single.key,
        'cash',
      );
      expect(
        FinancialAccounts.pick([
          fact('기초현금및현금성자산', statement: FinancialStatementKind.cashFlow),
          fact('사용권자산감가상각비', statement: FinancialStatementKind.cashFlow),
        ]),
        isEmpty,
      );
      expect(
        FinancialAccounts.pick([
          fact(
            '매출액',
            accountId: 'ifrs-full_Revenue',
          ).copyWith(supersededById: 2),
          fact('매출액'),
        ]).single.accountId,
        isNull,
      );
    },
  );

  test('valuation inputs retain provenance and never infer complete debt from liabilities', () {
    final cash = fact(
      '현금',
      accountId: 'ifrs-full_CashAndCashEquivalents',
      statement: FinancialStatementKind.balanceSheet,
    );
    final da = fact(
      '상각',
      accountId: 'ifrs-full_AdjustmentsForDepreciationAndAmortisationExpense',
      statement: FinancialStatementKind.cashFlow,
    );
    final debt = fact(
      '총차입금(리스부채포함)',
      statement: FinancialStatementKind.balanceSheet,
    );
    final lines = FinancialAccounts.pick([cash, da, debt]);
    expect(
      lines.map((l) => l.key),
      containsAll([
        'cash',
        'depreciationAmortisation',
        'interestDebtIncludingLeases',
      ]),
    );
    expect(lines.every((l) => l.factId == 1), isTrue);
    expect(
      FinancialAccounts.pick([
        fact('총차입금', statement: FinancialStatementKind.balanceSheet),
      ]),
      isEmpty,
    );
    expect(FinancialAccounts.pick([debt, debt]), isEmpty);
    expect(
      FinancialAccounts.pick([
        da.copyWith(statement: FinancialStatementKind.incomeStatement),
      ]),
      isEmpty,
    );
  });

  test(
    'unidentified half-year profit keeps quarter, cumulative and provenance',
    () {
      final picked = FinancialAccounts.pick([fact('반기 순이익(손실)')]).single;
      expect(picked.key, 'netIncome');
      expect(picked.amount, BigInt.from(-601318468));
      expect(picked.cumulativeAmount, BigInt.from(-680203867));
      expect(picked.accountId, isNull);
      expect(picked.factId, 1);
    },
  );
  test('EPS, comprehensive income, subtotal, other IDs and ambiguous rows are excluded', () {
    for (final f in [
      fact('기본주당이익(손실)'),
      fact('총포괄이익'),
      fact('계속영업당기순이익(손실)'),
      fact('지배주주당기순이익(손실)'),
      fact('당기순손실'),
      fact('당기순이익(손실)', detail: 'segment'),
      fact('당기순이익(손실)', statement: FinancialStatementKind.equityChanges),
      fact('당기순이익(손실)', accountId: 'ifrs-full_ComprehensiveIncome'),
    ]) {
      expect(FinancialAccounts.pick([f]), isEmpty);
    }
    expect(
      FinancialAccounts.pick([fact('당기순이익(손실)'), fact('반기순이익(손실)')]),
      isEmpty,
    );
  });
  test(
    'standard ID wins and operating income/capex require correct statement',
    () {
      final standard = fact('공시 순이익', accountId: 'ifrs-full_ProfitLoss');
      expect(
        FinancialAccounts.pick([fact('당기순이익(손실)'), standard]).single.accountId,
        'ifrs-full_ProfitLoss',
      );
      expect(
        FinancialAccounts.pick([fact('영업이익(손실)')]).single.key,
        'operatingIncome',
      );
      expect(FinancialAccounts.pick([fact('유형자산의 취득')]), isEmpty);
      expect(
        FinancialAccounts.pick([
          fact('유형자산의 취득', statement: FinancialStatementKind.cashFlow),
        ]).single.key,
        'capex',
      );
    },
  );
}
