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
      expect(find.text('새 공시가 오면 여기에 모아드려요'), findsOneWidget);
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
