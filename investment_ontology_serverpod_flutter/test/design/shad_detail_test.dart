import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/company_section_heading.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

void main() {
  testWidgets(
    'detail has one close control and Escape keeps the parent mounted',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: const Scaffold(
              body: CompanySectionHeading('매출', help: '기간과 단위를 확인합니다.'),
            ),
          ),
        ),
      );
      final parent = tester.element(find.byType(CompanySectionHeading));
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.byType(ShadSheet), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ShadSheet), findsNothing);
      expect(tester.element(find.byType(CompanySectionHeading)), same(parent));
      expect(tester.takeException(), isNull);
    },
  );
}
