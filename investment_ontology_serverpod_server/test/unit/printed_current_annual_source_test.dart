import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/printed_current_annual_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

void main() {
  test('caller profile copy cannot change compiled identity', () {
    final copy = PrintedCurrentAnnualSource.profiles.first;
    final original = copy['corp'];
    copy['corp'] = '00000000';
    expect(PrintedCurrentAnnualSource.profiles.first['corp'], original);
  });
  for (final p in PrintedCurrentAnnualSource.profiles) {
    final receipt = p['receipt'] as String, basis = p['basis'] as String;
    final dir = 'assets/financial_source_cache/$receipt-$basis-dated-current';
    final cover = File('$dir/cover.html').readAsStringSync(),
        body = File('$dir/$basis.html').readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? b,
      String? corp,
      String? name,
      Uri? source,
      DateTime? start,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover,
      statementHtml: b ?? body,
      coverSource: Uri.parse(p['coverUri'] as String),
      statementSource: source ?? Uri.parse(p['bodyUri'] as String),
      receipt: receipt,
      corpCode: corp ?? p['corp'] as String,
      companyName: name ?? p['name'] as String,
      periodStart: start ?? DateTime.utc(p['year'] as int),
      periodEnd: DateTime.utc(p['year'] as int, 12, 31),
      consolidated: basis == 'cfs',
    );
    test('$receipt $basis actual seven and printed start', () {
      final rows = parse();
      expect(rows.length, 7);
      final facts = [
        for (final row in rows)
          FinancialFact(
            id: rows.indexOf(row) + 1,
            reportId: 1,
            companyId: 1,
            bsnsYear: p['year'] as int,
            reportCode: FinancialReportCode.annual,
            fsDiv: basis == 'cfs' ? FsDiv.consolidated : FsDiv.separate,
            statement: row['sj_div'] == 'BS'
                ? FinancialStatementKind.balanceSheet
                : row['sj_div'] == 'CIS'
                ? FinancialStatementKind.comprehensiveIncome
                : FinancialStatementKind.cashFlow,
            accountName: row['account_nm'] as String,
            amount: BigInt.parse(row['thstrm_amount'] as String),
            sourceId: 1,
            currency: 'KRW',
          ),
      ];
      expect(
        FinancialAccounts.pick(facts).map((l) => l.key).toSet(),
        containsAll([
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
        ]),
      );

      final cells =
          jsonDecode(
                File('$dir/current-cell-evidence.json').readAsStringSync(),
              )['rows']
              as List;
      for (final cell in cells) {
        final row = rows.singleWhere(
          (r) => r['account_nm'] == cell['printedLabel'],
        );
        expect(row['thstrm_amount'], cell['amount']);
        expect(row['account_id'], null);
        expect(row['currency'], 'KRW');
        expect(
          (row['html_provenance']
              as Map)['supportingPeriodEvidence']['flowCaptionPrintedStart'],
          true,
        );
      }
    });
    for (final token in ['단위', '${p['year']}.01.01', '${p['year']}.12.31']) {
      test('$receipt $basis independent $token mutation', () {
        final changed = body.replaceAll(token, 'CONFLICT');
        expect(changed, isNot(body));
        expect(() => parse(b: changed), throwsFormatException);
      });
    }
    test('$receipt $basis monetary/owner/date/coordinate mutations', () {
      final first = (p['core'] as List).first as Map;
      final printed =
          (first['expected'] as List)[first['column'] as int] as String;
      expect(
        () => parse(b: body.replaceAll(printed, '123,456,789')),
        throwsFormatException,
      );
      expect(() => parse(corp: '00000000'), throwsFormatException);
      expect(() => parse(name: '다른 회사'), throwsFormatException);
      expect(
        () => parse(start: DateTime.utc((p['year'] as int) - 1)),
        throwsFormatException,
      );
      expect(
        () => parse(
          source: Uri.parse(
            (p['bodyUri'] as String).replaceAll(receipt, '20260301000000'),
          ),
        ),
        throwsFormatException,
      );
    });
    test(
      '$receipt $basis unknown receipt/basis and manifest scope rejected',
      () {
        for (final wrong in ['receipt', 'basis', 'cover']) {
          expect(
            () => PrintedCurrentAnnualSource.parse(
              receipt: wrong == 'receipt' ? '20260301000000' : receipt,
              corpCode: p['corp'] as String,
              companyName: p['name'] as String,
              cover: wrong == 'cover'
                  ? cover.replaceAll('${p['year']}', '1999')
                  : cover,
              body: body,
              coverSource: Uri.parse(p['coverUri'] as String),
              statementSource: Uri.parse(p['bodyUri'] as String),
              start: DateTime.utc(p['year'] as int),
              end: DateTime.utc(p['year'] as int, 12, 31),
              consolidated: wrong == 'basis' ? basis != 'cfs' : basis == 'cfs',
            ),
            throwsFormatException,
          );
        }
      },
    );
    test(
      '$receipt $basis immutable cache with cap3 preserves exact source',
      () async {
        final div = basis == 'cfs' ? FsDiv.consolidated : FsDiv.separate,
            entry = VerifiedAnnualSourceRegistry.find(
              receipt,
              basis == 'cfs' ? FsDiv.consolidated : FsDiv.separate,
            )!;
        final company = Company(
          id: 1,
          corpCode: p['corp'] as String,
          name: p['name'] as String,
          stockCode: '123456',
          market: Market.konex,
          fiscalMonth: 12,
        );
        final filing = DartFiling(
          companyId: 1,
          corpCode: company.corpCode,
          rceptNo: receipt,
          reportName: '사업보고서 (${p['year']}.12)',
          bsnsYear: p['year'] as int,
          reportCode: FinancialReportCode.annual,
          receivedDate: DateTime.utc(2026),
          discoveredAt: DateTime.utc(2026),
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          lastError: 'api-noData-annual-public:attempt=3;',
          attempts: 3,
        );
        expect(VerifiedAnnualSourceCache.eligibleFor(filing, entry), true);
        expect(
          VerifiedAnnualSourceCache.eligibleFor(
            filing.copyWith(corpCode: '00000000'),
            entry,
          ),
          false,
        );
        expect(
          VerifiedAnnualSourceCache.eligibleFor(
            filing.copyWith(reportCode: FinancialReportCode.halfYear),
            entry,
          ),
          false,
        );
        expect(
          VerifiedAnnualSourceCache.eligibleFor(
            filing.copyWith(reportName: '사업보고서 (${p['year']}.06)'),
            entry,
          ),
          false,
        );
        expect(
          VerifiedAnnualSourceCache.eligibleFor(
            filing.copyWith(lastError: 'api-noData-annual-public:attempt=2;'),
            entry,
          ),
          false,
        );
        expect(
          VerifiedAnnualSourceCache.eligibleFor(
            filing.copyWith(
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
            ),
            entry,
          ),
          false,
        );

        final result = await VerifiedAnnualSourceCache().verifyRegistered(
          filing,
          company,
          div,
        );
        expect(result.numeric!.rows.length, 7);
        expect(result.numeric!.sourceReceipt, receipt);
        expect(result.absence, null);
      },
    );
  }
}
