import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/research/own_annual_financials_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/reviewed_dart_issuer_sources.dart';

void main() {
  final rows = <Map<String, dynamic>>[];
  for (final d in ReviewedDartIssuerSources.documents.where(
    OwnAnnualFinancialsHtml.supports,
  )) {
    final receipt = d['metadata']['providerReceipt'];
    rows.addAll(
      OwnAnnualFinancialsHtml.parse(
        document: d,
        shellBytes: File(
          'test/fixtures/issuer_documents/dart/$receipt-own-shell.html',
        ).readAsBytesSync(),
        statementBytes: File(
          'test/fixtures/issuer_documents/dart/$receipt-own-statement.html',
        ).readAsBytesSync(),
      ),
    );
  }
  File(
    '../investment_ontology_serverpod_flutter/test/fixtures/own-annual-current-core.json',
  ).writeAsStringSync(jsonEncode(rows));
}
