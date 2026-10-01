import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';

import '../unit/public_financial_html_cns_period_test.dart' show parseCns;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('CNS source-bound period storage', (builder, endpoints) {
    test('actual HTML core and corroboration audit survive storage and summary', () async {
      final session = builder.build();
      try {
        const receipt = '20260319000677';
        final now = DateTime.utc(2026, 3, 19);
        final rows = parseCns();
        final proof = jsonDecode(
          File('test/fixtures/financial_html/cns-year-only/proof.json')
              .readAsStringSync(),
        ) as Map;
        final url =
            (proof['sources'] as List).singleWhere(
                  (s) => s['label'] == 'ofs',
                )['url']
                as String;
        final body = File('test/fixtures/financial_html/cns-year-only/ofs.html')
            .readAsStringSync();
        final digest = sha256.convert(utf8.encode(body)).toString();
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: '01116380',
            name: '씨앤에스링크',
            stockCode: '999997',
            market: Market.konex,
          ),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: receipt,
            url: url,
            title:
                'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · SHA256:$digest',
            retrievedAt: now,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id,
            corpCode: c.corpCode,
            rceptNo: receipt,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            discoveredAt: now,
            separateStatus: FilingFetchStatus.stored,
            consolidatedStatus: FilingFetchStatus.noData,
          ),
        );
        final report = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: c.id!,
            rceptNo: receipt,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            reportName: '사업보고서 (2025.12)',
            sourceId: source.id!,
            factCount: rows.length,
            fetchedAt: now,
          ),
        );
        await FinancialFact.db.insert(
          session,
          FinancialRows.toFacts(
            rows,
            reportId: report.id!,
            companyId: c.id!,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            sourceId: source.id!,
          ).facts,
        );
        final audit = await Source.db.insertRow(
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
              'corpCode': c.corpCode,
              'reportName': '사업보고서 (2025.12)',
              'fsDiv': 'separate',
              'format': 'html',
              'sha256': digest,
              'coreRows': rows.length,
              'coreRowProvenance': rows,
            }),
          ),
        );
        final summary = (await FinancialEndpoint().summary(
          session,
          c.corpCode,
          fsDiv: FsDiv.separate,
        ))!;
        final lines = summary.periods.single.lines;
        expect(
          lines.singleWhere((l) => l.key == 'revenue').amount,
          BigInt.from(17944404122),
        );
        expect(
          lines.singleWhere((l) => l.key == 'netIncome').amount,
          BigInt.from(1179965236),
        );
        expect(
          lines.singleWhere((l) => l.key == 'equity').amount,
          BigInt.from(3800784543),
        );
        expect(summary.periods.single.periodName, contains('2025.01.01'));
        expect(lines.every((l) => l.accountId == null), isTrue);
        final security = await Security.db.insertRow(
          session,
          Security(
            isinCode: 'KR_CNS',
            shortCode: '999997',
            name: c.name,
            companyId: c.id,
            lastSeenDate: now,
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: security.id!,
            baseDate: now,
            marketCap: BigInt.from(10000000000),
            sourceId: source.id!,
          ),
        );
        await MarketSnapshotDay.db.insertRow(
          session,
          MarketSnapshotDay(baseDate: now, rowCount: 1, fetchedAt: now),
        );
        ScreenEndpoint.clearCache();
        ScreenEndpoint.serveStaleWhileRefreshing = false;
        try {
          final screen = (await ScreenEndpoint().list(
            session,
            corpCodes: [c.corpCode],
          )).items.single;
          expect(screen.revenue, BigInt.from(17944404122));
          expect(screen.netIncome, BigInt.from(1179965236));
          expect(screen.freeCashFlow, isNull);
          expect(
            lines.singleWhere((l) => l.key == 'revenue').accountName,
            contains('(주석16,17)'),
          );
        } finally {
          ScreenEndpoint.serveStaleWhileRefreshing = true;
          ScreenEndpoint.clearCache();
        }
        final saved = jsonDecode(
          (await Source.db.findById(session, audit.id!))!.title,
        ) as Map;
        expect(
          saved['coreRowProvenance'][0]['html_provenance']['supportingPeriodEvidence']['periodEnd'],
          '2025-12-31',
        );
      } finally {
        await session.close();
      }
    });
  });
}
