import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;
import 'financial_accounts_test.dart' show fact;

void main() {
  final entries = VerifiedAnnualSourceRegistry.entries.where(
    (e) => e.ruleVersion == 'dated-current-column-whole-equity-v1',
  );
  for (final e in entries) {
    test(
      '${e.receipt}:${e.basis.name} immutable whole7 same-basis source',
      () async {
        final r = (await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          e.basis,
        ));
        expect(r.absence, isNull);
        final rows = r.numeric!.rows;
        expect(rows.length, greaterThanOrEqualTo(7));
        final proof =
            (rows.first['html_provenance']
                    as Map)['supportingWholeCurrentEvidence']
                as Map;
        expect(proof['basis'], e.basis == FsDiv.consolidated ? 'CFS' : 'OFS');
        expect(
          rows.take(7).map((r) => r['thstrm_amount']).toList(),
          (proof['core'] as Map).values.toList(),
        );
        expect(
          rows.every(
            (row) =>
                row['account_id'] == null &&
                (row['html_provenance'] as Map)['source'] ==
                    r.numeric!.statementSource.toString(),
          ),
          true,
        );
        if (e.receipt == '20260323000759') {
          expect(rows.first['account_nm'], '[자산총계]');
          expect(rows[1]['account_nm'], '[부채총계]');
        }
      },
    );
    for (final bad in ['corp', 'year', 'quarter', 'receipt', 'sha']) {
      test('${e.receipt}:${e.basis.name} rejects $bad', () async {
        final f = filing(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = 2024;
          case 'quarter':
            f.reportCode = FinancialReportCode.halfYear;
          case 'receipt':
            f.rceptNo = '20260323000000';
        }
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = File(p).readAsBytesSync();
            return bad == 'sha' && p.endsWith('${e.statementLabel}.html')
                ? [...b, 32]
                : b;
          },
        );
        expect(
          () => cache.verifyRegistered(f, company(e), e.basis),
          throwsA(isA<FormatException>()),
        );
      });
    }
    test(
      '${e.receipt}:${e.basis.name} finite priority cap3/stored rejection',
      () {
        final f = filing(e)
          ..lastError = 'api-noData-annual-public:attempt=2; previous failure';
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
          true,
        );
        for (final bad in ['corp', 'year', 'quarter', 'exhausted', 'stored']) {
          final x = filing(
            e,
          )..lastError = 'api-noData-annual-public:attempt=2; previous failure';
          switch (bad) {
            case 'corp':
              x.corpCode = '00000000';
            case 'year':
              x.bsnsYear = 2024;
            case 'quarter':
              x.reportCode = FinancialReportCode.halfYear;
            case 'exhausted':
              x.lastError =
                  'api-noData-annual-public:attempt=3; previous failure';
            case 'stored':
              x.consolidatedStatus = FilingFetchStatus.stored;
              x.separateStatus = FilingFetchStatus.stored;
          }
          expect(
            FinancialFactsSync.verifiedDurationSourceRecoveryPriority(x),
            false,
            reason: bad,
          );
        }
      },
    );
  }
  test('finite bracket BS names Dart/SQL mirror rejects detail/nonBS', () {
    for (final e in {'[자산총계]': 'assets', '[부채총계]': 'liabilities'}.entries) {
      expect(
        FinancialAccounts.pick([
          fact(e.key, statement: FinancialStatementKind.balanceSheet),
        ]).single.key,
        e.value,
      );
      expect(FinancialAccounts.resolvedIdSql('f'), contains("'${e.key}'"));
      for (final name in ['부문${e.key}', '${e.key}주석', '[${e.key}]']) {
        expect(
          FinancialAccounts.pick([
            fact(name, statement: FinancialStatementKind.balanceSheet),
          ]),
          isEmpty,
        );
      }
      expect(FinancialAccounts.pick([fact(e.key)]), isEmpty);
      expect(
        FinancialAccounts.pick([
          fact(
            e.key,
            statement: FinancialStatementKind.balanceSheet,
            detail: 'segment',
          ),
        ]),
        isEmpty,
      );
    }
  });
}
