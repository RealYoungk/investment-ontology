import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/app/app_shell.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.macOS,
  ]) {
    testWidgets('search icon immediately requests keyboard on $platform', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                AppShell(location: state.uri, child: const SizedBox()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: buildAppTheme(ledgerBrand).copyWith(platform: platform),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.byTooltip('기업 · 인물 · 메뉴 검색'));
        // No additional frame or input-field tap is needed for the request.
        expect(tester.testTextInput.isVisible, isTrue);
        await tester.pumpAndSettle();
        final field = tester.widget<EditableText>(find.byType(EditableText));
        expect(field.focusNode.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(field.focusNode.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);
        expect(
          tester.widget<TextField>(find.byType(TextField)).textInputAction,
          TextInputAction.search,
        );
        // Retapping an already focused field must request the keyboard again.
        tester.testTextInput.hide();
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('기업 · 인물 · 메뉴 검색'));
      await tester.pumpAndSettle();
      // Switching to the desktop header disposes the mounted mobile editor.
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
