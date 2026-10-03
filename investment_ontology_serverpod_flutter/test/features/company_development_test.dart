import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/business/company_development.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_development_section.dart';

void main() {
  test('acquisition snapshot never leaks into other companies', () {
    expect(CompanyDevelopment.forCompany('00317210'), isNotNull);
    expect(
      CompanyDevelopment.forCompany('00765569')?.headline,
      contains('AI 반도체'),
    );
    expect(CompanyDevelopment.forCompany('00126380'), isNull);
  });
  for (final width in [320.0, 1280.0]) {
    testWidgets('research remains readable at $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final development = CompanyDevelopment.forCompany('00317210')!;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CompanyDevelopmentSection(development: development),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final toggle = find.text('데이터센터·광통신 배경 이해하기');
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('CPO란?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('CPO란?'), findsNothing);
    });
  }
}
