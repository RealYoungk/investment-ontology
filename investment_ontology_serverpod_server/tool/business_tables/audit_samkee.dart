import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';

/// Offline replay of the reviewed stored source corpus; no DB/network writes.
void main(List<String> args) {
  final results = <Map<String, dynamic>>[];
  for (final period in ['2022', '2023', '2024', '2025', '2026-half']) {
    final text = File('test/fixtures/business_tables/samkee-$period.txt')
        .readAsStringSync();
    final year = int.parse(period.substring(0, 4));
    final tables = BusinessTableInsights.parse(text, reportPeriod: period);
    final rnd = RndFacts.parse(text, bsnsYear: year);
    results.add({
      'period': period,
      'sourceChars': text.length,
      'tables': tables.map((t) => t.toJson()).toList(),
      'segmentRevenue': [
        for (final r in SegmentRevenue.parse(text))
          {
            'label': r.label,
            'value': r.amount,
            'unit': r.unit,
            'evidence': r.evidence,
          },
      ],
      'production': [
        for (final r in ProductionFacts.parse(text))
          {
            'label': r.label,
            'capacity': r.capacity,
            'production': r.production,
            'utilization': r.utilization,
            'unit': r.unit,
          },
      ],
      'validatedOrders': [
        for (final r in OrderFacts.parse(text))
          {
            'label': r.label,
            'total': r.total,
            'delivered': r.delivered,
            'backlog': r.backlog,
            'unit': r.unit,
          },
      ],
      'research': rnd == null
          ? null
          : {
              'years': rnd.years,
              'unit': rnd.unit,
              'totals': rnd.totals.map((r) => r.values).toList(),
              'ratio': rnd.ratio?.values,
            },
    });
    stdout.writeln(
      '$period: ${tables.length} readable tables, ${SegmentRevenue.parse(text).length} revenue rows, ${ProductionFacts.parse(text).length} validated production rows, R&D ${rnd == null ? "missing" : "parsed"}',
    );
  }
  File(args.single)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
}
