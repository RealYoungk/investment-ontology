import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/heungkuk_current_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  final entries = VerifiedAnnualSourceRegistry.entries.where(
    (e) => HeungkukCurrentExactSource.supports(e.ruleVersion),
  );
  for (final e in entries) {
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
      String? corp,
      DateTime? start,
      bool cfs = false,
      Map<String, String>? body,
      Map<String, Uri>? urls,
    }) => HeungkukCurrentExactSource.parse(
      raw: body ?? raw,
      uris: urls ?? uris,
      receipt: e.receipt,
      corp: corp ?? e.corpCode,
      start: start ?? DateTime.utc(e.year),
      end: DateTime.utc(e.year, 12, 31),
      consolidated: cfs,
    );
    test(
      '${e.year} directly printed current eight and exact source cash scope',
      () async {
        final rows = parse();
        expect(rows, hasLength(8));
        expect(
          rows.map((r) => r['thstrm_amount']).toSet(),
          e.year == 2022
              ? {
                  '13966098000000',
                  '13246051000000',
                  '720047000000',
                  '4528860000000',
                  '185978000000',
                  '147508000000',
                  '356205000000',
                  '7445000000',
                }
              : {
                  '13762260000000',
                  '13071612000000',
                  '690648000000',
                  '4514595000000',
                  '77138000000',
                  '62045000000',
                  '389598000000',
                  '4844000000',
                },
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
        final ni = rows[5]['account_nm'] as String;
        expect(
          FinancialAccounts.fallbackNames['netIncome'],
          contains(ni.substring(ni.indexOf('당기순이익')).replaceAll(' ', '')),
        );
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['fullStatementCollected'], false);
          expect(p['notesVerified'], false);
          expect(p['numericCellCorrection'], false);
          expect(p['unit'], '백만원');
          final cash = p['cashScopeProof'] as Map;
          expect(cash['priorNote43CashConflict'], e.year == 2021);
          expect(
            cash['priorNote43DifferencePrintedMillion'],
            e.year == 2021 ? 1 : 0,
          );
          expect(
            cash['currentCFCashPrinted'],
            e.year == 2022 ? '64062' : '90275',
          );
          expect(cash['currentDepositPrinted'], e.year == 2022 ? '5' : '13');
        }
        final filing = DartFiling(
          id: 1,
          companyId: 1,
          rceptNo: e.receipt,
          corpCode: e.corpCode,
          bsnsYear: e.year,
          reportName: '사업보고서 (${e.year}.12)',
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'api-noData-annual-public:attempt=3; source failure',
          discoveredAt: DateTime.utc(2026),
        );
        final result =
            await VerifiedAnnualSourceCache(
              readAsset: (p) => File(p).readAsBytes(),
            ).verifyRegistered(
              filing,
              Company(
                id: 1,
                corpCode: e.corpCode,
                name: e.companyName,
                stockCode: '000001',
                fiscalMonth: 12,
              ),
              FsDiv.separate,
            );
        expect(result.absence, isNull);
        expect(result.numeric!.rows, rows);
      },
    );
    test(
      '${e.year} guards own company, exact period, opposite basis and raw notes',
      () {
        expect(() => parse(corp: '00000000'), throwsFormatException);
        expect(
          () => parse(start: DateTime.utc(e.year, 3, 17)),
          throwsFormatException,
        );
        expect(() => parse(cfs: true), throwsFormatException);
        expect(
          () => parse(body: {...raw, 'notes': '${raw['notes']} '}),
          throwsFormatException,
        );
        expect(
          () => parse(
            urls: {...uris, 'notes': Uri.parse('${uris['notes']}&other=1')},
          ),
          throwsFormatException,
        );
        expect(
          () => parse(
            body: {
              ...raw,
              'ofs': raw['ofs']!.replaceFirst(
                e.year == 2022 ? '147,508' : '62,045',
                '0',
              ),
            },
          ),
          throwsFormatException,
        );
      },
    );
  }
}
