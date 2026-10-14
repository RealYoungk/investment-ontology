import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:test/test.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('Company-scoped financial source metadata', (
    builder,
    endpoints,
  ) {
    test('related audit proof is retained while another issuer stays blocked', () async {
      final session = builder.build();
      try {
        final now = DateTime.utc(2026, 10, 13);
        final companies = <Company>[];
        final reports = <FinancialReport>[];
        const digest =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        for (var i = 0; i < 2; i++) {
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: '0000000${i + 1}',
              name: 'scope fixture $i',
            ),
          );
          companies.add(company);
          final receipt = '2026032000000${i + 1}';
          final url = 'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt';
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference: receipt,
              title: 'DART 원문 HTML 부분 핵심계정(7) SHA256:$digest',
              url: url,
              retrievedAt: now,
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: receipt,
              fsDiv: FsDiv.separate,
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (2025.12)',
              factCount: 7,
              sourceId: source.id!,
              fetchedAt: now,
            ),
          );
          reports.add(report);
          if (i == 0) {
            await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference: 'financial-api-noData-source:$receipt:separate',
                url: url,
                retrievedAt: now,
                title: jsonEncode({
                  'action': 'verified-keyless-annual-source-after-api-noData',
                  'targetReceipt': receipt,
                  'sourceReceipt': receipt,
                  'corpCode': company.corpCode,
                  'reportName': report.reportName,
                  'fsDiv': 'separate',
                  'format': 'html',
                  'sha256': digest,
                  'coreRows': 7,
                  'coreRowProvenance': List.generate(
                    7,
                    (_) => {
                      'currency': 'KRW',
                      'html_provenance': {
                        'source': url,
                        'basis': 'OFS',
                        'periodStart': '2025-01-01',
                        'periodEnd': '2025-12-31',
                      },
                    },
                  ),
                }),
              ),
            );
          }
        }
        final global = await FinancialSourceDuration.load(session);
        final first = await FinancialSourceDuration.load(
          session,
          companyIds: [companies[0].id!],
        );
        final second = await FinancialSourceDuration.load(
          session,
          companyIds: [companies[1].id!],
        );
        expect(global.ranges.keys, contains(reports[0].id));
        expect(global.blockedReportIds, {reports[1].id});
        expect(
          first.ranges[reports[0].id]?.label,
          global.ranges[reports[0].id]?.label,
        );
        expect(first.ranges.keys, {reports[0].id});
        expect(first.blockedReportIds, isEmpty);
        expect(second.ranges, isEmpty);
        expect(second.blockedReportIds, {reports[1].id});
        expect(
          (await FinancialSourceDuration.load(session, companyIds: [])).ranges,
          isEmpty,
        );
        expect(
          (await FinancialSourceDuration.load(
            session,
            companyIds: [99999999],
          )).blockedReportIds,
          isEmpty,
        );
      } finally {
        await session.close();
      }
    });
  });
}
