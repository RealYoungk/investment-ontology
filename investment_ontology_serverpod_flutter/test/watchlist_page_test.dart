import 'package:shad/shad.dart';

import 'support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/watchlist/watchlist_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/watchlist/watchlist_store.dart';

final theme = buildAppTheme(
  AppBrand(
    colors: ledgerBrand.colors,
    shape: ledgerBrand.shape,
    typography: const AppTypography(
      displayBase: TextStyle(),
      bodyBase: TextStyle(),
      numericBase: TextStyle(),
      labelBase: TextStyle(),
    ),
  ),
);
void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('search can be typed, cleared and reopened at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = WatchlistStore(
        fetch: () async => WatchlistView(
          companies: [],
          updates: [],
          limit: 3,
          paid: false,
          scanStatus: 'waiting',
          pushConfigured: false,
          workerEnabled: false,
        ),
        addCompany: (_) async {},
        removeCompany: (_) async {},
      );
      store.setOwner('fixture');
      await tester.pump();
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: theme,
            home: Scaffold(body: WatchlistPage(store: store)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (width < 600) {
        await tester.tap(find.text('종목 0'));
        await tester.pumpAndSettle();
      }
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('종목 추가').first);
        await tester.pumpAndSettle();
        final input = find.byType(EditableText);
        expect(input, findsOneWidget);
        expect(tester.widget<EditableText>(input).focusNode.hasFocus, isTrue);
        for (final text in ['삼', '삼성', '', '005930', '']) {
          tester.testTextInput.enterText(text);
          await tester.pump();
          expect(tester.widget<EditableText>(input).controller.text, text);
          expect(tester.testTextInput.hasAnyClients, isTrue);
        }
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ShadIconButton && w.semanticLabel == '검색 닫기',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'empty watchlist explains limits and unavailable push at mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = WatchlistStore(
        fetch: () async => WatchlistView(
          companies: [],
          updates: [],
          limit: 3,
          paid: false,
          scanStatus: 'waiting',
          pushConfigured: false,
          workerEnabled: false,
        ),
        addCompany: (_) async {},
        removeCompany: (_) async {},
      );
      store.setOwner('fixture');
      await tester.pump();
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: theme,
            home: Scaffold(body: WatchlistPage(store: store)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('무료 플랜 · 최대 3개 기업'), findsOneWidget);
      expect(find.text('새 소식이 오면 여기에 모아드려요'), findsOneWidget);
      await tester.tap(find.text('종목 0'));
      await tester.pumpAndSettle();
      expect(find.text('첫 기업을 담아보세요'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              (w is Tooltip && w.message == '알림 설정') ||
              (w is ShadIconButton && w.semanticLabel == '알림 설정'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
