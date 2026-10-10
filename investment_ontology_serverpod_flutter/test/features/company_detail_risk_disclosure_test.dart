import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_insights_panel.dart';

import '../support/shad_test_host.dart';
import 'business_table_insights_test.dart' as fixtures;

void main() {
  testWidgets('risk charts remain available through expand and collapse', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BusinessTableInsightsPanel(
                insights: [
                  fixtures.insight().copyWith(
                    topic: 'derivatives',
                    title: '파생상품·위험관리',
                  ),
                ],
                rceptNo: '20260813000643',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('파생상품·위험관리 펼치기'), findsOneWidget);
    expect(find.text('추출 근거'), findsNothing);
    await tester.tap(find.text('파생상품·위험관리 펼치기'));
    await tester.pumpAndSettle();
    expect(find.text('추출 근거'), findsOneWidget);
    await tester.tap(find.text('파생상품·위험관리 접기'));
    await tester.pumpAndSettle();
    expect(find.text('파생상품·위험관리 펼치기'), findsOneWidget);
    expect(find.text('추출 근거'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
