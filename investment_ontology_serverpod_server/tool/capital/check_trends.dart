import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/bond_trends.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';

/// Rebuild a UI specimen from recorded official-source fixtures, without a DB.
Future<void> main(List<String> args) async {
  final manifest = File(args[0]);
  final entries = (jsonDecode(await manifest.readAsString()) as List)
      .cast<Map<String, dynamic>>();
  final periods = <Map<String, dynamic>>[];
  for (final entry in entries) {
    final parsed = CapitalStructureParser.parse(
      await File('${manifest.parent.path}/${entry['file']}').readAsString(),
      receipt: entry['receipt'],
      periodEnd: entry['periodEnd'],
      companyName: entry['companyName'],
    );
    periods.add({
      ...parsed,
      'state': 'ready',
      'reportName': '사업보고서 (${entry['periodEnd'].substring(0, 4)}.12)',
      'sourceUrls': entry['sourceUrls'],
    });
  }
  final data = BondTrends.build(periods);
  final target = File(args[1]);
  await target.parent.create(recursive: true);
  await target.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
  stdout.writeln(
    'Source-bound specimen saved: ${data['points'].last['netDecreaseWon']} won net decrease; causes remain unconfirmed.',
  );
}
