import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_product_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  const investments = [376, 530, 570, 422, 574, 278];
  for (var year = 2021; year <= 2026; year++) {
    final suffix = year == 2026 ? 'half' : 'annual';
    final text = File('test/fixtures/business_tables/yg1-$year-$suffix.txt')
        .readAsStringSync();
    final period = '$year ${year == 2026 ? '반기' : '연간'}';
    test(
      '$year explicit products and correctly scoped investment are covered',
      () {
        final products = BusinessProductRules.parse(text);
        expect(products, hasLength(year <= 2022 ? 6 : 4));
        expect(products.every((p) => text.contains(p.evidence)), isTrue);
        final tables = BusinessTableInsights.parse(text, reportPeriod: period);
        final materials = tables.singleWhere(
          (t) => t.topic == 'materialContext',
        );
        expect(materials.rows.map((r) => r.cells.first), ['CARBIDE', 'HSS']);
        expect(materials.measures, isEmpty);
        final projectRows = tables
            .singleWhere((t) => t.topic == 'researchProjects')
            .rows;
        expect(projectRows, hasLength([44, 37, 35, 35, 29, 25][year - 2021]));
        expect(
          tables.singleWhere((t) => t.topic == 'intellectualProperty').rows,
          isNotEmpty,
        );
        if (year >= 2023) {
          expect(
            tables
                .singleWhere((t) => t.topic == 'customerShareTotal')
                .measures
                .single
                .value,
            [12.4, 11.7, 11.88, 11.35][year - 2023],
          );
        }
        if (year >= 2025) {
          final customers = tables.singleWhere(
            (t) => t.topic == 'customerConcentration',
          );
          expect(customers.measures, hasLength(5));
          expect(
            customers.measures.every(
              (m) => m.unit == '%' && m.period == period,
            ),
            isTrue,
          );
        }
        final rows = BusinessTableInsights.parse(
          text,
          reportPeriod: period,
        ).where((t) => t.topic == 'investmentExecution').toList();
        expect(rows, hasLength(1));
        expect(rows.single.measures.single.value, investments[year - 2021]);
        expect(rows.single.measures.single.period, period);
        expect(rows.single.measures.single.unit, '억원');
        expect(text.contains(rows.single.evidence), isTrue);
        expect(
          BusinessTableInsights.parse(
            text.replaceAll('당사의', '경쟁사의'),
            reportPeriod: period,
          ).any((t) => t.topic == 'investmentExecution'),
          isFalse,
        );
        expect(
          BusinessTableInsights.parse(
            text,
            reportPeriod: '${year + 1} 연간',
          ).any((t) => t.topic == 'investmentExecution'),
          isFalse,
        );
      },
    );
  }
}
