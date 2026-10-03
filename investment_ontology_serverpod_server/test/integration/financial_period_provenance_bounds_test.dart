import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_period_metadata.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class NeverApproveMetadata extends SourceClient {
  int metadataCalls = 0;
  final receipts = <String>[];
  @override
  Future<PublicFinancialPeriodMetadata> fetchAnnualPeriodMetadata(
    String receipt, {
    required String corpCode,
    required String companyName,
    required String targetReceipt,
    required DateTime periodEnd,
    bool halfYear = false,
  }) async {
    metadataCalls++;
    receipts.add(receipt);
    throw const FormatException(
      'Counterfactual candidate has no independently verified official cover',
    );
  }
}

void main() {
  withServerpod('Missing duration bounds and real already-short metadata', (
    builder,
    endpoints,
  ) {
    test('21 unproved existing-original candidates call at most20; do not invent metadata or numeric success; reserve normal next batch', () async {
      final s = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
      final c = await Company.db.insertRow(
        s,
        Company(
          corpCode: '99999999',
          name: 'Explicit counterfactual bounds fixture',
          stockCode: '999999',
          market: Market.konex,
        ),
      );
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      // Counterfactual stored rows test only the bounded scheduling boundary.
      // The client denies every source; no fixed success/SHA/real issuer is invented.
      for (var i = 0; i < 21; i++) {
        final receipt = '20260316${i.toString().padLeft(6, '0')}';
        await DartFiling.db.insertRow(
          s,
          DartFiling(
            companyId: c.id,
            corpCode: c.corpCode,
            rceptNo: receipt,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.stored,
            attempts: 7,
            discoveredAt: now,
          ),
        );
        final src = await Source.db.insertRow(
          s,
          Source(
            kind: SourceKind.dartReport,
            reference: receipt,
            title: 'DART 원문 HTML 부분 핵심계정(counterfactual unverified fixture)',
            url: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
            retrievedAt: now,
          ),
        );
        final r = await FinancialReport.db.insertRow(
          s,
          FinancialReport(
            companyId: c.id!,
            rceptNo: receipt,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            fsDiv: FsDiv.separate,
            sourceId: src.id!,
            factCount: 1,
            fetchedAt: now,
          ),
        );
        await FinancialFact.db.insertRow(
          s,
          FinancialFact(
            companyId: c.id!,
            reportId: r.id!,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            sourceId: src.id!,
            statement: FinancialStatementKind.balanceSheet,
            accountName:
                'counterfactual stored fixture value, not approved source data',
            amount: BigInt.one,
          ),
        );
      }
      final before = jsonEncode(
        (await FinancialFact.db.find(s)).map((f) => f.toJson()).toList(),
      );
      final job = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final client = NeverApproveMetadata(), scheduled = <DateTime>[];
      await FinancialFactsSync(
        s,
        client,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
        scheduleResume: (at) async {
          scheduled.add(at);
        },
      ).run();
      expect(client.metadataCalls, 20);
      expect(
        await Source.db.count(
          s,
          where: (t) => t.reference.like('financial-source-period-anchor:%'),
        ),
        0,
      );
      expect(
        jsonEncode(
          (await FinancialFact.db.find(s)).map((f) => f.toJson()).toList(),
        ),
        before,
      );
      expect(scheduled, hasLength(1));
      expect(scheduled.single, now.add(const Duration(seconds: 30)));
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
      expect(client.calls, 0);
      final nextJob = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now.add(const Duration(seconds: 30)),
        ),
      );
      final nextClient = NeverApproveMetadata(), nextScheduled = <DateTime>[];
      await FinancialFactsSync(
        s,
        nextClient,
        nextJob.id!,
        dailyBudget: 0,
        clock: () => now.add(const Duration(seconds: 30)),
        callInterval: Duration.zero,
        scheduleResume: (at) async {
          nextScheduled.add(at);
        },
      ).run();
      expect(nextClient.metadataCalls, 1);
      expect(nextClient.receipts.single, isNot(isIn(client.receipts)));
      expect({...client.receipts, ...nextClient.receipts}, hasLength(21));
      expect(nextScheduled, [DateTime.utc(2026, 10, 3, 15, 10)]);
      final waitingJob = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now.add(const Duration(minutes: 1)),
        ),
      );
      final waitingClient = NeverApproveMetadata();
      await FinancialFactsSync(
        s,
        waitingClient,
        waitingJob.id!,
        dailyBudget: 0,
        clock: () => now.add(const Duration(minutes: 1)),
        callInterval: Duration.zero,
      ).run();
      expect(
        waitingClient.metadataCalls,
        0,
        reason: 'other normal jobs must not restart a completed rejected cycle before retryAt',
      );
      final scopedJob = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.companyKind,
          status: IngestStatus.running,
          startedAt: now.add(const Duration(minutes: 2)),
        ),
      );
      final scopedClient = NeverApproveMetadata();
      await FinancialFactsSync(
        s,
        scopedClient,
        scopedJob.id!,
        dailyBudget: 0,
        clock: () => now.add(const Duration(minutes: 2)),
        callInterval: Duration.zero,
        corpCode: c.corpCode,
      ).run();
      expect(
        scopedClient.metadataCalls,
        20,
        reason: 'all-company cursor cannot be reused by a company-scoped job',
      );

      expect(
        jsonEncode(
          (await FinancialFact.db.find(s)).map((f) => f.toJson()).toList(),
        ),
        before,
      );
    });
    test('actual EMT90day own cover already verified remains blocked and no metadata fetch is repeated', () async {
      final s = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
      const receipt = '20260709000400';
      final transport = MockClient(
        (r) async => http.Response.bytes(
          File(
            'test/fixtures/financial_period_metadata_emt_short/${r.url.path == '/report/viewer.do' ? 'cover' : 'shell'}.html',
          ).readAsBytesSync(),
          200,
          request: r,
        ),
      );
      final md = await PublicFinancialPeriodMetadata.fetch(
        transport,
        receipt: receipt,
        corpCode: '00925967',
        companyName: '(주)이엠티',
        targetReceipt: receipt,
        periodEnd: DateTime.utc(2026, 3, 31),
        interval: Duration.zero,
      );
      transport.close();
      expect(md.periodStart, DateTime.utc(2026));
      expect(md.periodEnd, DateTime.utc(2026, 3, 31));
      final c = await Company.db.insertRow(
        s,
        Company(
          corpCode: '00925967',
          name: '(주)이엠티',
          stockCode: '232530',
          market: Market.konex,
        ),
      );
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      final f = await DartFiling.db.insertRow(
        s,
        DartFiling(
          companyId: c.id,
          corpCode: c.corpCode,
          rceptNo: receipt,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (2026.03)',
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.stored,
          attempts: 7,
          discoveredAt: now,
        ),
      );
      final src = await Source.db.insertRow(
        s,
        Source(
          kind: SourceKind.dartReport,
          reference: receipt,
          title: 'DART 원문 HTML 부분 핵심계정(existing short metadata test only)',
          url:
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt&dcmNo=11470039&eleId=21&offset=109130&length=43771&dtd=dart4.xsd',
          retrievedAt: now,
        ),
      );
      final r = await FinancialReport.db.insertRow(
        s,
        FinancialReport(
          companyId: c.id!,
          rceptNo: receipt,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (2026.03)',
          fsDiv: FsDiv.separate,
          sourceId: src.id!,
          factCount: 1,
          fetchedAt: now,
        ),
      );
      // Numeric placeholder only makes an existing period stored. No numerical
      // extraction/approval is performed or claimed in this duration-only test.
      await FinancialFact.db.insertRow(
        s,
        FinancialFact(
          companyId: c.id!,
          reportId: r.id!,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: src.id!,
          statement: FinancialStatementKind.balanceSheet,
          accountName:
              'existing synthetic amount preserved, numeric scope unverified',
          amount: BigInt.one,
        ),
      );
      final anchor = await Source.db.insertRow(
        s,
        Source(
          kind: SourceKind.dartReport,
          reference: 'financial-source-period-anchor:$receipt:$receipt',
          url: md.coverSource.toString(),
          retrievedAt: now,
          title: jsonEncode({
            'kind': 'verified-source-cover-period-metadata',
            'sourceReceipt': receipt,
            'targetReceipt': receipt,
            'corpCode': c.corpCode,
            'shellSource': md.shellSource.toString(),
            'coverSource': md.coverSource.toString(),
            'sha256': md.digest,
            'periodStart': md.periodStart.toIso8601String(),
            'periodEnd': md.periodEnd.toIso8601String(),
          }),
        ),
      );
      final before = await FinancialSourceDuration.load(s);
      expect(before.blockedReportIds, contains(r.id));
      expect(before.ranges[r.id]!.days, 90);
      expect(before.ranges[r.id]!.isShort, true);
      final j = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final client = NeverApproveMetadata();
      await FinancialFactsSync(
        s,
        client,
        j.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(client.metadataCalls, 0);
      expect((await DartFiling.db.findById(s, f.id!))!.toJson(), f.toJson());
      expect(
        (await Source.db.findById(s, anchor.id!))!.toJson(),
        anchor.toJson(),
      );
      expect(
        await Source.db.count(
          s,
          where: (t) => t.reference.like('financial-source-period-anchor:%'),
        ),
        1,
      );
      final after = await FinancialSourceDuration.load(s);
      expect(after.blockedReportIds, contains(r.id));
      expect(after.ranges[r.id]!.days, 90);
    });
  });
}
