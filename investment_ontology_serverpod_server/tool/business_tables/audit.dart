import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

// Replay public stored-source snapshots without network or database writes.
void main(List<String> args) {
  final directory = Directory(args.single);
  for (final file in directory.listSync().whereType<File>().where(
    (f) => RegExp(r'^\d{8}(?:-2025)?\.json$').hasMatch(f.uri.pathSegments.last),
  )) {
    final source = jsonDecode(file.readAsStringSync());
    if (source is! Map || source['sections'] == null) continue;
    final text = (source['sections'] as List)
        .map((s) => '## ${s['title']}\n${s['text']}')
        .join('\n');
    final period = source['_audit']['reportPeriod'] as String;
    final tables = BusinessTableInsights.parse(text, reportPeriod: period);
    File(file.path.replaceFirst('.json', '.parsed.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ')
          .convert(tables.map((t) => t.toJson()).toList()),
    );
    stdout.writeln(
      '${file.uri.pathSegments.last}: ${tables.map((t) => '${t.topic}:${t.rows.length}/${t.measures.length}').join(', ')}',
    );
  }
}
