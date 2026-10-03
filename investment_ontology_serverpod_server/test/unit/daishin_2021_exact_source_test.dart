import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/daishin_2021_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final p in Daishin2021ExactSource.profiles) {
    final cfs = p['basis'] == 'cfs';
    final basis = cfs ? FsDiv.consolidated : FsDiv.separate;
    final e = VerifiedAnnualSourceRegistry.find('20220516001812', basis)!;
    final manifest = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    ) as Map;
    final raw = <String, String>{
      for (final s in manifest['sources'] as List)
        s['label'] as String: File('${e.assetDirectory}/${s['file']}')
            .readAsStringSync(),
    };
    final urls = <String, Uri>{
      for (final s in manifest['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? body,
      Map<String, Uri>? uris,
      String corp = '00110893',
      String receipt = '20220516001812',
      int year = 2021,
      bool? consolidated,
    }) => Daishin2021ExactSource.parse(
      raw: body ?? raw,
      uris: uris ?? urls,
      receipt: receipt,
      corp: corp,
      start: DateTime.utc(year),
      end: DateTime.utc(year, 12, 31),
      consolidated: consolidated ?? cfs,
    );
    test(
      '${p['basis']} direct core8 verifies own notes; no prior facts or full notes claim',
      () async {
        final result = await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          basis,
        );
        expect(result.absence, isNull);
        final rows = result.numeric!.rows;
        expect(rows, hasLength(8));
        expect(
          rows.map((r) => r['thstrm_amount']),
          cfs
              ? [
                  '22763241909000',
                  '20110035373000',
                  '2653206536000',
                  '3635331998000',
                  '885548890000',
                  '615822762000',
                  '-1402568980000',
                  '22046693000',
                ]
              : [
                  '15138810188000',
                  '13112533710000',
                  '2026276478000',
                  '2432183746000',
                  '281812111000',
                  '178657494000',
                  '143066240000',
                  '20151542000',
                ],
        );
        final facts = [
          for (final r in rows)
            FinancialFact(
              id: rows.indexOf(r) + 1,
              reportId: 1,
              companyId: 1,
              bsnsYear: 2021,
              reportCode: FinancialReportCode.annual,
              fsDiv: basis,
              statement: r['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : r['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.incomeStatement,
              accountName: r['account_nm'] as String,
              amount: BigInt.parse(r['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        expect(
          FinancialAccounts.pick(facts).map((r) => r.key).toSet(),
          containsAll([
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
            'capex',
          ]),
        );
        for (final r in rows) {
          final pr = r['html_provenance'] as Map;
          expect(pr['fullNotesVerified'], false);
          expect(pr['fullStatementCollected'], false);
          expect(pr['priorFactsExtracted'], 0);
          expect(pr['unit'], '천원');
          expect(r.containsKey('frmtrm_amount'), false);
          if (!cfs) {
            expect(pr['preservedClassificationDifferences'], isNotEmpty);
          }
        }
      },
    );
    test(
      '${p['basis']} rejects wrong issuer period receipt basis URI and changed original bytes',
      () {
        expect(() => parse(corp: '00414540'), throwsFormatException);
        expect(() => parse(year: 2022), throwsFormatException);
        expect(() => parse(receipt: '20230316001545'), throwsFormatException);
        expect(() => parse(consolidated: !cfs), throwsFormatException);
        expect(
          () => parse(
            uris: {
              ...urls,
              'notes': Uri.parse(
                'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001545',
              ),
            },
          ),
          throwsFormatException,
        );
        for (final label in raw.keys) {
          expect(
            () => parse(body: {...raw, label: '${raw[label]} '}),
            throwsFormatException,
          );
        }
      },
    );
  }
  test('audit getters cannot mutate compiled source guards', () {
    final p = Daishin2021ExactSource.profiles;
    p[0]['rows'][0]['printed'] = '0';
    expect(
      Daishin2021ExactSource.profiles[0]['rows'][0]['printed'],
      isNot('0'),
    );
  });
}
