import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/research/fund_financial_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/fund_financials_text.dart';

void main() {
  final rows = FundFinancialProfiles.rows
      .map(
        (p) => FundFinancialsText.parseText(
          p['metadata'],
          File(
            'test/fixtures/issuer_documents/fund_text/${p['metadata']['periodEnd']}.txt',
          ).readAsBytesSync(),
        ),
      )
      .toList();
  File(
    '../investment_ontology_serverpod_flutter/test/fixtures/fund-current-categories.json',
  ).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'state': 'ready',
      'provider': 'verified-primary-pdf-text-rule',
      'source': {
        'kind': 'officialFile',
        'url': 'https://re1.miraeasset.com',
        'reference': 'source-bound-partial-printed-fund;cash-quarantine;no-regular-api-or-xbrl',
      },
      'rows': rows,
    }),
  );
}
