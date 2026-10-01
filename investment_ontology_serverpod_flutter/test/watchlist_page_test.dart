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
        MaterialApp(
          theme: theme,
          home: Scaffold(body: WatchlistPage(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('무료 · 0/3개'), findsOneWidget);
      expect(find.textContaining('아직 관심종목이 없습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
