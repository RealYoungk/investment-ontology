import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Source-proved short annual periods', (builder, endpoints) {
    late Session session;
    setUp(() {
      session = builder.build();
      ScreenEndpoint.clearCache();
      ScreenEndpoint.serveStaleWhileRefreshing = false;
    });
    tearDown(() async {
      await session.close();
      ScreenEndpoint.clearCache();
      ScreenEndpoint.serveStaleWhileRefreshing = true;
    });
    test('actual EMT 90-day report keeps raw core and balances, blocks TTM before and after audit', () async {
      const receipt = '20260709000400';
      const corp = '00925967';
      const url =
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=21&offset=109130&length=43771&dtd=dart4.xsd';
      const dir = 'test/fixtures/financial_html/standard-annual/20260709000400';
      final body = File('$dir/separate-statement.html').readAsStringSync();
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$dir/cover.html').readAsStringSync(),
        statementHtml: body,
        coverSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=1&offset=951&length=4480&dtd=dart4.xsd',
        ),
        statementSource: Uri.parse(url),
        receipt: receipt,
        corpCode: corp,
        companyName: '이엠티',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 3, 31),
        consolidated: false,
      );
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: corp,
          name: '이엠티',
          stockCode: '999999',
          market: Market.kosdaq,
        ),
      );
      final digest = sha256.convert(utf8.encode(body)).toString();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: receipt,
          url: url,
          title:
              'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · SHA256:$digest',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      const reportName = '사업보고서 (2026.03)';
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: receipt,
          corpCode: corp,
          companyId: company.id,
          reportName: reportName,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: DateTime.utc(2026),
        ),
      );
      final report = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: company.id!,
          rceptNo: receipt,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          reportName: reportName,
          sourceId: source.id!,
          factCount: rows.length,
          fetchedAt: DateTime.utc(2026),
        ),
      );
      await FinancialFact.db.insert(
        session,
        FinancialRows.toFacts(
          rows,
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: source.id!,
        ).facts,
      );
      final security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR_SHORT',
          shortCode: '999999',
          name: '이엠티',
          companyId: company.id,
          lastSeenDate: DateTime.utc(2026, 10, 1),
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: DateTime.utc(2026, 10, 1),
          marketCap: BigInt.from(100000000000),
          sourceId: source.id!,
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(
          baseDate: DateTime.utc(2026, 10, 1),
          rowCount: 1,
          fetchedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      Future<void> check(String label) async {
        final summary = (await FinancialEndpoint().summary(
          session,
          corp,
          fsDiv: FsDiv.separate,
        ))!;
        expect(summary.periods.single.periodName, label);
        expect(
          summary.periods.single.lines
              .singleWhere((l) => l.key == 'revenue')
              .amount,
          BigInt.from(22224597290),
        );
        expect(
          summary.periods.single.lines
              .singleWhere((l) => l.key == 'assets')
              .amount,
          BigInt.from(165992336930),
        );
        final durations = await FinancialSourceDuration.load(
          session,
          companyIds: [company.id!],
        );
        expect(durations.blockedReportIds, {report.id!});
        final ttm = await session.db.unsafeQuery(
          'WITH ${FinancialBasis.ctes(companyId: company.id!, blockedAnnualFlowReportIds: durations.blockedReportIds)} SELECT v FROM ttm',
        );
        expect(ttm.every((r) => r[0] == null), isTrue);
        ScreenEndpoint.clearCache();
        final screen = (await ScreenEndpoint().list(
          session,
          corpCodes: [corp],
        )).items.single;
        expect(screen.revenue, isNull);
        expect(screen.netIncome, isNull);
        final detail = (await FinancialEndpoint().report(session, report.id!))!;
        expect(detail.facts.where((f) => f.amount != null).length, rows.length);
      }

      await check('원문 보고기간 확인 필요');
      final audit = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: 'financial-api-noData-source:$receipt:separate',
          url: url,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode({
            'action': 'verified-keyless-annual-source-after-api-noData',
            'targetReceipt': receipt,
            'sourceReceipt': receipt,
            'corpCode': corp,
            'reportName': reportName,
            'fsDiv': 'separate',
            'format': 'html',
            'sha256': digest,
            'coreRows': rows.length,
            'coreRowProvenance': rows,
          }),
        ),
      );
      await check('2026.01.01 ~ 2026.03.31 (90일)');
      await Source.db.updateRow(session, audit.copyWith(title: '{malformed'));
      await check('원문 보고기간 확인 필요');
      // General partial XBRL without a duration audit is also fail-closed;
      // the separately named Sunjin recovery is not classified by this prefix.
      await Source.db.updateRow(
        session,
        source.copyWith(title: 'DART 원문 XBRL 핵심계정 · SHA256:$digest'),
      );
      await check('원문 보고기간 확인 필요');
    });
  });
}
