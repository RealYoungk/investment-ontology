import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/charter_comparison_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';

void main(List<String> args) {
  for (final f in Directory(
    args.first,
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.xml.gz'))) {
    final xml = utf8.decode(gzip.decode(f.readAsBytesSync()));
    try {
      final parsed = CharterComparisonRules.parse(xml);
      stdout.writeln(
        '${f.path}: ${(parsed['changes'] as List).length} changes',
      );
    } catch (e) {
      stdout.writeln('${f.path}: $e');
    }
    for (final m in RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xml)) {
      final cells =
          RegExp(
                r'<(TD|TH|TE|TU)\b[^>]*>(.*?)</\1>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(m[0]!)
              .map(
                (c) => CharterComparisonRules.compact(
                  CapitalStructureParser.plain(c[2]!),
                ),
              )
              .toList();
      if (!(cells.any(CharterComparisonRules.beforeNames.contains) &&
          cells.any(CharterComparisonRules.afterNames.contains))) {
        continue;
      }
      try {
        CapitalStructureParser.grid(m[0]!);
      } catch (e) {
        stdout.writeln('GRID: $e; cells=${cells.take(8).toList()}');
        File('${f.path}.table.xml').writeAsStringSync(m[0]!);
      }
    }
  }
}
