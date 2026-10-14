import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/financial_business_source_tables.dart';

/// Explicit offline audit. Streams JSONL so the corpus is not loaded into RAM.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/business_tables/audit_financial_sources.dart CORPUS.jsonl',
    );
    exitCode = 64;
    return;
  }
  var docs = 0, supported = 0, tables = 0, measures = 0, failures = 0;
  await for (final line in File(
    args.single,
  ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final d = jsonDecode(line) as Map<String, dynamic>;
    docs++;
    final text = d['text'] as String;
    final parsed = FinancialBusinessSourceTables.parse(
      text,
      d['reportPeriod']?.toString() ?? d['year'].toString(),
      industryCode: d['industryCode']?.toString(),
    );
    if (parsed.isNotEmpty) supported++;
    tables += parsed.length;
    for (final t in parsed) {
      final valid =
          text.contains(t.evidence) &&
          t.rows.every((r) => r.cells.length == t.columns.length) &&
          t.measures.every(
            (m) =>
                m.value.isFinite &&
                m.metric.isNotEmpty &&
                m.period.isNotEmpty &&
                ['원', '천원', '백만원', '억원', '%'].contains(m.unit),
          );
      measures += t.measures.length;
      if (!valid) {
        failures++;
        stderr.writeln('FAIL ${d['documentId']} ${d['name']} ${t.title}');
      }
      if (!RegExp(r'^6[456]').hasMatch(d['industryCode']?.toString() ?? '')) {
        failures++;
        stderr.writeln('NONFINANCE ${d['documentId']} ${d['name']}');
      }
    }
  }
  stdout.writeln(
    'REPLAY docs=$docs supported=$supported tables=$tables measures=$measures failures=$failures',
  );
  if (failures > 0) exitCode = 1;
}
