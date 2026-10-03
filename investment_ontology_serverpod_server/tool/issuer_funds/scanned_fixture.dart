import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/research/scanned_fund_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/scanned_fund_financials.dart';

void main() {
  final rows = ScannedFundProfiles.rows
      .map(
        (p) => ScannedFundFinancials.parse(
          p['metadata'],
          File(
            'test/fixtures/issuer_documents/scanned_fund/${p['metadata']['periodEnd'].substring(0, 4)}.scanned-ocr.json',
          ).readAsBytesSync(),
        ),
      )
      .toList();
  File(
    '../investment_ontology_serverpod_flutter/test/fixtures/scanned-fund-current-categories.json',
  ).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'state': 'ready',
      'provider': 'verified-primary-pdf-text-rule',
      'source': {
        'kind': 'officialFile',
        'url': 'https://www.mkif.com',
        'reference': 'source-bound-partial-printed-infrastructure-fund;no-regular-api-or-xbrl',
      },
      'rows': rows,
    }),
  );
}
