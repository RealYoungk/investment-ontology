import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

/// Offline source replay. No network or database mutations.
void main(List<String> args) {
  final output = Directory(args[1])..createSync(recursive: true);
  final ledger = <Map<String, dynamic>>[];
  for (final line in File(args[0]).readAsLinesSync()) {
    final source = jsonDecode(line) as Map<String, dynamic>;
    final company = source['company'] as Map<String, dynamic>;
    final document = source['latestBusiness'] as Map<String, dynamic>?;
    final code = company['corpCode'] as String;
    if (document == null || document['text'] == null) {
      ledger.add({...company, 'status': 'missingStoredSource'});
      continue;
    }
    final text = document['text'] as String;
    try {
      final tables = BusinessTableInsights.parse(
        text,
        reportPeriod: '${document['bsnsYear']} ${document['reportCode']}',
      );
      File(
        '${output.path}/$code.parsed.json',
      ).writeAsStringSync(jsonEncode(tables.map((t) => t.toJson()).toList()));
      ledger.add({
        ...company,
        'status': 'parsed',
        'receipt': document['rceptNo'],
        'reportCode': document['reportCode'],
        'year': document['bsnsYear'],
        'sourceChars': text.length,
        'tables': tables.length,
        'rows': tables.fold<int>(0, (n, t) => n + t.rows.length),
        'measures': tables.fold<int>(0, (n, t) => n + t.measures.length),
        'topics': tables.map((t) => t.topic).toSet().toList(),
        'latestReceiptMatches':
            document['rceptNo'] == source['latestFiling']?['rceptNo'],
      });
    } catch (error) {
      ledger.add({...company, 'status': 'failed', 'error': error.toString()});
    }
  }
  File('${output.path}/ledger.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(ledger));
  stdout.writeln('Audited ${ledger.length} issuer snapshots.');
}
