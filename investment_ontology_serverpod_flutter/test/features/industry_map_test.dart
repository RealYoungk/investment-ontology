import '../support/shad_test_host.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/market_map/market_cap_treemap_section.dart';

MarketCapNode node(
  String code,
  String name, {
  List<MarketCapNode> children = const [],
  int count = 1,
}) => MarketCapNode(
  code: code,
  name: name,
  marketCap: BigInt.from(100000000000),
  companyCount: count,
  children: children,
);
MarketCapTreemap map(String? section, {String suffix = ''}) => MarketCapTreemap(
  baseDate: DateTime.utc(2026, 9, 30),
  sectionCode: section,
  sectionName: section == null ? null : '제조업',
  total: BigInt.from(100000000000),
  unlinkedSecurityCount: 0,
  unlinkedMarketCap: BigInt.zero,
  industryRevision: 'KSIC 11',
  nodes: section == null
      ? [node('C', '제조업', count: 35)]
      : [
          node(
            '26',
            '전자 부품, 컴퓨터, 영상, 음향 및 통신장비 제조업',
            count: 35,
            children: [
              for (var i = 0; i < 35; i++) node('corp$i', '검증기업$i$suffix'),
            ],
          ),
        ],
);
Widget app(
  IndustryMapLoader loader,
  ValueChanged<String> select, {
  int version = 0,
  Market? market,
}) => MaterialApp(
  theme: buildAppTheme(ledgerBrand),
  home: Scaffold(
    body: SingleChildScrollView(
      child: MarketCapTreemapSection(
        market: market,
        loader: loader,
        onSelectCompany: select,
        dataVersion: version,
      ),
    ),
  ),
);
Future<void> click(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('KSIC drilldown, list pagination, breadcrumbs at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <String>[];
      await tester.pumpWidget(
        shadTestHost(app((section, _) async => map(section), selected.add)),
      );
      await tester.pumpAndSettle();
      expect(find.text('검증기업0'), findsNothing);
      await click(tester, 'C 제조업 →');
      expect(find.text('검증기업0'), findsNothing);
      await click(
        tester,
        '26 전자 부품, 컴퓨터, 영상, 음향 및 통신장비 제조업 →',
      );
      expect(find.text('검증기업34 →'), findsNothing);
      await click(tester, '더 보기 (5개 남음)');
      await click(tester, '검증기업34 →');
      expect(selected, ['corp34']);
      await click(tester, 'C 제조업');
      expect(find.text('중분류 목록 · 시가총액 순'), findsOneWidget);
      await click(tester, '전체 업종');
      expect(find.text('대분류 목록 · 시가총액 순'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('ingest refresh preserves selected division', (tester) async {
    String suffix = '';
    Future<MarketCapTreemap> loader(String? section, Market? _) async =>
        map(section, suffix: suffix);
    await tester.pumpWidget(shadTestHost(app(loader, (_) {})));
    await tester.pumpAndSettle();
    await click(tester, 'C 제조업 →');
    await click(tester, '26 전자 부품, 컴퓨터, 영상, 음향 및 통신장비 제조업 →');
    suffix = '갱신';
    await tester.pumpWidget(shadTestHost(app(loader, (_) {}, version: 1)));
    await tester.pumpAndSettle();
    expect(find.text('기업 목록 · 시가총액 순'), findsOneWidget);
    expect(find.text('검증기업0갱신 →'), findsOneWidget);
  });
  testWidgets('late section response cannot replace navigation back to all', (
    tester,
  ) async {
    final pending = Completer<MarketCapTreemap>();
    await tester.pumpWidget(
      shadTestHost(
        app(
          (section, _) =>
              section == null ? Future.value(map(null)) : pending.future,
          (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('C 제조업 →'));
    await tester.tap(find.text('C 제조업 →'));
    await tester.pump();
    await tester.ensureVisible(find.text('전체 업종'));
    await tester.tap(find.text('전체 업종'));
    await tester.pumpAndSettle();
    pending.complete(map('C'));
    await tester.pumpAndSettle();
    expect(find.text('대분류 목록 · 시가총액 순'), findsOneWidget);
    expect(find.text('중분류 목록 · 시가총액 순'), findsNothing);
  });
}
