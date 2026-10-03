import 'package:flutter/services.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

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
        shadTestHost(
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
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('전체 지표 보기'));
      await tester.tap(find.text('전체 지표 보기'));
      await tester.pumpAndSettle();
      expect(find.text('예상 EPS·성장률 데이터 미연결'), findsOneWidget);
      await tester.ensureVisible(find.text('PSR'));
      await tester.tap(find.text('PSR'));
      await tester.pumpAndSettle();
      expect(find.text('계산 방법'), findsOneWidget);
      expect(find.text('10.00배'), findsWidgets);
      expect(find.byType(ShadSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              (w is Tooltip && w.message == '닫기') ||
              (w is ShadIconButton && w.semanticLabel == '닫기'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
      expect(find.byType(ShadSheet), findsNothing);
      if (width < 600) {
        await tester.tap(find.text('PSR'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        await tester.tap(find.text('PSR'));
        await tester.pumpAndSettle();
        // shad sheets dismiss by Escape/back/close; drag-to-dismiss is not provided.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ShadSheet), findsNothing);
      }
    });
  }
}
