import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/power_product_lesson.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/power_components_guide.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/revenue_composition.dart';

const table = '''2) 주요 제품 매출 비중
구분 | 2024년 | 2025년 | 2023년
PSU | 72.5% | 66.3% | 73.6%
필름콘덴서 | 26.4% | 31.2% | 25.7%
증착필름 | 1.1% | 2.5% | 0.7%
합계 | 100.0% | 100.0% | 100.0%''';
BusinessUnderstanding profile({
  String receipt = 'current',
  String status = 'ready',
}) => BusinessUnderstanding(
  status: status,
  products: [],
  bsnsYear: 2025,
  rceptNo: receipt,
  ruleVersion: 30007,
);
BusinessContent doc({String text = table, String title = '2. 주요 제품 및 서비스'}) =>
    BusinessContent(
      bsnsYear: 2025,
      rceptNo: 'current',
      title: '사업',
      sections: [BusinessSection(title: title, text: text)],
      charCount: text.length,
      years: [2025],
    );
void main() {
  test(
    'uses printed current-year column, not first/last year or financial totals',
    () {
      final result = PowerProductLesson.resolve(profile(), doc())!;
      expect(result.shares.map((e) => e.share), [66.3, 31.2, 2.5]);
      expect(result.year, 2025);
    },
  );
  test(
    'fails closed on stale receipts, unsupported families and invalid totals',
    () {
      expect(
        PowerProductLesson.resolve(profile(receipt: 'old'), doc()),
        isNull,
      );
      expect(
        PowerProductLesson.resolve(profile(status: 'stale'), doc()),
        isNull,
      );
      expect(PowerProductLesson.resolve(profile(), doc(title: '원재료')), isNull);
      expect(
        PowerProductLesson.resolve(
          profile(),
          doc(text: table.replaceAll('필름콘덴서', 'MLCC')),
        ),
        isNull,
      );
      expect(
        PowerProductLesson.resolve(
          profile(),
          doc(text: table.replaceFirst('66.3%', '60.3%')),
        ),
        isNull,
      );
      expect(
        PowerProductLesson.resolve(
          profile(),
          doc(text: table.replaceFirst('2025년', '2022년')),
        ),
        isNull,
      );
      expect(
        PowerProductLesson.resolve(
          profile(),
          doc(text: table.split('합계').first),
        ),
        isNull,
      );
    },
  );
  for (final width in [320.0, 1280.0]) {
    testWidgets('optical guide has four working pages at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: PowerComponentsGuide(includeOptical: true),
            ),
          ),
        ),
      );
      expect(find.text('1 / 4'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(find.text('다음 →'));
        await tester.tap(find.text('다음 →'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('4 / 4'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다음 →'))
            .onPressed,
        isNull,
      );
    });
  }
  for (final width in [320.0, 1280.0]) {
    testWidgets('power lesson and revenue fit and navigate at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const PowerComponentsGuide(),
                  PrintedProductMix(
                    mix: PowerProductLesson.resolve(profile(), doc())!,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('프린터 → 전원 보드 → 작은 부품 순서로 확대해 보세요.'), findsOneWidget);
      expect(find.text('66.3%'), findsOneWidget);
      expect(find.text('2. 증착필름'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('다음 →'));
      await tester.tap(find.text('다음 →'));
      await tester.pumpAndSettle();
      expect(find.text('증착필름은 필름콘덴서의 핵심 재료입니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('다음 →'));
      await tester.tap(find.text('다음 →'));
      await tester.pumpAndSettle();
      expect(find.text('같은 전자기기 안에서도 판매 단위가 다릅니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('이전'));
      await tester.tap(find.text('이전'));
      await tester.pumpAndSettle();
      expect(find.text('증착필름은 필름콘덴서의 핵심 재료입니다.'), findsOneWidget);
    });
  }
}
