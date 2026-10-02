import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_capital_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';

Future<void> main(List<String> args) async {
  final reader = PublicCapitalDocument();
  try {
    final body = await reader.fetch(args[0], args[1]);
    await File(args[4]).writeAsString(body.document);
    final parsed = CapitalStructureParser.parse(
      body.document,
      receipt: args[0],
      periodEnd: args[2],
      companyName: args[3],
    );
    await File('${args[4]}.json').writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({...parsed, 'sourceUrls': body.urls}),
    );
    stdout.writeln(
      '${parsed['states']} · ${(parsed['entries'] as List).length} rows · ${(parsed['stocks'] as List).length} share classes',
    );
  } finally {
    reader.close();
  }
}
