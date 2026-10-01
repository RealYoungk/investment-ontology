import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  const dir = 'test/fixtures/financial_html/standard-annual';
  final sources =
      jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
  final reviewed = jsonDecode(
    File('$dir/reviewed-current-core-evidence.json').readAsStringSync(),
  ) as List;
  withServerpod('Primary HTML labels in summary and screener', (
    builder,
    endpoints,
  ) {
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
    test('actual Luxpia whole losses stay negative in summary and screener', () async {
      const dir = 'test/fixtures/financial_html/annual-labels';
      const receipt = '20260629000311';
      final all =
          jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
      final e = all.singleWhere((v) => v['receipt'] == receipt) as Map;
      final body = File('$dir/$receipt/separate.html').readAsStringSync();
      final start = DateTime.parse('${e['start']}T00:00:00Z');
      final end = DateTime.parse('${e['end']}T00:00:00Z');
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$dir/$receipt/cover.html').readAsStringSync(),
        statementHtml: body,
        coverSource: Uri.parse(e['urls']['cover']),
        statementSource: Uri.parse(e['urls']['separate']),
        receipt: receipt,
        corpCode: e['corpCode'],
        companyName: e['name'],
        periodStart: start,
        periodEnd: end,
        consolidated: false,
      );
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: e['corpCode'],
          name: e['name'],
          stockCode: '999998',
          market: Market.kosdaq,
        ),
      );
      final digest = sha256.convert(utf8.encode(body)).toString();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: receipt,
          url: e['urls']['separate'],
          title:
              'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · SHA256:$digest',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      final reportName =
          '사업보고서 (${end.year}.${end.month.toString().padLeft(2, '0')})';
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: receipt,
          corpCode: company.corpCode,
          companyId: company.id,
          reportName: reportName,
          bsnsYear: end.year,
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
          bsnsYear: end.year,
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
          bsnsYear: end.year,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: source.id!,
        ).facts,
      );
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: 'financial-api-noData-source:$receipt:separate',
          url: source.url,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode({
            'action': 'verified-keyless-annual-source-after-api-noData',
            'targetReceipt': receipt,
            'sourceReceipt': receipt,
            'corpCode': company.corpCode,
            'reportName': reportName,
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
        company.corpCode,
        fsDiv: FsDiv.separate,
      ))!;
      final op = summary.periods.single.lines.singleWhere(
        (l) => l.key == 'operatingIncome',
      );
      final net = summary.periods.single.lines.singleWhere(
        (l) => l.key == 'netIncome',
      );
      expect(op.amount, BigInt.from(-1263543904));
      expect(net.amount, BigInt.from(-1858500784));
      expect(op.accountName, contains('영업손실'));
      expect(net.accountName, contains('당기순손실'));
      expect(op.accountId, isNull);
      expect(net.accountId, isNull);
      final security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR_LOSS',
          shortCode: '999998',
          name: company.name,
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
      final screen = (await ScreenEndpoint().list(
        session,
        corpCodes: [company.corpCode],
      )).items.single;
      expect(screen.netIncome, BigInt.from(-1858500784));
      expect(screen.per, isNull);
      // A positive unidentified API loss is ambiguous and must not become profit.
      final raw = (await FinancialFact.db.findFirstRow(
        session,
        where: (t) =>
            t.reportId.equals(report.id!) &
            t.accountName.equals(net.accountName),
      ))!;
      await FinancialFact.db.updateRow(
        session,
        raw.copyWith(amount: BigInt.one),
      );
      expect(
        (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: FsDiv.separate,
        ))!.periods.single.lines.where((l) => l.key == 'netIncome'),
        isEmpty,
      );
      ScreenEndpoint.clearCache();
      expect(
        (await ScreenEndpoint().list(
          session,
          corpCodes: [company.corpCode],
        )).items.single.netIncome,
        isNull,
      );
    });

    test('actual IO whole connected losses stay negative in summary and screener', () async {
      const dir = 'test/fixtures/financial_html/annual-labels';
      const receipt = '20260430001951';
      final all =
          jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
      final e = all.singleWhere((v) => v['receipt'] == receipt) as Map;
      final body = File('$dir/$receipt/consolidated.html').readAsStringSync();
      final start = DateTime.parse('${e['start']}T00:00:00Z');
      final end = DateTime.parse('${e['end']}T00:00:00Z');
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$dir/$receipt/cover.html').readAsStringSync(),
        statementHtml: body,
        coverSource: Uri.parse(e['urls']['cover']),
        statementSource: Uri.parse(e['urls']['consolidated']),
        receipt: receipt,
        corpCode: e['corpCode'],
        companyName: e['name'],
        periodStart: start,
        periodEnd: end,
        consolidated: true,
      );
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: e['corpCode'],
          name: e['name'],
          stockCode: '999998',
          market: Market.kosdaq,
        ),
      );
      final digest = sha256.convert(utf8.encode(body)).toString();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: receipt,
          url: e['urls']['consolidated'],
          title:
              'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · SHA256:$digest',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      final reportName =
          '사업보고서 (${end.year}.${end.month.toString().padLeft(2, '0')})';
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: receipt,
          corpCode: company.corpCode,
          companyId: company.id,
          reportName: reportName,
          bsnsYear: end.year,
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
          bsnsYear: end.year,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.consolidated,
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
          bsnsYear: end.year,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.consolidated,
          sourceId: source.id!,
        ).facts,
      );
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: 'financial-api-noData-source:$receipt:consolidated',
          url: source.url,
          retrievedAt: DateTime.utc(2026),
          title: jsonEncode({
            'action': 'verified-keyless-annual-source-after-api-noData',
            'targetReceipt': receipt,
            'sourceReceipt': receipt,
            'corpCode': company.corpCode,
            'reportName': reportName,
            'fsDiv': 'consolidated',
            'format': 'html',
            'sha256': digest,
            'coreRows': rows.length,
            'coreRowProvenance': rows,
          }),
        ),
      );
      final summary = (await FinancialEndpoint().summary(
        session,
        company.corpCode,
        fsDiv: FsDiv.consolidated,
      ))!;
      final op = summary.periods.single.lines.singleWhere(
        (l) => l.key == 'operatingIncome',
      );
      final net = summary.periods.single.lines.singleWhere(
        (l) => l.key == 'netIncome',
      );
      expect(op.amount, BigInt.from(-4525092778));
      expect(net.amount, BigInt.from(-5291588269));
      expect(op.accountName, contains('영업손실'));
      expect(net.accountName, contains('연결당기순손실'));
      expect(op.accountId, isNull);
      expect(net.accountId, isNull);
      final security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR_LOSS',
          shortCode: '999998',
          name: company.name,
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
      final screen = (await ScreenEndpoint().list(
        session,
        corpCodes: [company.corpCode],
      )).items.single;
      expect(screen.netIncome, BigInt.from(-5291588269));
      expect(screen.per, isNull);
      // A positive unidentified API loss is ambiguous and must not become profit.
      final raw = (await FinancialFact.db.findFirstRow(
        session,
        where: (t) =>
            t.reportId.equals(report.id!) &
            t.accountName.equals(net.accountName),
      ))!;
      await FinancialFact.db.updateRow(
        session,
        raw.copyWith(amount: BigInt.one),
      );
      expect(
        (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: FsDiv.consolidated,
        ))!.periods.single.lines.where((l) => l.key == 'netIncome'),
        isEmpty,
      );
      ScreenEndpoint.clearCache();
      expect(
        (await ScreenEndpoint().list(
          session,
          corpCodes: [company.corpCode],
        )).items.single.netIncome,
        isNull,
      );
    });

    for (final evidence in reviewed.cast<Map>().where(
      (e) => (e['rawCurrentCoreRows'] as List).isNotEmpty,
    )) {
      test(
        '${evidence['receipt']} ${evidence['basis']} resolves all eight printed core amounts',
        () async {
          final receipt = evidence['receipt'] as String;
          final sourceEvidence =
              sources.firstWhere((e) => e['receipt'] == receipt) as Map;
          final period = sourceEvidence['sourcePeriod'] as String;
          final year = int.parse(period.substring(0, 4));
          final end = DateTime.utc(year, int.parse(period.substring(5)) + 1, 0);
          final start = receipt == '20260922000230'
              ? DateTime.utc(2025, 7, 1)
              : DateTime.utc(year, 1, 1);
          final consolidated = evidence['basis'] == 'consolidated';
          final div = consolidated ? FsDiv.consolidated : FsDiv.separate;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: sourceEvidence['corpCode'] as String,
              name: sourceEvidence['name'] as String,
              stockCode: '999999',
              market: Market.kosdaq,
            ),
          );
          final rows = PublicFinancialHtml.parseStandardAnnual(
            coverHtml: File('$dir/$receipt/cover.html').readAsStringSync(),
            statementHtml: File(
              '$dir/$receipt/${evidence['basis']}-statement.html',
            ).readAsStringSync(),
            coverSource: Uri.parse(sourceEvidence['coverUrl'] as String),
            statementSource: Uri.parse(evidence['url'] as String),
            receipt: receipt,
            corpCode: company.corpCode,
            companyName: company.name,
            periodStart: start,
            periodEnd: end,
            consolidated: consolidated,
          );
          final digest = sha256
              .convert(
                utf8.encode(
                  File('$dir/$receipt/${evidence['basis']}-statement.html')
                      .readAsStringSync(),
                ),
              )
              .toString();
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference: receipt,
              title:
                  'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · SHA256:$digest',
              url: evidence['url'] as String,
              retrievedAt: DateTime.utc(2026),
            ),
          );
          final reportName = '사업보고서 ($period)';
          await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: receipt,
              corpCode: company.corpCode,
              companyId: company.id,
              reportName: reportName,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
              discoveredAt: DateTime.utc(2026),
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: receipt,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              fsDiv: div,
              reportName: reportName,
              sourceId: source.id!,
              factCount: rows.length,
              fetchedAt: DateTime.utc(2026),
            ),
          );
          final facts = FinancialRows.toFacts(
            rows,
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            fsDiv: div,
            sourceId: source.id!,
          ).facts;
          await FinancialFact.db.insert(session, facts);
          await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference: 'financial-api-noData-source:$receipt:${div.name}',
              url: source.url,
              retrievedAt: DateTime.utc(2026),
              title: jsonEncode({
                'action': 'verified-keyless-annual-source-after-api-noData',
                'targetReceipt': receipt,
                'sourceReceipt': receipt,
                'corpCode': company.corpCode,
                'reportName': reportName,
                'fsDiv': div.name,
                'format': 'html',
                'sha256': digest,
                'coreRows': rows.length,
                'coreRowProvenance': rows,
              }),
            ),
          );

          final summary = (await FinancialEndpoint().summary(
            session,
            company.corpCode,
            fsDiv: div,
          ))!;
          const keys = [
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
            'capex',
          ];
          final expected = evidence['rawCurrentCoreRows'] as List;
          expect(summary.periods.single.lines.length, 8);
          for (var i = 0; i < keys.length; i++) {
            final line = summary.periods.single.lines.singleWhere(
              (l) => l.key == keys[i],
            );
            expect(line.accountName, expected[i]['printedAccountName']);
            expect(line.accountId, isNull);
            expect(
              line.amount,
              BigInt.parse(expected[i]['currentAmount'] as String),
            );
          }
          final sql = await session.db.unsafeQuery(
            'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT acc,v FROM ttm',
          );
          final ttm = {for (final row in sql) row[0] as String: row[1]};
          expect(
            num.parse('${ttm['ifrs-full_Revenue']}'),
            num.parse(expected[3]['currentAmount'] as String),
          );
          expect(
            num.parse(
              '${ttm['ifrs-full_CashFlowsFromUsedInOperatingActivities']}',
            ),
            num.parse(expected[6]['currentAmount'] as String),
          );
          final security = await Security.db.insertRow(
            session,
            Security(
              isinCode: 'KR_HTML',
              shortCode: '999999',
              name: company.name,
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
          final screen = (await ScreenEndpoint().list(
            session,
            corpCodes: [company.corpCode],
          )).items.single;
          expect(
            screen.revenue,
            BigInt.parse(expected[3]['currentAmount'] as String),
          );
          expect(
            screen.netIncome,
            BigInt.parse(expected[5]['currentAmount'] as String),
          );
          // This is eight source-proved core accounts, not a full financial statement.
          expect(report.factCount, 8);
          // Two source-bound whole totals for the same semantic account remain
          // ambiguous even when their printed ordinal prefixes differ.
          await FinancialFact.db.insertRow(
            session,
            FinancialFact(
              reportId: report.id!,
              companyId: company.id!,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              fsDiv: div,
              statement: FinancialStatementKind.cashFlow,
              accountName: '영업활동현금흐름',
              amount: BigInt.one,
              sourceId: source.id!,
            ),
          );
          final duplicateSummary = (await FinancialEndpoint().summary(
            session,
            company.corpCode,
            fsDiv: div,
          ))!;
          expect(
            duplicateSummary.periods.single.lines.where(
              (l) => l.key == 'operatingCashFlow',
            ),
            isEmpty,
          );
          final duplicateSql = await session.db.unsafeQuery(
            'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT v FROM ttm WHERE acc=\'ifrs-full_CashFlowsFromUsedInOperatingActivities\'',
          );
          expect(
            duplicateSql.isEmpty || duplicateSql.single[0] == null,
            isTrue,
          );
        },
      );
    }
  });
}
