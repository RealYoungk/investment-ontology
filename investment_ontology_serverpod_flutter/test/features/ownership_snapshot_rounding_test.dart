import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/ownership_snapshot.dart';

import '../support/shad_test_host.dart';

CompanyGovernance roundedDisclosure(double first, double second, double total) {
  ShareholderEntry entry(String name, double ratio, {bool isTotal = false}) =>
      ShareholderEntry(
        reportId: 1,
        companyId: 1,
        bsnsYear: 2025,
        ord: 1,
        holderName: name,
        ratioEnd: ratio,
        stockKind: '보통주',
        isTotal: isTotal,
      );
  return CompanyGovernance(
    corpCode: 'test',
    bsnsYear: 2025,
    settlementDate: DateTime(2025, 12, 31),
    availableYears: [2025],
    shareholders: [
      entry('최대주주', first),
      entry('관계인', second),
      entry('합계', total, isTotal: true),
    ],
    executives: [],
    investments: [],
    investors: [],
    holdings: [],
    companies: [],
    persons: [],
    sources: [],
  );
}

Future<void> renderSnapshot(
  WidgetTester tester,
  double width,
  CompanyGovernance data,
) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    shadTestHost(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(child: OwnershipSnapshotCard(data: data)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [1440.0, 390.0]) {
    testWidgets('rounded source sum fits public snapshot at $width', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Printed holder shares sum to 42.31%, versus the printed total 42.30%.
      // Fixed widths used to sum to 100.01% and overflow even at desktop width.
      final data = roundedDisclosure(37.11, 5.20, 42.30);
      await renderSnapshot(tester, width, data);
      expect(tester.takeException(), isNull);
      expect(find.text('최대주주 37.1%'), findsOneWidget);
      expect(find.text('관계인 5.20%'), findsOneWidget);
      expect(find.text('그 외 주주 57.7%'), findsOneWidget);
      expect(data.shareholders.first.ratioEnd, 37.11);
      expect(data.shareholders.last.ratioEnd, 42.30);
      expect(find.textContaining('구성 차트를 표시하지 않습니다'), findsNothing);
    });
    testWidgets('invalid source sum keeps guard at $width', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final data in [
        roundedDisclosure(37.11, 5.20, 40.0),
        roundedDisclosure(80.0, 21.0, 100.0),
      ]) {
        await renderSnapshot(tester, width, data);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('구성 차트를 표시하지 않습니다'), findsOneWidget);
        expect(find.textContaining('그 외 주주 '), findsNothing);
      }
    });
  }
}
