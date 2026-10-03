import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/widgets/index_trend.dart';

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('Shows dated close and signed point changes at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final date = DateTime.utc(2026, 10, 1);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(
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
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: IndexTrend(
                  load: (_) async => [
                    IndexHistory(
                      series: 'KOSPI',
                      name: '코스피',
                      stride: 1,
                      points: [IndexPoint(date: date, value: 3100)],
                      dayBase: IndexPoint(
                        date: date.subtract(const Duration(days: 1)),
                        value: 3000,
                      ),
                      weekBase: IndexPoint(
                        date: date.subtract(const Duration(days: 7)),
                        value: 3200,
                      ),
                      lastChangeRate: 3.33,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3,100'), findsOneWidget);
      expect(find.text('2026.10.01 종가'), findsOneWidget);
      expect(find.text('+100pt'), findsOneWidget);
      expect(find.text('-100pt'), findsOneWidget);
      expect(find.text('+3.33%'), findsOneWidget);
      expect(find.text('비교 종가 없음'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
