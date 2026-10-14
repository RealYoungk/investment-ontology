import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

/// Offline diagnostic only. A candidate is not a verified fact or an error.
void main(List<String> args) {
  final companies = (jsonDecode(File(args[1]).readAsStringSync()) as List)
      .map((c) => c['name'] as String)
      .toSet();
  final out = <Map<String, dynamic>>[];
  for (final line in File(args[0]).readAsLinesSync()) {
    final d = jsonDecode(line) as Map<String, dynamic>;
    final text = d['text'] as String;
    final rows = <Map<String, dynamic>>[];
    void add(
      String kind,
      String label,
      double? value,
      String unit,
      String evidence,
    ) {
      if (value == null) return;
      final stored = (d['storedFacts'] as List)
          .where(
            (f) =>
                f['kind'] == kind &&
                f['sourceId'] == d['source']['id'] &&
                f['label'] == label &&
                f['unit'] == unit &&
                f['value'] == value,
          )
          .isNotEmpty;
      rows.add({
        'kind': kind,
        'label': label,
        'value': value,
        'unit': unit,
        'stored': stored,
        'evidence': evidence,
      });
    }

    for (final r in SegmentRevenue.parse(text)) {
      add('segmentRevenue', r.label, r.amount, r.unit, r.evidence);
    }
    if (d['industryCode'] != '64992') {
      for (final r in ProductionFacts.parse(
        text,
        owner: d['name'],
        otherCompanies: companies,
      )) {
        add('capacity', r.label, r.capacity, r.unit, r.evidence);
        add('production', r.label, r.production, r.unit, r.evidence);
        add('utilization', r.label, r.utilization, '%', r.evidence);
      }
    }
    for (final r in OrderFacts.parse(text)) {
      add('orderTotal', r.label, r.total, r.unit, r.evidence);
      add('orderDelivered', r.label, r.delivered, r.unit, r.evidence);
      add('orderBacklog', r.label, r.backlog, r.unit, r.evidence);
    }
    final tables = BusinessTableInsights.parse(
      text,
      reportPeriod: d['reportPeriod'],
    );
    final issues = <Map<String, dynamic>>[];
    for (final t in tables) {
      if (t.rows.any((r) => r.cells.length != t.columns.length)) {
        issues.add({
          'type': 'raggedSourceTable',
          'topic': t.topic,
          'columns': t.columns,
          'rows': t.rows
              .where((r) => r.cells.length != t.columns.length)
              .take(3)
              .map((r) => r.cells)
              .toList(),
        });
      }
      if (t.measures.any((m) => !m.value.isFinite || m.unit.isEmpty)) {
        issues.add({'type': 'invalidMeasure', 'topic': t.topic});
      }
    }
    out.add({
      'corpCode': d['corpCode'],
      'name': d['name'],
      'receipt': d['receipt'],
      'year': d['year'],
      'role': d['role'],
      'reportCode': d['reportCode'],
      'rows': rows,
      'sourceTableIssues': issues,
    });
  }
  File(args[2])
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln('Replayed ${out.length} documents without writes.');
}
