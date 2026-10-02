import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';

Future<void> main(List<String> args) async {
  final data = CapitalStructureParser.parse(
    await File(args[0]).readAsString(),
    receipt: args[1],
    periodEnd: args[2],
    companyName: args[3],
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(data));
}
