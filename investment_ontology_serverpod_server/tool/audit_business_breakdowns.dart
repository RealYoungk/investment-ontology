import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_breakdown_facts.dart';

/// Offline, read-only replay of a saved businessContent text. Never writes DB.
/// dart run tool/audit_business_breakdowns.dart filing.txt 2025
void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError('Expected a UTF-8 filing text path and fiscal year');
  }
  final text = File(args[0]).readAsStringSync();
  final rows = BusinessBreakdownFacts.parse(text, year: int.parse(args[1]));
  if (rows.any((r) => !text.contains(r.evidence))) {
    throw StateError('Evidence is not a verbatim substring');
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert([
      for (final r in rows)
        {
          'kind': r.kind.name,
          'label': r.label,
          'value': r.value,
          'unit': r.unit,
          'note': r.note,
        },
    ]),
  );
}
