import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_header.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

import 'financial_metrics_test.dart' as fixtures;

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'missing metric reasons are visible without tapping at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final data = fixtures.financials([
          fixtures.period(2025, FinancialReportCode.annual, [
            fixtures.line('netIncome', -100),
            fixtures.line('equity', 0),
          ]),
        ], cap: BigInt.from(1000));
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyHeader(
                  detail: CompanyDetail(
                    company: Company(corpCode: 'test', name: '테스트금융지주'),
                    industryPath: [],
                    changes: [],
                  ),
                  financials: data,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final metric in FinancialView(
          data,
        ).metrics().where((m) => ['per', 'roe'].contains(m.key))) {
          expect(metric.derived.value, isNull);
          expect(find.text(metric.derived.missing!), findsWidgets);
        }
        expect(find.text('일부 지표 계산 불가 · 지표를 누르면 사유 확인'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
