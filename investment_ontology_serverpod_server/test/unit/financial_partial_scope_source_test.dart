import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/curachem_current_seven_source.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in ['20250331003105', '20250305000164']) {
    test('actual $receipt source profile binds public scope', () async {
      final e = VerifiedAnnualSourceRegistry.find(
        receipt,
        FsDiv.separate,
      )!;
      final verified = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      final rows = verified.numeric!.rows;
      final report = FinancialReport(
        companyId: 1,
        rceptNo: e.receipt,
        bsnsYear: 2024,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.separate,
        reportName: '사업보고서 (2024.12)',
        sourceId: 1,
        factCount: 7,
        fetchedAt: DateTime.utc(2026),
      );
      final source = Source(
        kind: SourceKind.dartReport,
        reference: 'financial-api-noData-source:${e.receipt}:separate',
        url: verified.numeric!.statementSource.toString(),
        retrievedAt: DateTime.utc(2026),
        title: jsonEncode({
          'action': 'verified-keyless-annual-source-after-api-noData',
          'targetReceipt': e.receipt,
          'sourceReceipt': e.receipt,
          'format': 'html',
          'corpCode': e.corpCode,
          'fsDiv': 'separate',
          'reportName': report.reportName,
          'sha256': verified.numeric!.sourceDigest,
          'coreRows': rows.length,
          'coreRowProvenance': rows,
        }),
      );
      expect(
        FinancialEndpoint.validPartialScopeSource(source, report, e.corpCode),
        isTrue,
      );
    });
  }
  test(
    'exact seven source binding rejects wrong identity period and provenance',
    () {
      final report = FinancialReport(
        companyId: 1,
        rceptNo: CurachemCurrentSevenSource.receipt,
        bsnsYear: 2024,
        reportCode: FinancialReportCode.annual,
        fsDiv: FsDiv.separate,
        reportName: '사업보고서 (2024.12)',
        sourceId: 2,
        factCount: 7,
        fetchedAt: DateTime.utc(2026),
      );
      Map<String, dynamic> payload() => {
        'action': 'verified-keyless-annual-source-after-api-noData',
        'targetReceipt': report.rceptNo,
        'corpCode': CurachemCurrentSevenSource.corp,
        'fsDiv': 'separate',
        'reportName': report.reportName,
        'sha256':
            '8c39bff6456acf946f58632df188cf597d85e5abae4d0a3c3d9d32abf08856a5',
        'coreRows': 7,
        'coreRowProvenance': List.generate(
          7,
          (_) => <String, dynamic>{
            'html_provenance': {
              'source': CurachemCurrentSevenSource.bodyUri,
              'sourceSha256': CurachemCurrentSevenSource.bodySha,
              'basis': 'OFS',
              'periodStart': '2024-01-01',
              'periodEnd': '2024-12-31',
              'partialCore7': true,
              'detailHierarchyComplete': false,
              'notesVerified': false,
            },
          },
        ),
      };
      bool check(Map<String, dynamic> value) =>
          FinancialEndpoint.validPartialScopeSource(
            Source(
              kind: SourceKind.dartReport,
              reference:
                  'financial-api-noData-source:${report.rceptNo}:separate',
              url: CurachemCurrentSevenSource.bodyUri,
              title: jsonEncode(value),
              retrievedAt: DateTime.utc(2026),
            ),
            report,
            CurachemCurrentSevenSource.corp,
          );
      Map<String, dynamic> complete() {
        final value = jsonDecode(jsonEncode(payload())) as Map<String, dynamic>;
        value['sourceReceipt'] = report.rceptNo;
        value['format'] = 'html';
        final coords = [
          (0, 31),
          (0, 43),
          (0, 54),
          (1, 1),
          (1, 22),
          (1, 37),
          (3, 1),
        ];
        for (var i = 0; i < 7; i++) {
          final row = value['coreRowProvenance'][i] as Map;
          row['account_nm'] = 'account$i';
          row['thstrm_amount'] = '-1234';
          final proof = row['html_provenance'] as Map;
          proof.addAll(<String, dynamic>{
            'currentCell': '(1,234)',
            'fullStatementCollected': false,
            'allStatementRowsVerified': false,
            'notesReadScopeComplete': false,
            'tableIndex': coords[i].$1,
            'rowIndex': coords[i].$2,
            'column': 3,
            'printedUnit': '원',
            'multiplier': '1',
            'printedLabel': row['account_nm'],
            'missingAccountReasons': {
              'capex': 'No printed whole PPE acquisition total; research-equipment component is not the total.',
            },
          });
        }
        return value;
      }

      expect(check(complete()), isTrue);
      for (final key in [
        'sourceReceipt',
        'format',
        'action',
        'targetReceipt',
        'corpCode',
        'fsDiv',
        'reportName',
        'sha256',
        'coreRows',
      ]) {
        final value = complete();
        value[key] = 'wrong';
        expect(check(value), isFalse, reason: key);
      }
      for (final key in [
        'currentCell',
        'tableIndex',
        'rowIndex',
        'column',
        'missingAccountReasons',
        'fullStatementCollected',
        'source',
        'sourceSha256',
        'basis',
        'periodStart',
        'periodEnd',
        'partialCore7',
        'detailHierarchyComplete',
        'notesVerified',
      ]) {
        final value = complete();
        (value['coreRowProvenance'][0]['html_provenance'] as Map)[key] =
            'wrong';
        expect(check(value), isFalse, reason: key);
      }
    },
  );
}
