import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/research/retrospective_fund_financials.dart';

void main() {
  const base = 'test/fixtures/issuer_documents/kbif_retrospective';
  RetrospectiveFundFinancials.verifyPdf(
    File('$base/corrected-20241115.pdf').readAsBytesSync(),
  );
  final rows = RetrospectiveFundFinancials.parse(
    File('$base/corrected-20241115.txt').readAsBytesSync(),
  );
  File(
    '../investment_ontology_serverpod_flutter/test/fixtures/retrospective-fund-categories.json',
  ).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'corpCode': '01880801',
      'state': 'ready',
      'provider': 'verified-primary-pdf-text-rule',
      'sourceRef': 'source-bound-partial-printed-infrastructure-fund;no-regular-api-or-xbrl',
      'rows': rows,
      'source': {'kind': 'officialFile', 'url': 'https://kbif.co.kr'},
    }),
  );
}
