import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/governance_view.dart';

InvestmentEntry entry(
  String name,
  int? book,
  int? income, {
  bool total = false,
}) => InvestmentEntry(
  reportId: 1,
  companyId: 1,
  bsnsYear: 2025,
  ord: 1,
  investeeName: name,
  bookValueEnd: book == null ? null : BigInt.from(book),
  investeeNetIncome: income == null ? null : BigInt.from(income),
  isTotal: total,
);
void main() {
  final rows = [
    entry('loss', 10, -300),
    entry('profit', 100, 200),
    entry('zero', 0, 0),
    entry('missing', null, null),
    entry('total', 110, -100, total: true),
  ];
  for (final expectation in {
    InvestmentSort.bookValue: ['profit', 'loss', 'zero', 'missing', 'total'],
    InvestmentSort.profit: ['profit', 'zero', 'loss', 'missing', 'total'],
    InvestmentSort.loss: ['loss', 'zero', 'profit', 'missing', 'total'],
    InvestmentSort.incomeMagnitude: [
      'loss',
      'profit',
      'zero',
      'missing',
      'total',
    ],
  }.entries) {
    test(
      '${expectation.key} preserves zero, places missing and totals last',
      () {
        expect(
          sortedInvestments(rows, expectation.key).map((r) => r.investeeName),
          expectation.value,
        );
        expect(rows.first.investeeName, 'loss');
      },
    );
  }
}
