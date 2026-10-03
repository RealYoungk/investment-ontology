import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/home_concept_gallery.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('home concepts fit and keep reports scrollable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(serviceBrand),
            home: const HomeConceptGallery(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['A · 읽는 홈', 'B · 발견하는 홈', 'C · 함께 보는 홈']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('새로 들어온 보고서'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadToggle, '정정'));
        await tester.pumpAndSettle();
        expect(find.text('반기보고서 · 2026.06 · 합성'), findsNothing);
        await tester.tap(find.widgetWithText(ShadToggle, '전체'));
        await tester.pumpAndSettle();
        expect(find.text('반기보고서 · 2026.06 · 합성'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
