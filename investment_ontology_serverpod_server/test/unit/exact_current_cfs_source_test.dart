import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_current_cfs_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  for (final p in ExactCurrentCfsSource.profiles) {
    final receipt = p['receipt'] as String,
        corp = p['corp'] as String,
        name = p['name'] as String;
    final dir = 'assets/financial_source_cache/$receipt-cfs-exact-current';
    final raw = <String, String>{
      for (final s in p['sources'] as List)
        s['label'] as String: File('$dir/${s['file']}').readAsStringSync(),
    };
    final uris = <String, Uri>{
      for (final s in p['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? body,
      Map<String, Uri>? urls,
      String? issuer,
      String? company,
      bool consolidated = true,
      DateTime? start,
    }) => ExactCurrentCfsSource.parse(
      receipt: receipt,
      corpCode: issuer ?? corp,
      companyName: company ?? name,
      consolidated: consolidated,
      start: start ?? DateTime.utc(2024),
      end: DateTime.utc(2024, 12, 31),
      raw: body ?? raw,
      uris: urls ?? uris,
    );
    test('$receipt own CFS direct seven and whole source proof', () {
      final rows = parse();
      expect(rows.length, 7);
      final cells = (p['core'] as List).cast<Map>();
      for (var i = 0; i < 7; i++) {
        expect(rows[i]['thstrm_amount'], cells[i]['amountKRW']);
        expect(rows[i]['account_nm'], cells[i]['printedLabel']);
        expect(rows[i]['account_id'], isNull);
        expect(rows[i]['fs_div'], 'CFS');
        final proof =
            (rows[i]['html_provenance'] as Map)['supportingPeriodEvidence']
                as Map;
        expect(proof['fullStatementCollected'], false);
        expect(proof['optionalAccountsNotCollected'], ['capex']);
        expect(proof['issuerPrintedInStatement'], receipt == '20250424000405');
      }
      final facts = [
        for (var i = 0; i < rows.length; i++)
          FinancialFact(
            id: i + 1,
            reportId: 1,
            companyId: 1,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.consolidated,
            statement: i < 3
                ? FinancialStatementKind.balanceSheet
                : i == 6
                ? FinancialStatementKind.cashFlow
                : FinancialStatementKind.comprehensiveIncome,
            accountName: rows[i]['account_nm'] as String,
            amount: BigInt.parse(rows[i]['thstrm_amount'] as String),
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
    });
    for (final label in ['shell', 'cover', 'cfs']) {
      test('$receipt changed $label raw rejected', () {
        expect(
          () => parse(
            body: {...raw, label: raw[label]!.replaceFirst('2024', '2023')},
          ),
          throwsFormatException,
        );
      });
      test('$receipt changed $label coordinates rejected', () {
        expect(
          () => parse(
            urls: {
              ...uris,
              label: Uri.parse(
                'https://dart.fss.or.kr/report/viewer.do?rcpNo=00000000000000',
              ),
            },
          ),
          throwsFormatException,
        );
      });
    }
    test('$receipt cross basis period and issuer rejected', () {
      expect(() => parse(consolidated: false), throwsFormatException);
      expect(() => parse(start: DateTime.utc(2023)), throwsFormatException);
      expect(() => parse(issuer: '00000000'), throwsFormatException);
      expect(() => parse(company: 'other'), throwsFormatException);
    });
    test('$receipt packaged cache normal proof unchanged filing', () async {
      final e = VerifiedAnnualSourceRegistry.entries.singleWhere(
        (e) => e.receipt == receipt && e.basis == FsDiv.consolidated,
      );
      final f = DartFiling(
        id: 1,
        companyId: 1,
        corpCode: corp,
        rceptNo: receipt,
        bsnsYear: 2024,
        reportCode: FinancialReportCode.annual,
        reportName: '사업보고서 (2024.12)',
        consolidatedStatus: FilingFetchStatus.failed,
        separateStatus: FilingFetchStatus.failed,
        attempts: 7,
        lastError: 'api-noData-annual-public:attempt=3;',
        discoveredAt: DateTime.utc(2026),
      );
      final before = jsonEncode(f.toJson());
      final company = Company(
        id: 1,
        corpCode: corp,
        name: name,
        stockCode: '123456',
        fiscalMonth: 12,
      );
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        f,
        company,
        e.basis,
      );
      expect(result.numeric!.rows.length, 7);
      expect(result.absence, isNull);
      expect(jsonEncode(f.toJson()), before);
    });
  }
  test('caller cannot change immutable profile', () {
    final p = ExactCurrentCfsSource.profiles.first;
    p['corp'] = '00000000';
    expect(ExactCurrentCfsSource.profiles.first['corp'], '00861100');
  });
}
