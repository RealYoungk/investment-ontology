import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_cover_executive_role.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  const expected = {
    '20220317001218': [
      '11292422797',
      '5413060663',
      '5879362134',
      '21922928386',
      '458780662',
      '477567597',
      '540702788',
    ],
    '20220816000416': [
      '299608513355',
      '48050513135',
      '251558000220',
      '79969402198',
      '2355793584',
      '-268705545',
      '17375200309',
    ],
  };
  const keys = [
    'assets',
    'liabilities',
    'equity',
    'revenue',
    'operatingIncome',
    'netIncome',
    'operatingCashFlow',
  ];
  for (final e in expected.entries) {
    test(
      '${e.key} own historical legal issuer and direct whole7 amounts',
      () async {
        final entry = VerifiedAnnualSourceRegistry.find(e.key, FsDiv.separate)!;
        final result = await VerifiedAnnualSourceCache(
          readAsset: (p) => File(p).readAsBytes(),
        ).verifyRegistered(filing(entry), company(entry), FsDiv.separate);
        final rows = result.numeric!.rows;
        expect(rows.every((r) => r['account_id'] == null), true);
        final converted = FinancialRows.toFacts(
          rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2021,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: 1,
        );
        for (var i = 0; i < converted.facts.length; i++) {
          converted.facts[i].id = i + 1;
        }
        final lines = FinancialAccounts.pick(converted.facts);
        for (var i = 0; i < keys.length; i++) {
          expect(
            lines.singleWhere((l) => l.key == keys[i]).amount,
            BigInt.parse(e.value[i]),
          );
        }
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['periodStart'], '2021-01-01');
          expect(p['periodEnd'], '2021-12-31');
          final ce = p['supportingPeriodEvidence'];
          if (ce is Map) {
            expect(ce['periodStart'], '2021-01-01');
            expect(ce['periodEnd'], '2021-12-31');
          }
        }
      },
    );
  }
  test('representative executive role never accepted on an unpinned cover', () {
    final raw = File(
      'assets/financial_source_cache/20220816000416-ofs/cover.html',
    ).readAsStringSync();
    expect(
      ExactCoverExecutiveRole.names(raw).hasMatch('회사명:(주)시그넷이브이대표집행임원:'),
      true,
    );
    expect(
      ExactCoverExecutiveRole.names('$raw ').hasMatch('회사명:(주)시그넷이브이대표집행임원:'),
      false,
    );
    expect(
      ExactCoverExecutiveRole.names(raw.replaceAll('시그넷이브이', '다른회사'))
          .hasMatch('회사명:다른회사대표집행임원:'),
      false,
    );
  });
}
