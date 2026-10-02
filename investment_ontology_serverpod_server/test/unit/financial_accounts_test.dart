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
    'printed whole cash outflow exact alias preserves source and SQL mirror',
    () {
      final row = fact(
        '영업활동으로부터의 순현금유출',
        statement: FinancialStatementKind.cashFlow,
      );
      final line = FinancialAccounts.pick([row]).single;
      expect(line.key, 'operatingCashFlow');
      expect(line.accountName, row.accountName);
      expect(line.accountId, isNull);
      expect(
        FinancialAccounts.resolvedIdSql('f'),
        contains("'영업활동으로부터의순현금유출'"),
      );
      expect(FinancialAccounts.pick([fact(row.accountName)]), isEmpty);
      expect(
        FinancialAccounts.pick([row.copyWith(accountDetail: 'segment')]),
        isEmpty,
      );
      expect(FinancialAccounts.pick([row, row.copyWith(id: 2)]), isEmpty);
      expect(
        FinancialAccounts.pick([
          row.copyWith(accountName: '영업활동으로부터의 순현금유출 주석'),
        ]),
        isEmpty,
      );
    },
  );

  test(
    'whole mixed profit/loss labels preserve signs and SQL exact mirror',
    () {
      for (final sign in [-1, 1]) {
        for (final a in [
          ('Ⅴ. 영업손익(손실)', 'operatingIncome'),
          ('X. 당기순손익(손실)', 'netIncome'),
        ]) {
          final row = fact(a.$1).copyWith(amount: BigInt.from(sign * 123));
          expect(FinancialAccounts.pick([row]).single.key, a.$2);
          expect(FinancialAccounts.pick([row]).single.amount, row.amount);
          expect(
            FinancialAccounts.pick([row.copyWith(accountDetail: 'segment')]),
            isEmpty,
          );
          expect(
            FinancialAccounts.pick([
              row.copyWith(statement: FinancialStatementKind.cashFlow),
            ]),
            isEmpty,
          );
        }
      }
      for (final name in ['부문영업손익(손실)', '지배기업당기순손익(손실)', '중단영업당기순손익(손실)']) {
        expect(FinancialAccounts.pick([fact(name)]), isEmpty);
      }
      expect(FinancialAccounts.resolvedIdSql('f'), contains("'영업손익(손실)'"));
      expect(FinancialAccounts.resolvedIdSql('f'), contains("'당기순손익(손실)'"));
    },
  );

  test('actual trailing numeric note maps while malformed or embedded notes remain excluded', () {
    expect(FinancialAccounts.pick([fact('매출 (주25,36)')]).single.key, 'revenue');
    for (final name in [
      '매출(주25,X)',
      '매출(주25,,36)',
      '매출(주25,36)기타',
      '(주25,36)매출',
    ]) {
      expect(FinancialAccounts.pick([fact(name)]), isEmpty);
    }
  });

  test(
    'exact printed whole revenue and SQL mirror excludes costs and details',
    () {
      for (final name in ['매출', 'Ⅰ. 매 출', 'Ⅰ.매출액(주5)']) {
        expect(FinancialAccounts.pick([fact(name)]).single.key, 'revenue');
      }
      for (final name in ['매출원가', '부문매출', '고객별매출', '주석매출', '매출원가(주5)']) {
        expect(FinancialAccounts.pick([fact(name)]), isEmpty);
      }
      expect(FinancialAccounts.pick([fact('매출', detail: 'segment')]), isEmpty);
      expect(
        FinancialAccounts.pick([
          fact('매출', statement: FinancialStatementKind.cashFlow),
        ]),
        isEmpty,
      );
      expect(
        FinancialAccounts.pick([fact('매출액(주5)', detail: 'notes')]),
        isEmpty,
      );
      expect(
        FinancialAccounts.pick([
          fact('매출액(주5)', statement: FinancialStatementKind.cashFlow),
        ]),
        isEmpty,
      );
      expect(FinancialAccounts.resolvedIdSql('f'), contains("'매출액(주5)'"));
      expect(FinancialAccounts.resolvedIdSql('f'), contains("'매출'"));
      for (final year in [2024, 2025]) {
        final row = fact('Ⅰ. 매 출')
            .copyWith(bsnsYear: year, amount: BigInt.from(year * 1000));
        expect(FinancialAccounts.pick([row]).single.amount, row.amount);
      }
    },
  );

  test(
    'whole loss labels only resolve non-positive source-normalized amounts',
    () {
      final op = fact('Ⅴ. 영업손실');
      final net = fact('Ⅹ. 당기순손실');
      expect(FinancialAccounts.pick([op, net]).map((l) => l.key), [
        'operatingIncome',
        'netIncome',
      ]);
      op.amount = BigInt.zero;
      net.amount = BigInt.zero;
      expect(FinancialAccounts.pick([op, net]).length, 2);
      op.amount = BigInt.one;
      net.amount = BigInt.one;
      expect(FinancialAccounts.pick([op, net]), isEmpty);
      expect(op.accountName, 'Ⅴ. 영업손실');
      expect(net.accountId, isNull);
    },
  );

  test('printed ordinal labels resolve exact totals without rewriting raw names or ids', () {
    final originals = [
      fact('Ⅰ. 자 산 총 계', statement: FinancialStatementKind.balanceSheet),
      fact('II. 부 채 총 계', statement: FinancialStatementKind.balanceSheet),
      fact('Ⅲ. 영업수익'),
      fact('V. 영업이익(손실)'),
      fact('X. 당기순이익(손실)'),
      fact('Ⅰ. 영업활동으로 인한 현금흐름', statement: FinancialStatementKind.cashFlow),
    ];
    final lines = FinancialAccounts.pick(originals);
    expect(lines.map((l) => l.key).toSet(), {
      'assets',
      'liabilities',
      'revenue',
      'operatingIncome',
      'netIncome',
      'operatingCashFlow',
    });
    expect(lines.every((l) => l.accountId == null), isTrue);
    for (final line in lines) {
      expect(originals.any((f) => f.accountName == line.accountName), isTrue);
    }
    expect(originals.every((f) => f.accountId == null), isTrue);
  });
  test('ordinal normalization cannot admit subtotal, wrong statement, or duplicate totals', () {
    expect(
      FinancialAccounts.pick([
        fact('Ⅰ. 자산총계'),
        fact('I. 영업활동으로인한현금흐름'),
        fact('X. 계속영업당기순이익'),
        fact('IV. 지배기업소유주당기순이익'),
        fact('Ⅴ. 영업이익(손실)', detail: 'segment'),
        fact('Ⅰ. 매출액'),
        fact('매출액'),
      ]),
      isEmpty,
    );
  });

  test('term deposits stay separate from cash equivalents and other financial assets', () {
    final lines = FinancialAccounts.pick([
      fact(
        '현금및현금성자산',
        accountId: 'ifrs-full_CashAndCashEquivalents',
        statement: FinancialStatementKind.balanceSheet,
      ),
      fact(
        '단기금융상품',
        accountId: 'ifrs-full_ShorttermDepositsNotClassifiedAsCashEquivalents',
        statement: FinancialStatementKind.balanceSheet,
      ),
      fact(
        '기타금융자산',
        accountId: 'ifrs-full_OtherCurrentFinancialAssets',
        statement: FinancialStatementKind.balanceSheet,
      ),
    ]);
    expect(lines.map((l) => l.key), ['cash', 'shortTermDeposits']);
    expect(
      FinancialAccounts.pick([
        fact(
          '단기금융상품',
          accountId:
              'ifrs-full_ShorttermDepositsNotClassifiedAsCashEquivalents',
          statement: FinancialStatementKind.cashFlow,
        ),
      ]),
      isEmpty,
    );
  });

  test(
    'prior owners comparison conflicts are blocked without altering raw facts',
    () {
      final owners = fact(
        '지배주주 순이익',
        accountId: 'ifrs-full_ProfitLossAttributableToOwnersOfParent',
      )..priorCumulativeAmount = BigInt.zero;
      final total = fact('순이익', accountId: 'ifrs-full_ProfitLoss')
        ..priorCumulativeAmount = BigInt.from(-2715804289);
      final minority = fact(
        '비지배 순이익',
        accountId: 'ifrs-full_ProfitLossAttributableToNoncontrollingInterests',
      )..priorCumulativeAmount = BigInt.zero;
      final picked = FinancialAccounts.pick([owners, total, minority]);
      final result = picked.firstWhere((l) => l.key == 'netIncomeOwners');
      expect(result.priorSameCumulativeAmount, isNull);
      expect(result.priorSameUnavailableReason, contains('합계 불일치'));
      expect(result.amount, owners.amount);
      expect(owners.priorCumulativeAmount, BigInt.zero);
      owners.priorCumulativeAmount = total.priorCumulativeAmount;
      expect(
        FinancialAccounts.pick([owners, total, minority])
            .firstWhere((l) => l.key == 'netIncomeOwners')
            .priorSameCumulativeAmount,
        total.priorCumulativeAmount,
      );
    },
  );

  test(
    'interim P/L quarter comparisons never stand in for cumulative amounts',
    () {
      final revenue = fact('매출액', accountId: 'ifrs-full_Revenue')
        ..priorQuarterAmount = BigInt.from(19);
      expect(
        FinancialAccounts.pick([revenue]).single.priorSameCumulativeAmount,
        isNull,
      );
      revenue.reportCode = FinancialReportCode.q1;
      expect(
        FinancialAccounts.pick([revenue]).single.priorSameCumulativeAmount,
        BigInt.from(19),
      );
      revenue.reportCode = FinancialReportCode.halfYear;
      revenue.statement = FinancialStatementKind.cashFlow;
      revenue.accountId = 'ifrs-full_CashFlowsFromUsedInOperatingActivities';
      expect(
        FinancialAccounts.pick([revenue]).single.priorSameCumulativeAmount,
        BigInt.from(19),
      );
    },
  );

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
  test(
    'connected whole profit exact labels exclude positive loss and non-PL',
    () {
      for (final name in ['연결당기순손실', '연결당기순이익']) {
        expect(FinancialAccounts.pick([fact(name)]).single.key, 'netIncome');
        expect(
          FinancialAccounts.pick([
            fact(name, statement: FinancialStatementKind.cashFlow),
          ]),
          isEmpty,
        );
        expect(
          FinancialAccounts.pick([
            fact(name, statement: FinancialStatementKind.equityChanges),
          ]),
          isEmpty,
        );
      }
      expect(
        FinancialAccounts.pick([fact('연결당기순손실').copyWith(amount: BigInt.one)]),
        isEmpty,
      );
      expect(FinancialAccounts.pick([fact('연결지배기업당기순이익')]), isEmpty);
      expect(FinancialAccounts.pick([fact('연결기본주당순손실')]), isEmpty);
    },
  );
  test('EPS, comprehensive income, subtotal, other IDs and ambiguous rows are excluded', () {
    for (final f in [
      fact('기본주당이익(손실)'),
      fact('총포괄이익'),
      fact('계속영업당기순이익(손실)'),
      fact('지배주주당기순이익(손실)'),
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
