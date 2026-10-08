import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_insights_panel.dart';

import '../support/shad_test_host.dart';

BusinessTableInsight insight() => BusinessTableInsight(
  topic: 'materialPurchase',
  title: '원재료 매입 구성',
  columns: ['품목', '매입액'],
  rows: [
    BusinessTableRecord(label: 'Resin', cells: ['Resin', '3,085']),
  ],
  measures: [
    BusinessTableMeasure(
      label: 'Resin',
      metric: '매입액',
      period: '2026 반기',
      value: 3085,
      unit: '억원',
    ),
    BusinessTableMeasure(
      label: 'Filter',
      metric: '매입액',
      period: '2026 반기',
      value: 2456,
      unit: '억원',
    ),
    BusinessTableMeasure(
      label: 'Resin',
      metric: '매입액',
      period: '2025 연간',
      value: 5000,
      unit: '억원',
    ),
    BusinessTableMeasure(
      label: 'Resin',
      metric: '매입액',
      period: '2026 반기',
      value: 10,
      unit: 'USD',
    ),
  ],
  evidence: '품목 | 매입액\nResin | 3,085',
  validation: '합계 검산 미수행',
  scope: '3. 원재료 및 생산설비',
);
void main() {
  testWidgets('all observations in a large chart remain reachable', (
    tester,
  ) async {
    final table = insight().copyWith(
      topic: 'materialPrice',
      measures: [
        for (var i = 0; i < 20; i++)
          BusinessTableMeasure(
            label: '항목 $i',
            metric: '매입액',
            period: '2026 반기',
            value: i.toDouble(),
            unit: '억원',
          ),
      ],
    );
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BusinessTableInsightsPanel(
                insights: [table],
                rceptNo: 'source',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1–16 / 20개'), findsOneWidget);
    await tester.ensureVisible(find.text('다음 항목'));
    await tester.tap(find.text('다음 항목'));
    await tester.pumpAndSettle();
    expect(find.text('17–20 / 20개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('charts never mix units or annual and interim periods', () {
    final groups = tableMeasureGroups(insight());
    expect(groups.length, 3);
    expect(groups[('매입액', '억원', '2026 반기')]!.map((m) => m.value), [3085, 2456]);
  });
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets('source details and long labels fit $width at enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.4),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BusinessTableInsightsPanel(
                    insights: [insight()],
                    rceptNo: '20260814003375',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('원재료 매입 구성'), findsOneWidget);
      await tester.ensureVisible(find.bySemanticsLabel('원재료 매입 구성 읽는 법'));
      await tester.tap(find.bySemanticsLabel('원재료 매입 구성 읽는 법'));
      await tester.pumpAndSettle();
      expect(find.textContaining('합계 검산 미수행'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('항목별 정보 1개'));
      await tester.tap(find.text('항목별 정보 1개'));
      await tester.pumpAndSettle();
      expect(find.text('3,085'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
