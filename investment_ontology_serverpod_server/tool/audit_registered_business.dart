import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_taxonomy.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/registered_business_evidence.dart';

void main(List<String> args) {
  final rows = jsonDecode(File(args.first).readAsStringSync()) as List;
  final result = <Map<String, dynamic>>[];
  for (final r in rows) {
    if (r['industryCode'] == null || r['industryCode'] == '64992') continue;
    final evidence = RegisteredBusinessEvidence.find(
      r['text'],
      industry: DiscoveryTaxonomy.category(r['industryCode']).$1,
      code: r['industryCode'],
      companyName: r['name'],
    );
    if (evidence != null) {
      if (!(r['text'] as String).contains(evidence)) {
        throw StateError('non-verbatim');
      }
      result.add({
        'corpCode': r['corpCode'],
        'name': r['name'],
        'industry': r['industry'],
        'code': r['industryCode'],
        'evidence': evidence,
      });
    }
  }
  stdout.writeln(jsonEncode(result));
}
