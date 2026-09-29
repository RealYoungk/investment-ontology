import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_section.dart';

import 'financial_metrics_test.dart' as fixtures;

void main() {
  testWidgets('기준 전환 후 계산 근거를 갱신하고 선택한 분기를 유지한다', (tester) async {
    CompanyFinancials data(FsDiv div, int net) {
      final result = fixtures.financials([
        fixtures.period(2025, FinancialReportCode.annual, [
          fixtures.line('netIncome', net),
          fixtures.line('netIncomeOwners', net),
          fixtures.line('revenue', 500),
          fixtures.line('operatingIncome', 100),
        ]),
      ], cap: BigInt.from(1000));
      result.fsDiv = div;
      result.availableFsDivs = FsDiv.values;
      return result;
    }

    Future<void> pump(CompanyFinancials value) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinancialSection(
                corpCode: value.corpCode,
                initialData: value,
                showBasisSelector: false,
                openMetric: 'per',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(data(FsDiv.consolidated, 100));
    expect(find.textContaining('계산식 · PER = 10.00배 · 연결'), findsOneWidget);
    await tester.tap(find.text('분기'));
    await tester.pumpAndSettle();
    expect(find.text('분기 재무가 없습니다.'), findsOneWidget);

    await pump(data(FsDiv.separate, 50));
    expect(find.textContaining('계산식 · PER = 20.00배 · 별도'), findsOneWidget);
    expect(find.textContaining('계산식 · PER = 10.00배 · 연결'), findsNothing);
    expect(find.text('분기 재무가 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
