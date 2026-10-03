import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/cns_micro_current_seven_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final e in VerifiedAnnualSourceRegistry.entries.where(
    (e) => CnsMicroCurrentSevenSource.supports(e.ruleVersion),
  )) {
    final manifest = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    ) as Map;
    final raw = <String, String>{
      for (final s in manifest['sources'] as List)
        s['label'] as String: File('${e.assetDirectory}/${s['file']}')
            .readAsStringSync(),
    };
    final uris = <String, Uri>{
      for (final s in manifest['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? body,
      Map<String, Uri>? urls,
      String? corp,
      String? receipt,
      int? year,
      bool cfs = false,
    }) => CnsMicroCurrentSevenSource.parse(
      raw: body ?? raw,
      uris: urls ?? uris,
      receipt: receipt ?? e.receipt,
      corp: corp ?? e.corpCode,
      start: DateTime.utc(year ?? e.year),
      end: DateTime.utc(year ?? e.year, 12, 31),
      consolidated: cfs,
    );
    test(
      '${e.receipt} printed current7 exact crosschecks, no synthesized PPE',
      () async {
        final r = await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          e.basis,
        );
        expect(r.absence, isNull);
        final rows = r.numeric!.rows;
        expect(rows, hasLength(7));
        expect(
          rows.map((r) => r['thstrm_amount']),
          e.year == 2022
              ? [
                  '8857831382',
                  '6935338185',
                  '1922493197',
                  '19991208651',
                  '-147756862',
                  '-412587926',
                  '331138751',
                ]
              : [
                  '25104359650',
                  '14798747907',
                  '10305611743',
                  '8349068677',
                  '590611790',
                  '166398850',
                  '-465157269',
                ],
        );
        final facts = [
          for (final row in rows)
            FinancialFact(
              id: rows.indexOf(row) + 1,
              reportId: 1,
              companyId: 1,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              fsDiv: FsDiv.separate,
              statement: row['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : row['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.incomeStatement,
              accountName: row['account_nm'] as String,
              amount: BigInt.parse(row['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        expect(FinancialAccounts.pick(facts).map((r) => r.key).toSet(), {
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
        });
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['partialCore7'], true);
          expect(p['uncollectedOptionalAccounts'], ['capex']);
          expect(p['fullStatementVerified'], false);
          expect(p['wholeNetIncomeExact'], true);
          expect(p['numericCellCorrection'], false);
          expect(p['genericRoundingTolerance'], false);
          expect(p['priorNumericPeriodsCollected'], false);
          expect(p['printedCurrentPeriodAnomaly'], isNotEmpty);
          expect(row.containsKey('frmtrm_amount'), false);
        }
      },
    );
    test(
      '${e.receipt} exact actor/year/basis/receipt/URI/bytes negative guards',
      () {
        expect(() => parse(corp: '00000000'), throwsFormatException);
        expect(() => parse(receipt: '19990101000000'), throwsFormatException);
        expect(() => parse(year: e.year - 1), throwsFormatException);
        expect(() => parse(cfs: true), throwsFormatException);
        for (final k in raw.keys) {
          expect(
            () => parse(body: {...raw, k: '${raw[k]} '}),
            throwsFormatException,
          );
          expect(
            () => parse(urls: {...uris, k: Uri.parse('${uris[k]}&mutated=1')}),
            throwsFormatException,
          );
        }
      },
    );
  }
}
