import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/widgets/market_summary.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Market scope selects, clears and wraps at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Market? selected;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, update) => MarketSummary(
                    overview: null,
                    selected: selected,
                    onSelect: (market) => update(() => selected = market),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('시장 요약 불러오는 중…'), findsOneWidget);
      await tester.tap(find.text('코스닥'));
      await tester.pumpAndSettle();
      expect(selected, Market.kosdaq);
      await tester.tap(find.text('코스닥'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text('유가'));
      await tester.pumpAndSettle();
      expect(selected, Market.kospi);
      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
