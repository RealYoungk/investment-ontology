import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

void main() {
  final directory = Directory('../outputs/autech-audit-2026-10-09');
  for (final file in directory.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.txt'),
  )) {
    final text = file.readAsStringSync();
    final orders = OrderFacts.parse(text);
    final tables = BusinessTableInsights.parse(text, reportPeriod: 'current');
    stdout.writeln(
      jsonEncode({
        'file': file.path,
        'orders': [
          for (final r in orders)
            {'label': r.label, 'backlog': r.backlog, 'evidence': r.evidence},
        ],
        'topics': {
          for (final topic in tables.map((t) => t.topic).toSet())
            topic: tables.where((t) => t.topic == topic).length,
        },
      }),
    );
  }
}
