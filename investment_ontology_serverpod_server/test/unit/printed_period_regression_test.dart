import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';

void main() {
  final text = File('test/fixtures/business_tables/samkee-2026-half.txt')
      .readAsStringSync();
  test('삼기 반기 매출은 오름차순 연도 머리글의 마지막 기간이다', () {
    final rows = SegmentRevenue.parse(text);
    expect(rows.map((r) => (r.label, r.amount)), [
      ('기구부품', 42055313.0),
      ('전장부품', 17590074.0),
      ('부산물', 19639278.0),
      ('기타', 593342.0),
    ]);
    expect(rows.every((r) => r.unit == '천원'), isTrue);
    expect(rows.every((r) => r.evidence.contains('(별도)')), isTrue);
  });
  test('금액과 비율 결합 셀도 오름차순의 실제 최신 기간을 고른다', () {
    const source = '''
(별도) (단위: 천원)
부문 | 2024년 매출액(비율) | 2025년 매출액(비율) | 2026년 반기 매출액(비율)
제품 | 100 (100%) | 200 (100%) | 300 (100%)
합계 | 100 | 200 | 300
''';
    expect(SegmentRevenue.parse(source).single.amount, 300);
  });
  test('삼기 원문 수주·설비·비중·인력·권리 표는 검산 사실과 구분해 보존한다', () {
    final tables = BusinessTableInsights.parse(text, reportPeriod: '2026 반기');
    expect(
      tables.map((t) => t.topic),
      containsAll([
        'orderSource',
        'productionSource',
        'materialShareSource',
        'facilitiesSource',
        'researchStaffSource',
        'intellectualPropertySource',
        'salesChannelSource',
      ]),
    );
    final order = tables.singleWhere((t) => t.topic == 'orderSource');
    final materials = tables.singleWhere(
      (t) => t.topic == 'materialShareSource',
    );
    expect(
      materials.measures
          .where((m) => m.period.startsWith('2026'))
          .map((m) => m.value),
      [89, 3, 8],
    );
    expect(materials.measures, hasLength(9));
    expect(
      tables.singleWhere((t) => t.topic == 'facilitiesSource').measures,
      hasLength(7),
    );
    expect(
      tables
          .singleWhere((t) => t.topic == 'researchStaffSource')
          .measures
          .map((m) => m.value),
      [1, 1, 1, 6],
    );
    expect(
      tables
          .singleWhere((t) => t.topic == 'intellectualPropertySource')
          .measures
          .fold<double>(0, (s, m) => s + m.value),
      14,
    );
    expect(order.measures.map((m) => m.value), [535943, 433448, 146838]);
    expect(order.evidence, contains('535,943 | 433,448 | 146,838'));
    final routes = tables.singleWhere((t) => t.topic == 'salesChannelSource');
    expect(routes.evidence, contains('PEOPLEWORKS, NEXTSTAR ENERGY'));
    expect(routes.evidence, contains('17,590,074 | 22%'));
    expect(routes.measures.where((m) => m.unit == '%').map((m) => m.value), [
      52,
      22,
      25,
      1,
    ]);
    final verifiedComponents = OrderFacts.parse(text);
    expect(verifiedComponents.map((r) => (r.total, r.delivered, r.backlog)), [
      (10256.0, 6095.0, 4161.0),
    ]);
    expect(
      verifiedComponents.any((r) => r.evidence.startsWith('합 계 |')),
      isFalse,
    );
    expect(tables.where((t) => t.topic == 'productionSource'), hasLength(2));
    final production = tables
        .where((t) => t.topic == 'productionSource')
        .toList();
    expect(
      production
          .expand((t) => t.measures)
          .where((m) => m.metric == '가동률')
          .map((m) => m.value),
      [50],
    );
    expect(
      production.expand((t) => t.measures).every((m) => m.period == '2026 반기'),
      isTrue,
    );
    expect(
      RndFacts.parse(text, bsnsYear: 2026)!.totals.single.values.first,
      1130222,
    );
  });

  test('a verified order component cannot hide an unverified printed total', () {
    const source =
        '(단위 : 백만원)\n품목 | 수주총액 | 기납품액 | 수주잔고\n제품 | 10 | 3 | 7\n합계 | 100 | 30 | 90';
    final raw = BusinessTableInsights.parse(source, reportPeriod: '2026 반기');
    final order = raw.singleWhere((t) => t.topic == 'orderSource');
    expect(order.evidence, contains('합계 | 100 | 30 | 90'));
    expect(order.measures.map((m) => m.value), [100, 30, 90]);
    expect(OrderFacts.parse(source).single.backlog, 7);
    final reconciled = source.replaceFirst(
      '합계 | 100 | 30 | 90',
      '합계 | 100 | 30 | 70',
    );
    expect(
      BusinessTableInsights.parse(
        reconciled,
        reportPeriod: '2026 반기',
      ).where((t) => t.topic == 'orderSource'),
      isEmpty,
    );
    expect(OrderFacts.parse(reconciled).single.backlog, 70);
  });
  for (final year in [2022, 2023, 2024, 2025]) {
    test('삼기 $year 실제 저장 본문 표가 현재 기간과 섞이지 않는다', () {
      final source = File('test/fixtures/business_tables/samkee-$year.txt')
          .readAsStringSync();
      final tables = BusinessTableInsights.parse(
        source,
        reportPeriod: '$year 연간',
      );
      expect(tables, isNotEmpty);
      expect(
        tables.expand((t) => t.measures).every((m) => m.value.isFinite),
        isTrue,
      );
      final rnd = RndFacts.parse(source, bsnsYear: year);
      final revenues = SegmentRevenue.parse(source);
      expect(
        revenues.length,
        year == 2022
            ? 2
            : year == 2025
            ? 4
            : 3,
      );
      expect(revenues.first.amount, switch (year) {
        2022 => 81947820,
        2023 => 66510493,
        2024 => 60491564,
        _ => 56864809,
      });
      final production = ProductionFacts.parse(source);
      expect(
        production.map((r) => r.label).toSet(),
        hasLength(production.length),
      );
      expect(production.any((r) => r.label.contains('고진공 주조공정')), isTrue);
      expect(production.any((r) => r.label.contains('가공 공정')), isTrue);
      if (year == 2025) {
        expect(rnd!.years.first, 2025);
        expect(rnd.totals.single.values.first, 2681072);
        expect(rnd.ratio!.values.first, 3.1);
      }
    });
  }
  test('삼기 생산의 과거값은 반기 값으로 저장하지 않는다', () {
    final rows = ProductionFacts.parse(text);
    // 공시 기구부품 91%는 4,162,542 / 4,767,633 = 87.3%와 불일치.
    expect(rows, hasLength(1));
    expect(rows.single.label, '전장부품');
    expect(rows.single.capacity, 4268420);
    expect(rows.single.production, 2148502);
    expect(rows.single.utilization, 50);
  });
  test('국내 천원 매입액과 명시된 외화는 분리하고 총합계를 중복하지 않는다', () {
    final table = BusinessTableInsights.parse(
      text,
      reportPeriod: '2026 반기',
    ).firstWhere((t) => t.topic == 'materialPurchase');
    final latest = table.measures.where((m) => m.period.contains('2026'));
    expect(latest.firstWhere((m) => m.label.contains('ALDC')).value, 35012481);
    expect(latest.every((m) => m.unit == '천원'), isTrue);
    expect(table.measures.any((m) => m.label.contains('총합계')), isFalse);
    expect(table.measures.any((m) => m.unit == 'USD'), isTrue);
  });
}
