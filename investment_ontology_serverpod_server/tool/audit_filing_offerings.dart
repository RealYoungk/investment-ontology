import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/filing_offering_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_taxonomy.dart';

void main(List<String> args) {
  final corpus = jsonDecode(File(args.first).readAsStringSync()) as List;
  final rows = <Map<String, dynamic>>[];
  for (final c in corpus) {
    if (c['year'] == null || c['year'] < DateTime.now().year - 2) continue;
    for (final (r, e) in FilingOfferingRules.parse(
      c['text'] ?? '',
      sector: DiscoveryTaxonomy.category(c['industryCode']).$1,
      companyName: c['name'],
      year: c['year'],
    )) {
      rows.add({
        'corpCode': c['corpCode'],
        'name': c['name'],
        'industry': r.$1,
        'group': r.$2,
        'key': r.$3,
        'evidence': e,
        'receipt': c['receipt'],
        'year': c['year'],
      });
    }
  }
  stdout.write(jsonEncode(rows));
}
