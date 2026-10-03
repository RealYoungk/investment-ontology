import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/uxn_2023_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20240320001200',
    FsDiv.separate,
  )!;
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
    DateTime? start,
    bool cfs = false,
  }) => Uxn2023ExactSource.parse(
    raw: body ?? raw,
    uris: urls ?? uris,
    receipt: receipt ?? e.receipt,
    corp: corp ?? e.corpCode,
    start: start ?? DateTime.utc(2023),
    end: DateTime.utc(2023, 12, 31),
    consolidated: cfs,
  );
  test(
    'own FY2023 current8, period anomaly preserved, unaudited prior excluded',
    () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      expect(result.absence, isNull);
      final rows = result.numeric!.rows;
      expect(rows.map((r) => r['thstrm_amount']), [
        '33395980981',
        '52781999366',
        '-19386018385',
        '336490000',
        '-6807802596',
        '-14009326289',
        '-4456714416',
        '1197626910',
      ]);
      final facts = [
        for (final r in rows)
          FinancialFact(
            id: rows.indexOf(r) + 1,
            reportId: 1,
            companyId: 1,
            bsnsYear: 2023,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
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
      expect(FinancialAccounts.pick(facts).map((line) => line.key).toSet(), {
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
        'capex',
      });
      for (final row in rows) {
        expect(row.containsKey('frmtrm_amount'), false);
        final p = row['html_provenance'] as Map;
        expect(p['printedPLPeriodTitle'], '제12(당)기 2023년 12월 31일 현재');
        expect(p['priorNumericPeriodsCollected'], false);
        expect(p['fullStatementVerified'], false);
        expect(p['numericCellCorrection'], false);
        expect(p['unit'], '원');
        expect(p['periodStart'], '2023-01-01');
      }
    },
  );
  test(
    'exact original actor, current period, basis, source URI and bytes guards',
    () {
      expect(() => parse(corp: '01396930'), throwsFormatException);
      expect(() => parse(receipt: '20230321001434'), throwsFormatException);
      expect(() => parse(start: DateTime.utc(2022)), throwsFormatException);
      expect(() => parse(cfs: true), throwsFormatException);
      for (final label in raw.keys) {
        expect(
          () => parse(body: {...raw, label: '${raw[label]} '}),
          throwsFormatException,
        );
        expect(
          () => parse(
            urls: {...uris, label: Uri.parse('${uris[label]}&altered=1')},
          ),
          throwsFormatException,
        );
      }
      expect(
        () => parse(
          body: {
            ...raw,
            'ofs': raw['ofs']!.replaceFirst('14,009,326,289', '14,009,326,288'),
          },
        ),
        throwsFormatException,
      );
    },
  );
}
