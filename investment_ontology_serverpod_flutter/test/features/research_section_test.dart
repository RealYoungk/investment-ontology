import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/research/research_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/research/treasury_movement.dart';

Widget app(Widget child) => MaterialApp(
  theme: buildAppTheme(ledgerBrand),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets('queued acquisition retries and displays the stored result', (
    t,
  ) async {
    var calls = 0;
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00126380',
          kinds: const ['treasury'],
          loader: (_, _) async => jsonEncode(
            ++calls == 1
                ? {
                    'state': 'collecting',
                    'retryAfterSeconds': 5,
                    'message': '수집 대기 중',
                    'rows': [],
                  }
                : {'state': 'ready', 'rows': []},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('수집 대기 중'), findsOneWidget);
    expect(find.text('수집 범위에 해당 보고가 없습니다.'), findsNothing);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('수집 범위에 해당 보고가 없습니다.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('leaving a pending company cancels the retry timer', (t) async {
    var calls = 0;
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00126380',
          kinds: const ['treasury'],
          loader: (_, _) async {
            calls++;
            return jsonEncode({
              'state': 'collecting',
              'retryAfterSeconds': 5,
              'rows': [],
            });
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
    expect(calls, 1);
  });

  test('plain wording keeps disposal separate from cancellation', () {
    expect(
      researchPlainTitle({'api': 'tsstkDpDecsn', 'reason': '독립이사 보수 지급'}),
      '보상으로 회사 보유 주식을 지급할 계획',
    );
    expect(
      researchPlainTitle({'api': 'tsstkDpDecsn', 'reason': '운영자금'}),
      '회사 보유 주식을 팔거나 넘길 계획',
    );
    expect(
      researchPlainTitle({'api': 'tsstkAqDecsn', 'reason': '소각'}),
      '없앨 목적으로 자기주식을 살 계획',
    );
    final overview = researchOverview('treasury', {
      'state': 'ready',
      'rows': [
        {'date': '2025-01-01', 'api': 'tsstkAqDecsn', 'amount': '100'},
        {'date': '2026-01-01', 'api': 'tsstkDpDecsn', 'shares': '500'},
      ],
    });
    expect(overview, contains('500주'));
    expect(overview, contains('수집 2건'));
    expect(overview, isNot(contains('100원')));
  });
  testWidgets(
    'normal company view hides management and previews other categories',
    (t) async {
      await t.pumpWidget(
        app(
          ResearchSection(
            corpCode: 'test',
            kinds: const ['capital', 'treasury'],
            loader: (_, kind) async => jsonEncode({
              'state': 'ready',
              'provider': 'DART',
              'collectedAt': '2026-10-01',
              'rows': [
                {
                  'date': '2026-01-01',
                  'api': 'tsstkAqDecsn',
                  'receipt': '20260101000001',
                  'shares': '500',
                },
              ],
            }),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('500주 · 수집 1건'), findsNWidgets(2));
      expect(find.text('출처 · 자료 상태'), findsNothing);
      expect(find.text('자료 수집·갱신'), findsNothing);
    },
  );

  testWidgets('unconnected feeds stay behind status disclosure', (t) async {
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00164779',
          showManagement: true,
          kinds: const ['capital', 'consensus'],
          loader: (_, kind) async => jsonEncode({
            'state': 'notCollected',
            'message': 'missing $kind',
            'rows': [],
          }),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('실적 전망·목표주가'), findsNothing);
    expect(find.text('missing capital'), findsOneWidget);
    await t.tap(find.text('출처 · 자료 상태'));
    await t.pumpAndSettle();
    await t.tap(find.text('미연결 항목 보기'));
    await t.pumpAndSettle();
    await t.tap(find.text('실적 전망·목표주가'));
    await t.pumpAndSettle();
    expect(find.text('missing consensus'), findsOneWidget);
    await t.tap(find.text('미연결 항목 접기'));
    await t.pumpAndSettle();
    expect(find.text('missing capital'), findsOneWidget);
    expect(find.text('실적 전망·목표주가'), findsNothing);
  });

  testWidgets('changing company tab cannot retain an unrelated feed', (
    t,
  ) async {
    Future<String> load(String _, String kind) async => jsonEncode({
      'state': 'notCollected',
      'message': 'missing $kind',
      'rows': [],
    });
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00126380',
          kinds: const ['treasury'],
          loader: load,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('missing treasury'), findsOneWidget);
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00126380',
          kinds: const ['insiders', 'majorHoldings'],
          loader: load,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('missing treasury'), findsNothing);
    expect(find.text('missing insiders'), findsOneWidget);
  });
  testWidgets(
    'captured DART decisions render on mobile without lost share classes',
    (t) async {
      t.view.physicalSize = const Size(320, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final name in ['samsung-treasury', 'skhynix-capital']) {
        final fixture = jsonDecode(
          File('test/fixtures/research/$name.json').readAsStringSync(),
        );
        for (final raw in fixture['rows'] as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          await t.pumpWidget(app(ResearchEventCard(row: row)));
          expect(find.text('공시 원문'), findsNothing);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.textContaining('결정일'), findsNothing);
          await t.ensureVisible(
            find.byKey(ValueKey('conditions-${row['receipt']}')),
          );
          await t.tap(find.byKey(ValueKey('conditions-${row['receipt']}')));
          await t.pumpAndSettle();
          expect(
            find.textContaining('결정일'),
            row['decisionDate'] == null ? findsNothing : findsOneWidget,
          );
          if (row['otherAmount'] != null) {
            expect(find.textContaining('기타주식 예정금액'), findsOneWidget);
          }
          if (row['api'] == 'exbdIsDecsn') {
            expect(find.textContaining('교환가'), findsOneWidget);
            expect(find.text('교환가 111,180원 / 주'), findsOneWidget);
            expect(find.textContaining('전환·행사가'), findsNothing);
          }
          expect(t.takeException(), isNull, reason: '${row['receipt']}');
        }
      }
    },
  );
  test('treasury null is not zero and balance is exact', () {
    final r = TreasuryStockEntry(
      reportId: 1,
      companyId: 1,
      bsnsYear: 2025,
      ord: 0,
      isTotal: true,
      sharesBegin: BigInt.from(100),
      acquired: BigInt.from(30),
      disposed: BigInt.from(10),
      retired: BigInt.from(20),
      sharesEnd: BigInt.from(100),
    );
    expect(treasuryBalances(r), true);
    r.acquired = null;
    expect(treasuryBalances(r), false);
  });
  test('treasury starts at populated total, not an empty trust subtotal', () {
    final rows = [
      TreasuryStockEntry(
        reportId: 1,
        companyId: 1,
        bsnsYear: 2025,
        ord: 0,
        isTotal: true,
        method3: '소계',
      ),
      TreasuryStockEntry(
        reportId: 1,
        companyId: 1,
        bsnsYear: 2025,
        ord: 1,
        isTotal: false,
        sharesEnd: BigInt.from(20),
      ),
      TreasuryStockEntry(
        reportId: 1,
        companyId: 1,
        bsnsYear: 2025,
        ord: 2,
        isTotal: true,
        method1: '총계',
        sharesEnd: BigInt.from(20),
      ),
    ];
    expect(treasuryDefaultIndex(rows), 2);
    expect(treasuryHasValues(rows.first), false);
    rows[2].sharesEnd = BigInt.zero;
    expect(treasuryDefaultIndex(rows), 2);
  });
  testWidgets('ownership change is not labelled buy and source is present', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      app(
        const ResearchEventCard(
          row: {
            'date': '2026-09-01',
            'reporter': '주주',
            'holdings': '1000',
            'change': '-200',
            'receipt': '20260901000001',
            'reason': '증여',
          },
        ),
      ),
    );
    expect(find.text('-200주'), findsOneWidget);
    expect(find.text('공시 원문'), findsNothing);
    await t.tap(find.text('보고자 주주'));
    await t.pumpAndSettle();
    expect(find.text('1,200 → 1,000주'), findsOneWidget);
    expect(find.text('공시 원문'), findsOneWidget);
    expect(find.textContaining('매도'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('uncollected and verified empty have different states', (
    t,
  ) async {
    await t.pumpWidget(
      app(
        ResearchSection(
          corpCode: '00126380',
          kinds: const ['capital', 'treasury'],
          loader: (_, k) async => jsonEncode(
            k == 'capital'
                ? {'state': 'notCollected', 'message': '수집 전', 'rows': []}
                : {
                    'state': 'ready',
                    'provider': 'DART',
                    'collectedAt': '2026-09-01',
                    'rows': [],
                  },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('수집 전'), findsOneWidget);
    await t.tap(find.text('자사주'));
    await t.pumpAndSettle();
    expect(find.text('수집 범위에 해당 보고가 없습니다.'), findsOneWidget);
    expect(find.text('자료 수집·갱신'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
