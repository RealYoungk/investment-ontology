import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/curachem_current_seven_source.dart';

void main() {
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
        'sha256': CurachemCurrentSevenSource.bodySha,
        'coreRows': 7,
        'coreRowProvenance': List.generate(
          7,
          (_) => {
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
      expect(check(payload()), isTrue);
      for (final key in [
        'action',
        'targetReceipt',
        'corpCode',
        'fsDiv',
        'reportName',
        'sha256',
        'coreRows',
      ]) {
        final value = payload();
        value[key] = 'wrong';
        expect(check(value), isFalse, reason: key);
      }
      for (final key in [
        'source',
        'sourceSha256',
        'basis',
        'periodStart',
        'periodEnd',
        'partialCore7',
        'detailHierarchyComplete',
        'notesVerified',
      ]) {
        final value = payload();
        (value['coreRowProvenance'][0]['html_provenance'] as Map)[key] =
            'wrong';
        expect(check(value), isFalse, reason: key);
      }
    },
  );
}
