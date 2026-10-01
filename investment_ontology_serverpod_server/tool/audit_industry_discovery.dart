import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/semiconductor_activity_rules.dart';

/// Reads an exported [{name,corpCode,text}] array; writes no database data.
void main(List<String> args) {
  final rows = jsonDecode(File(args.single).readAsStringSync()) as List;
  final activities = <Map<String, Object>>[];
  for (final row in rows) {
    for (final a in SemiconductorActivityRules.parse(
      row['text'] as String,
      companyName: row['name'] as String,
    )) {
      if (!(row['text'] as String).contains(a.evidence)) {
        throw StateError('Non-verbatim evidence');
      }
      activities.add({
        'company': row['name'],
        'code': row['corpCode'],
        'product': a.product.id,
        'evidence': a.evidence,
      });
    }
  }
  stdout.write(const JsonEncoder.withIndent('  ').convert(activities));
}
