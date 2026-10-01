import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/kind_product_catalog.dart';

void main(List<String> args) {
  final companies = jsonDecode(File(args.first).readAsStringSync()) as List;
  final result = <Map<String, dynamic>>[];
  for (final c in companies) {
    final issuer = Company(
      corpCode: c['corpCode'],
      name: c['name'],
      stockCode: c['stockCode'],
      industryCode: c['industryCode'],
      market: Market.values.byName(c['market']),
    );
    for (final a in KindProductCatalog.forCompany(issuer)) {
      result.add(a.toJson());
    }
  }
  stdout.write(jsonEncode(result));
}
