import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/infrastructure_fund_financials.dart';

void main() {
  final rows = InfrastructureFundProfiles.rows
      .map(
        (p) => InfrastructureFundFinancials.parseRaw(
          p['metadata'],
          File(
            'test/fixtures/issuer_documents/infrastructure_fund/${p['metadata']['corpCode']}-${p['metadata']['periodEnd']}.raw.txt',
          ).readAsBytesSync(),
        ),
      )
      .toList();
  File(
    '../investment_ontology_serverpod_flutter/test/fixtures/infrastructure-fund-current-categories.json',
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
