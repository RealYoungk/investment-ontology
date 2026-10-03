import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/db_yuanta_own_eight_source.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;
import 'financial_accounts_test.dart' show fact;

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  for (final receipt in ['20220316001241', '20230314000094']) {
    final e = VerifiedAnnualSourceRegistry.find(
      receipt,
      FsDiv.consolidated,
    )!;
    test(
      '$receipt independent actual8 and eight bounded current equations',
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
        expect((proof['checks'] as List).length, 8);
        final expected = proof['core'] as List;
        final rows = result.numeric!.rows;
        expect(rows.length, 8);
        // Independently transcribed own-current cells, in won; no fixture-derived multiplier expectation.
        final independent = receipt == '20220316001241'
            ? [
                '9583673039437',
                '8535236408583',
                '1048436630854',
                '1410732861048',
                '169597211231',
                '126818163372',
                '-197242734468',
                '6841895429',
              ]
            : [
                '13419879837000',
                '11862753297000',
                '1557126540000',
                '2479008315000',
                '43311171000',
                '45073044000',
                '517965843000',
                '7626293000',
              ];
        expect(rows.map((r) => r['thstrm_amount']), independent);

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
          receipt == '20220316001241'
              ? BigInt.parse('6841895429')
              : BigInt.parse('7626293000'),
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
        () => DbYuantaOwnEightSource.parse(
          receipt: receipt,
          corpCode: e.corpCode,
          companyName: e.companyName,
          consolidated: false,
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
    final sourceLabels = receipt == '20220316001241'
        ? ['shell', 'cover', 'overview', 'cfs', 'manifest']
        : ['shell', 'cover', 'cfs', 'manifest'];
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
