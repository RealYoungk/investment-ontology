import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/business_activity_rules.dart';

void main(List<String> args) {
  final rows = jsonDecode(File(args.first).readAsStringSync()) as List;
  final results = <Map<String, dynamic>>[];
  for (final row in rows) {
    for (final a in BusinessActivityRules.parse(
      row['text'],
      companyName: row['name'],
    )) {
      if (!(row['text'] as String).contains(a.$2)) {
        throw StateError('Non-verbatim');
      }
      results.add({
        'company': row['name'],
        'corpCode': row['corpCode'],
        'industry': a.$1.industry,
        'key': a.$1.key,
        'group': a.$1.group,
        'evidence': a.$2,
      });
    }
  }
  stdout.writeln(jsonEncode(results));
}
