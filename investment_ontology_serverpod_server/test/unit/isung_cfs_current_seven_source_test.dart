import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/isung_cfs_current_seven_source.dart';

void main() {
  for (final receipt in ['20230323000123', '20240321000294']) {
    final profile = IsungCfsCurrentSevenSource.profiles[receipt] as Map;
    final year = profile['year'] as int;
    final dir =
        'assets/financial_source_cache/$receipt-cfs-isung-current-seven';
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final raw = <String, String>{};
    final uris = <String, Uri>{};
    for (final source in manifest['sources'] as List) {
      raw[source['label']] = File('$dir/${source['file']}').readAsStringSync();
      uris[source['label']] = Uri.parse(source['url']);
    }
    List<Map<String, dynamic>> parse({
      bool consolidated = true,
      String? corp,
      DateTime? start,
      Map<String, String>? changed,
    }) => IsungCfsCurrentSevenSource.parse(
      raw: changed ?? raw,
      uris: uris,
      receipt: receipt,
      corp: corp ?? '01365384',
      start: start ?? DateTime.utc(year),
      end: DateTime.utc(year, 12, 31),
      consolidated: consolidated,
    );

    test(
      '$receipt actual compound digest and public scope strict binding',
      () async {
        final entry = VerifiedAnnualSourceRegistry.find(
          receipt,
          FsDiv.consolidated,
        )!;
        final f = filing(entry);
        final result = await VerifiedAnnualSourceCache(
          readAsset: (p) async => File(p).readAsBytes(),
        ).verifyRegistered(f, company(entry), entry.basis);
        final actual = result.numeric!;
        expect(actual.sourceDigest, profile['sourceDigest']);
        expect(
          actual.sourceDigest,
          isNot(
            (manifest['sources'] as List).singleWhere(
              (v) => v['label'] == 'cfs',
            )['sha256'],
          ),
        );
        expect(actual.rows, parse());
        final report = FinancialReport(
          companyId: 1,
          rceptNo: receipt,
          bsnsYear: year,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.consolidated,
          reportName: f.reportName,
          factCount: 7,
          sourceId: 1,
          fetchedAt: DateTime.utc(2026),
        );
        final payload = <String, dynamic>{
          'action': 'verified-keyless-annual-source-after-api-noData',
          'targetReceipt': receipt,
          'sourceReceipt': receipt,
          'corpCode': '01365384',
          'fsDiv': 'consolidated',
          'reportName': f.reportName,
          'format': 'html',
          'sha256': actual.sourceDigest,
          'coreRows': 7,
          'coreRowProvenance': actual.rows,
        };
        Source source(Map p) => Source(
          kind: SourceKind.dartReport,
          reference: 'financial-api-noData-source:$receipt:consolidated',
          url: actual.statementSource.toString(),
          title: jsonEncode(p),
          retrievedAt: DateTime.utc(2026),
        );
        expect(
          FinancialEndpoint.validPartialScopeSource(
            source(payload),
            report,
            '01365384',
          ),
          true,
        );
        for (final mutation in <String, dynamic>{
          'sha256': (manifest['sources'] as List).singleWhere(
            (v) => v['label'] == 'cfs',
          )['sha256'],
          'corpCode': '00000000',
          'fsDiv': 'separate',
          'sourceReceipt': '20260323000000',
          'targetReceipt': '20260323000000',
          'coreRows': 8,
        }.entries) {
          expect(
            FinancialEndpoint.validPartialScopeSource(
              source({...payload, mutation.key: mutation.value}),
              report,
              '01365384',
            ),
            false,
            reason: mutation.key,
          );
        }
        for (final bad in [
          source(payload).copyWith(kind: SourceKind.manual),
          source(payload).copyWith(
            url: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260323000000',
          ),
          source(payload).copyWith(
            reference: 'financial-api-noData-source:$receipt:separate',
          ),
        ]) {
          expect(
            FinancialEndpoint.validPartialScopeSource(bad, report, '01365384'),
            false,
          );
        }
        for (final bad in [
          report.copyWith(fsDiv: FsDiv.separate),
          report.copyWith(bsnsYear: year - 1),
          report.copyWith(reportCode: FinancialReportCode.halfYear),
        ]) {
          expect(
            FinancialEndpoint.validPartialScopeSource(
              source(payload),
              bad,
              '01365384',
            ),
            false,
          );
        }
        final changed = jsonDecode(jsonEncode(actual.rows)) as List;
        changed.first['html_provenance']['sourceSha256'] = actual.sourceDigest;
        expect(
          FinancialEndpoint.validPartialScopeSource(
            source({...payload, 'coreRowProvenance': changed}),
            report,
            '01365384',
          ),
          false,
        );
        final facts = [
          for (final row in actual.rows)
            FinancialFact(
              id: actual.rows.indexOf(row) + 1,
              reportId: 1,
              companyId: 1,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              fsDiv: FsDiv.consolidated,
              statement: row['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : row['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : row['sj_div'] == 'CIS'
                  ? FinancialStatementKind.comprehensiveIncome
                  : FinancialStatementKind.incomeStatement,
              accountName: row['account_nm'] as String,
              amount: BigInt.parse(row['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        expect(FinancialAccounts.pick(facts).map((v) => v.key).toSet(), {
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
        });
      },
    );
    test('$receipt own current seven exact physical cells', () {
      final rows = parse();
      expect(
        rows,
        jsonDecode(File('$dir/expected-rows.json').readAsStringSync()),
      );
      expect(rows, hasLength(7));
      expect(
        rows.map((r) => r['thstrm_amount']),
        (profile['core'] as List).map((c) => c['value']),
      );
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(int.parse(row['ord'] as String), greaterThan(0));
        final proof = row['html_provenance'] as Map;
        expect(proof['partialCore7'], isTrue);
        expect(proof['fullStatementCollected'], isFalse);
        expect(proof['optionalAccountsNotCollected'], ['capex']);
        expect(proof['cashFx'], contains('no zero'));
        expect(proof['numericCellCorrection'], false);
        expect(proof['notesVerified'], false);
        expect(proof['allStatementRowsVerified'], false);
        expect(proof['FCFSupported'], false);
        expect(row['fs_div'], 'CFS');
        expect(
          proof['sourceSha256'],
          (manifest['sources'] as List).singleWhere(
            (v) => v['label'] == 'cfs',
          )['sha256'],
        );
      }
      final ni = rows.singleWhere(
        (r) => (r['account_nm'] as String).contains('연결당기순손실'),
      );
      final p = ni['html_provenance'] as Map;
      expect(
        ni['thstrm_amount'],
        receipt == '20230323000123' ? '-1637586127' : '-1509318876',
      );
      if (year == 2022) {
        expect(ni['sj_div'], 'CIS');
        expect(p['currentCell'], '(1,637,586,127)');
        expect(p['signNormalization'], 'none');
      } else {
        expect(ni['sj_div'], 'IS');
        expect(p['currentCell'], '1,509,318,876');
        expect(p['printedSign'], 'positive');
        expect(p['normalizedSign'], 'negative');
        expect(
          p['signNormalization'],
          'explicitPrintedLossMagnitudeCorroboratedByCEandCF',
        );
        expect(p['sourceCellRewritten'], false);
      }
      for (final c in profile['checks'] as List) {
        expect(c['missingTermCount'], 0);
        expect(c['residualKRW'], 0);
      }
    });
    test(
      '$receipt rejects opposite basis',
      () => expect(() => parse(consolidated: false), throwsFormatException),
    );
    test(
      '$receipt rejects other issuer',
      () => expect(() => parse(corp: '00000000'), throwsFormatException),
    );
    test(
      '$receipt rejects prior period',
      () => expect(
        () => parse(start: DateTime.utc(year - 1)),
        throwsFormatException,
      ),
    );
    test(
      '$receipt rejects changed original',
      () => expect(
        () => parse(changed: {...raw, 'cfs': '${raw['cfs']} '}),
        throwsFormatException,
      ),
    );
  }
}
