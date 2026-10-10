import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/app/app_shell.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';

void main() {
  testWidgets('mobile menu hides down and returns up', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(location: state.uri, child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => ListView(
                children: const [SizedBox(height: 3000, child: Text('긴 본문'))],
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp.router(
          theme: buildAppTheme(ledgerBrand),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final menu = find.byWidgetPredicate(
      (w) => w is ShadIconButton && w.semanticLabel == '전체 메뉴',
    );
    expect(menu.hitTestable(), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(menu.hitTestable(), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(menu.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('nested route retains navigation semantics at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                AppShell(location: state.uri, child: child),
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const Text('본문')),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp.router(
            theme: buildAppTheme(ledgerBrand),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (w) => w is ShadIconButton && w.semanticLabel == '기업 · 인물 · 메뉴 검색',
      );
      if (width < 960) {
        expect(
          tester.getSemantics(search).getSemanticsData().label,
          contains('기업 · 인물 · 메뉴 검색'),
        );
        final menu = find.byWidgetPredicate(
          (w) => w is ShadIconButton && w.semanticLabel == '전체 메뉴',
        );
        expect(
          tester
              .getSemantics(menu)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.byType(ShadSheet), findsOneWidget);
        expect(find.text('기업 찾기'), findsOneWidget);
        expect(
          find.widgetWithText(ShadSidebarMenuButton, '기업 찾기'),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ShadSheet), findsNothing);
      } else {
        expect(
          tester.getSemantics(find.text('기업 찾기')).getSemanticsData().label,
          contains('기업 찾기'),
        );
      }
      if (width >= 960) {
        final label = find.text('기업 찾기');
        final button = find
            .ancestor(of: label, matching: find.byType(ShadButton))
            .first;
        expect(
          tester.getCenter(label).dx,
          closeTo(tester.getCenter(button).dx, 0.5),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(shadTestHost(const SizedBox()));
      router.dispose();
      semantics.dispose();
    });
  }
}
