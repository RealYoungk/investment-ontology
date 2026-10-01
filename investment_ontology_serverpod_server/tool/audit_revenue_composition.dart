import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';

// Read-only replay of stored filing text. Input: one JSON document per line.
void main(List<String> args) {
  final results = <Map<String, Object?>>[];
  for (final line in File(args.single).readAsLinesSync()) {
    final d = jsonDecode(line) as Map<String, dynamic>;
    final rows = SegmentRevenue.parse(d['text'] as String);
    results.add({
      'documentId': d['id'],
      'corpCode': d['corpCode'],
      'company': d['name'],
      'year': d['bsnsYear'],
      'receipt': d['rceptNo'],
      'rows': rows.length,
      'labels': rows.map((r) => r.label).toList(),
      'singleSegment': rows.length == 1,
      'duplicateLabels': rows.map((r) => r.label).toSet().length != rows.length,
    });
  }
  stdout.write(const JsonEncoder.withIndent('  ').convert(results));
}
