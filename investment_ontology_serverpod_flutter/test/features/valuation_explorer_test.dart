import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_header.dart';

import 'financial_metrics_test.dart' as f;

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('groups and formula dialog fit at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = f.financials([
        f.period(2025, FinancialReportCode.annual, [
          f.line('revenue', 1000),
          f.line('operatingIncome', 100),
        ]),
      ], cap: BigInt.from(10000));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompanyHeader(
                detail: CompanyDetail(
                  company: Company(
                    corpCode: data.corpCode,
                    name: '테스트',
                    industryCode: '62010',
                  ),
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
      await tester.tap(find.text('가격'));
      await tester.pumpAndSettle();
      expect(find.text('예상 EPS·성장률 데이터 미연결'), findsOneWidget);
      await tester.ensureVisible(find.text('PSR'));
      await tester.tap(find.text('PSR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('계산식 · PSR = 10.00배'), findsOneWidget);
      expect(find.byType(Dialog), width >= 600 ? findsOneWidget : findsNothing);
      expect(
        find.byType(DraggableScrollableSheet),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      if (width < 600) {
        await tester.tap(find.text('PSR'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        await tester.tap(find.text('PSR'));
        await tester.pumpAndSettle();
        final handle =
            tester.getTopLeft(find.byType(BottomSheet)) + const Offset(100, 16);
        await tester.dragFrom(handle, const Offset(0, 800));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      }
    });
  }
}
