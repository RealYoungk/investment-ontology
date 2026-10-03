import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/filing_series_current_eight_source.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;
import 'financial_accounts_test.dart' show fact;

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  for (final receipt in ['20220321001531', '20220321000965']) {
    final e = VerifiedAnnualSourceRegistry.find(
      receipt,
      receipt == '20220321001531' ? FsDiv.consolidated : FsDiv.separate,
    )!;
    test(
      '$receipt independent actual8 and seven bounded current equations',
      () async {
        final result = await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          e.basis,
        );
        expect(result.absence, isNull);
        final proof = jsonDecode(
          File('${e.assetDirectory}/current-cell-evidence.json')
              .readAsStringSync(),
        ) as Map;
        expect((proof['checks'] as List).length, 7);
        final expected = proof['core'] as List;
        final rows = result.numeric!.rows;
        expect(rows.length, 8);
        // Independently transcribed own-current cells, in won; no fixture-derived multiplier expectation.
        final independent = receipt == '20220321001531'
            ? [
                '8387016308',
                '16001740077',
                '-7614723769',
                '776151780',
                '-2712686801',
                '-5927862041',
                '-1846980891',
                '405214346',
              ]
            : [
                '16231577744',
                '1706431782',
                '14525145962',
                '5934446253',
                '651728876',
                '-771791959',
                '1030287321',
                '190134090',
              ];
        expect(rows.map((r) => r['thstrm_amount']), independent);
        final mapped = FinancialAccounts.pick([
          for (final row in rows)
            fact(
              row['account_nm'],
              statement: row['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : row['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.comprehensiveIncome,
            ).copyWith(amount: BigInt.parse(row['thstrm_amount'])),
        ]);
        expect(mapped.map((x) => x.key).toSet(), {
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
          'capex',
        });

        for (var i = 0; i < 8; i++) {
          expect(rows[i]['account_nm'], expected[i]['printedLabel']);
          expect(
            rows[i]['thstrm_amount'],
            ((BigInt.parse(expected[i]['amount']) *
                            BigInt.parse(proof['multiplier']))
                        .abs() *
                    (expected[i]['role'] == 'ppePurchaseSigned'
                        ? BigInt.one
                        : (BigInt.parse(expected[i]['amount']).isNegative
                              ? BigInt.from(-1)
                              : BigInt.one)))
                .toString(),
          );
          expect(rows[i]['account_id'], isNull);
          final p = rows[i]['html_provenance'] as Map;
          expect(p['source'], result.numeric!.statementSource.toString());
          expect(p['fullStatementCollected'], false);
          expect(p['notesVerified'], false);
          expect(p['detailHierarchyComplete'], false);
          expect(
            (p['filingSeriesIdentity'] as Map)['jurirContinuityVerified'],
            false,
          );
          expect(
            (p['filingSeriesIdentity']
                as Map)['operatingHistoryContinuityVerified'],
            false,
          );
          expect(
            (p['filingSeriesIdentity'] as Map)['identityScope'],
            'official-DART-filing-series-only',
          );
        }
      },
    );
    test(
      '$receipt literal CF purchase maps only in cash flow without alias changes',
      () async {
        final result = await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          e.basis,
        );
        final row = result.numeric!.rows.last;
        final cf = fact(
          row['account_nm'],
          statement: FinancialStatementKind.cashFlow,
        ).copyWith(amount: BigInt.parse(row['thstrm_amount']));
        expect(FinancialAccounts.pick([cf]).single.key, 'capex');
        expect(
          FinancialAccounts.pick([cf]).single.amount,
          BigInt.parse(receipt == '20220321001531' ? '405214346' : '190134090'),
        );
        for (final statement in FinancialStatementKind.values) {
          if (statement == FinancialStatementKind.cashFlow) continue;
          expect(
            FinancialAccounts.pick([cf.copyWith(statement: statement)]),
            isEmpty,
          );
        }
        expect(
          FinancialAccounts.pick([cf.copyWith(accountName: '사용권자산의 취득')]),
          isEmpty,
        );
        expect(
          FinancialAccounts.pick([cf.copyWith(accountName: '유형자산의 취득 참고')]),
          isEmpty,
        );
      },
    );
    test('$receipt exact source verifier rejects wrong basis', () {
      final manifest = jsonDecode(
        File('${e.assetDirectory}/manifest.json').readAsStringSync(),
      ) as Map;
      final sources = manifest['sources'] as List;
      expect(
        () => FilingSeriesCurrentEightSource.parse(
          receipt: receipt,
          corpCode: e.corpCode,
          companyName: e.companyName,
          consolidated: e.basis != FsDiv.consolidated,
          start: e.periodStart,
          end: e.periodEnd,
          raw: {
            for (final p in sources)
              p['label']: File('${e.assetDirectory}/${p['file']}')
                  .readAsStringSync(),
          },
          uris: {for (final p in sources) p['label']: Uri.parse(p['url'])},
        ),
        throwsA(isA<FormatException>()),
      );
    });
    final sourceLabels = ['shell', 'cover', e.statementLabel, 'manifest'];
    for (final label in sourceLabels) {
      test('$receipt rejects changed $label bytes before storing', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final b = File(path).readAsBytesSync();
            return path.endsWith(
                  '$label.${label == 'manifest' ? 'json' : 'html'}',
                )
                ? [...b, 32]
                : b;
          },
        );
        expect(
          () => cache.verifyRegistered(filing(e), company(e), e.basis),
          throwsA(isA<FormatException>()),
        );
      });
    }
    for (final bad in ['corp', 'year', 'receipt', 'quarter', 'sha', 'issuer']) {
      test('$receipt rejects $bad without laundering', () async {
        final f = filing(e), c = company(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = e.year - 1;
          case 'receipt':
            f.rceptNo = '20260323000000';
          case 'quarter':
            f.reportCode = FinancialReportCode.halfYear;
          case 'issuer':
            c.name = '다른 회사';
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
          () => cache.verifyRegistered(f, c, e.basis),
          throwsA(isA<FormatException>()),
        );
      });
    }
  }
}
