import '../support/shad_test_host.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/charts/app_charts.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/bond_trends_card.dart';

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
Map<String, dynamic> feed({String amount = '6000000000'}) => {
  'state': 'ready',
  'collectedPeriods': 2,
  'expectedPeriods': 3,
  'points': [
    {
      'periodEnd': '2024-12-31',
      'receipt': '20250301000001',
      'sourceUrl':
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250301000001',
      'state': 'verified',
      'balanceWon': '10000000000',
      'entries': [],
    },
    {
      'periodEnd': '2025-12-31',
      'receipt': '20260401000001',
      'sourceUrl':
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260401000001',
      'state': 'notCollected',
      'balanceWon': null,
      'entries': [],
    },
    {
      'periodEnd': '2026-06-30',
      'receipt': '20260801000001',
      'sourceUrl':
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260801000001',
      'state': 'verified',
      'balanceWon': amount,
      'potentialShares': '6000000',
      'netDecreaseWon': null,
      'fromDate': '2025-12-31',
      'entries': [
        {
          'series': '제2회차',
          'issueDate': '2023-01-01',
          'stockKind': '보통주',
          'balance': amount,
          'unit': '원',
          'price': '1000',
          'shares': '6000000',
          'evidence': '제2회차 | 2023.01.01 | 보통주 | 6,000,000,000',
        },
      ],
    },
  ],
  'changes': [
    {
      'series': '제2회차',
      'issueDate': '2023-01-01',
      'stockKind': '보통주',
      'fromDate': '2024-12-31',
      'toDate': '2026-06-30',
      'beforeWon': '10000000000',
      'afterWon': amount,
      'netDecreaseWon': '4000000000',
      'unexplainedDecreaseWon': '4000000000',
    },
  ],
};
Widget app(BondTrendsCard card) => MaterialApp(
  theme: theme,
  home: Scaffold(body: SingleChildScrollView(child: card)),
);

void main() {
  testWidgets(
    'recorded DART specimen: 250 to 227 eok, 23 eok net decrease with unconfirmed cause',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = File('test/fixtures/bonds/primary_trends.json')
          .readAsStringSync();
      const boundary = ValueKey('bond-primary-preview');
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: RepaintBoundary(
                key: boundary,
                child: SingleChildScrollView(
                  child: BondTrendsCard(
                    corpCode: '00147082',
                    loader: (_) async => source,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('227억원'), findsOneWidget);
      expect(find.text('23억원 순감소'), findsOneWidget);
      expect(find.textContaining('원인 미확인 순감소 23억원'), findsOneWidget);
      expect(
        tester
            .widget<AppLineChart>(find.byType(AppLineChart))
            .series
            .single
            .values,
        [250.0, 227.0],
      );
      expect(tester.takeException(), isNull);
      final output = Platform.environment['BOND_PREVIEW_OUTPUT'];
      if (output != null) {
        await tester.runAsync(() async {
          final render = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundary),
          );
          final pixels = await render.toImage(pixelRatio: 1);
          final png = await pixels.toByteData(format: ui.ImageByteFormat.png);
          final file = File(output);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          pixels.dispose();
        });
      }
    },
  );
  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'dated amounts, unknown cause, source disclosure and missing chart gap at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          shadTestHost(
            app(
              BondTrendsCard(
                corpCode: '00000001',
                loader: (_) async => jsonEncode(feed()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('60억원'), findsOneWidget);
        expect(find.text('비교 불가'), findsOneWidget);
        expect(find.textContaining('원인 미확인 순감소 40억원'), findsOneWidget);
        expect(find.textContaining('보고서 수집 2 / 3'), findsOneWidget);
        final chart = tester.widget<AppLineChart>(find.byType(AppLineChart));
        expect(chart.series.single.values, [100.0, null, 60.0]);
        final selector = find.descendant(
          of: find.byKey(const ValueKey('bond-series-selector')),
          matching: find.byWidgetPredicate((widget) => widget is ShadSelect),
        );
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text('제2회차 · 발행 2023-01-01 · 보통주').last);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AppLineChart>(find.byType(AppLineChart))
              .series
              .single
              .values,
          [null, null, 60.0],
        );
        await tester.ensureVisible(find.text('보고서별 수량과 원문 근거'));
        await tester.tap(find.text('보고서별 수량과 원문 근거'));
        await tester.pumpAndSettle();
        expect(find.textContaining('제2회차 | 2023.01.01'), findsOneWidget);
        expect(find.text('2025-12-31 · 미수집'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('failed read retries and public visitors cannot collect', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      shadTestHost(
        app(
          BondTrendsCard(
            corpCode: '00000001',
            loader: (_) async {
              if (calls++ == 0) throw StateError('offline');
              return jsonEncode(feed());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('불러오지 못'), findsWidgets);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('60억원'), findsOneWidget);
    expect(find.text('전환사채 추이 원문 수집'), findsNothing);
  });
  testWidgets('old company response cannot overwrite a new company', (
    tester,
  ) async {
    final old = Completer<String>();
    Future<String> load(String code) => code == 'old'
        ? old.future
        : Future.value(jsonEncode(feed(amount: '2000000000')));
    await tester.pumpWidget(
      shadTestHost(app(BondTrendsCard(corpCode: 'old', loader: load))),
    );
    await tester.pumpWidget(
      shadTestHost(app(BondTrendsCard(corpCode: 'new', loader: load))),
    );
    await tester.pumpAndSettle();
    old.complete(jsonEncode(feed()));
    await tester.pumpAndSettle();
    expect(find.text('20억원'), findsOneWidget);
    expect(find.text('60억원'), findsNothing);
  });
}
