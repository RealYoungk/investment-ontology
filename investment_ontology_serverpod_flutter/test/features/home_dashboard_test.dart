import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/home_dashboard.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1050.0, 1440.0]) {
    testWidgets(
      'live overview preserves dates, rates, login and layout at $width',
      (t) async {
        t.view.physicalSize = Size(width, 1050);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final points = [
          IndexPoint(date: DateTime(2026, 10, 1), value: 4.1),
          IndexPoint(date: DateTime(2026, 10, 2), value: 4.2),
        ];
        await t.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(serviceBrand),
              home: Scaffold(
                body: HomeDashboard(
                  search: const Text('검색'),
                  market: () async => [],
                  filings: () async => [],
                  macro: () async => [
                    MacroSeriesView(
                      seriesId: 'DGS2',
                      name: '2년',
                      group: '금리',
                      unit: '%',
                      rate: true,
                      points: points,
                      status: 'ready',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('+0.10%p'), findsOneWidget);
        expect(find.text('2026.10.02 · %'), findsOneWidget);
        expect(find.textContaining('로그인하면'), findsOneWidget);
        expect(find.textContaining('합성'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
  }
}
