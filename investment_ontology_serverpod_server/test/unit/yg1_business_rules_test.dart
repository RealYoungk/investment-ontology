import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_product_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_source_tables.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  final text = File('test/fixtures/business_tables/yg1-2026-half.txt')
      .readAsStringSync();

  test('YG1 current names survive image-only product classification', () {
    final products = BusinessProductRules.parse(text);
    expect(
      products.map((p) => p.name),
      containsAll(['밀링 공구', '드릴링 공구', '쓰레딩 공구', '터닝공구']),
    );
    expect(products.every((p) => text.contains(p.evidence)), isTrue);
    expect(products.every((p) => p.role.isEmpty), isTrue);
    expect(
      BusinessProductRules.parse(text.replaceAll('당사 제품은', '경쟁사 제품은')),
      isEmpty,
    );
  });

  test(
    'YG1 scaled production and merged labels retain verified half-year values',
    () {
      final rows = ProductionFacts.parse(text);
      expect(rows, hasLength(2));
      expect(rows.first.label, 'Round Tool');
      expect(rows.first.capacity, 45850);
      expect(rows.first.production, 31205);
      expect(rows.first.utilization, 68.06);
      expect(rows.first.unit, '1,000pcs');
      expect(rows.last.label, 'Insert Tool');
      expect(rows.last.capacity, 18366);
      expect(rows.last.production, 6966);
      expect(rows.last.utilization, 37.93);
      expect(rows.last.unit, '1,000pcs');
      final annual = File('test/fixtures/business_tables/yg1-2021-annual.txt')
          .readAsStringSync();
      expect(ProductionFacts.parse(annual).first.label, 'Endmill');
      expect(
        ProductionFacts.parse(text.replaceAll('68.06%', '98.06%')),
        hasLength(1),
      );
    },
  );

  test(
    'revenue type subtotals reconcile without counting company totals twice',
    () {
      final rows = SegmentRevenue.parse(text);
      expect(rows.map((r) => r.label), ['상품', '제품', '용역', '기타매출']);
      expect(rows.map((r) => r.amount), [26862, 362480, 3854, 27882]);
      expect(rows.every((r) => r.unit == '백만원'), isTrue);
      final broken = text.replaceAll('26,862', '26,000');
      expect(SegmentRevenue.parse(broken).any((r) => r.label == '상품'), isFalse);
    },
  );

  test(
    'sales channel shares and closing facility values retain source scopes',
    () {
      final tables = BusinessSourceTables.parse(text, reportPeriod: '2026 반기');
      final channels = tables.singleWhere(
        (t) => t.topic == 'salesChannelShareSource',
      );
      expect(channels.measures.map((m) => m.value), [14, 86]);
      final machines = tables.singleWhere(
        (t) => t.topic == 'facilitiesBookValueSource',
      );
      expect(
        machines.measures.singleWhere((m) => m.label == '기계장치').value,
        111979,
      );
      expect(
        machines.measures.singleWhere((m) => m.label == '기계장치').unit,
        '백만원',
      );
      expect(machines.validation, contains('현금 설비투자액과 구분'));
      expect(tables.every((t) => text.contains(t.evidence)), isTrue);
      final broken = BusinessSourceTables.parse(
        text.replaceAll('111,979', '111,000'),
      );
      expect(
        broken.expand((t) => t.measures).any((m) => m.label == '기계장치'),
        isFalse,
      );
    },
  );

  test('research projects keep merged-year continuation rows without inventing effects', () {
    final table = BusinessTableInsights.parse(
      text,
      reportPeriod: '2026 반기',
    ).singleWhere((t) => t.topic == 'researchProjects');
    expect(table.rows, hasLength(25));
    expect(table.rows.where((r) => r.cells.first == '2024년'), hasLength(15));
    expect(table.rows.where((r) => r.cells.first == '2025년'), hasLength(8));
    expect(table.rows.where((r) => r.cells.first == '2026년'), hasLength(2));
    expect(table.rows[1].cells.last, '-');
    expect(text.contains(table.evidence), isTrue);
  });

  test('derivative principal and fair value retain distinct currencies', () {
    final tables = BusinessTableInsights.parse(
      text,
      reportPeriod: '2026 반기',
    ).where((t) => t.topic == 'derivatives').toList();
    expect(tables, hasLength(2));
    final currency = tables.first.measures;
    expect(currency.first.value, 4000);
    expect(currency.first.unit, '천EUR');
    expect(currency.singleWhere((m) => m.metric == '공정가치 · 자산').value, 62485);
    expect(currency.singleWhere((m) => m.metric == '공정가치 · 자산').unit, '천원');
    expect(tables.last.measures.first.value, 30000000);
    expect(tables.last.measures.first.unit, '천원');
  });

  test(
    'single division revenue uses consolidated total after eliminations',
    () {
      final divisionText = text.split('## 4.')[0];
      final rows = SegmentRevenue.parse(divisionText);
      expect(rows, hasLength(1));
      expect(rows.single.label, '절삭공구');
      expect(rows.single.amount, 421078);
      expect(rows.single.unit, '백만원');
      expect(rows.single.evidence, contains('연결'));
      expect(rows.single.evidence, contains('(237,933)'));
      expect(text.contains(rows.single.evidence), isTrue);
      expect(
        SegmentRevenue.parse(divisionText.replaceAll('단일 사업부문', '여러 사업부문')),
        isEmpty,
      );
      expect(
        SegmentRevenue.parse(divisionText.replaceAll('421,078', '421,000')),
        isEmpty,
      );
      expect(
        SegmentRevenue.parse(divisionText.replaceAll('내부거래 제거', '고객사 매출')),
        isEmpty,
      );
    },
  );
}
