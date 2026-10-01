import 'dart:convert';
import 'dart:io';

import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'test_tools/serverpod_test_tools.dart';

class HalfClient extends DartClient {
  HalfClient()
    : super(
        'synthetic-test-key',
        httpClient: MockClient(
          (r) async =>
              http.Response('{"status":"013","message":"no data"}', 200),
        ),
      );
  int financialCalls = 0;
  @override
  Future<List<Map<String, dynamic>>?> fetchFinancialStatements({
    required String corpCode,
    required int bsnsYear,
    required String reportCode,
    required String fsDiv,
  }) async {
    financialCalls++;
    return super.fetchFinancialStatements(
      corpCode: corpCode,
      bsnsYear: bsnsYear,
      reportCode: reportCode,
      fsDiv: fsDiv,
    );
  }

  int publicCalls = 0;
  Future<void> Function()? afterZip;
  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async {
    publicCalls++;
    await afterZip?.call();
    return (
      zip: File('test/fixtures/financial_xbrl/duksan-half/original.zip')
          .readAsBytesSync(),
      source: Uri.parse(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$receipt&dcm_no=11523776&lang=ko',
      ),
    );
  }
}

void main() {
  withServerpod('Keyless pending half source', (builder, endpoints) {
    test('fresh annual work wins over half failure backoff with a single resume reservation', () async {
      final session = builder.build();
      final client = HalfClient();
      final now = DateTime.utc(2026, 10, 2);
      final reservations = <DateTime>[];
      try {
        final halfCompany = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00960623',
            name: '덕산넵코어스 주식회사',
            stockCode: '489790',
            market: Market.kosdaq,
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: '20260813000889',
            corpCode: halfCompany.corpCode,
            companyId: halfCompany.id,
            reportName: '반기보고서 (2026.06)',
            bsnsYear: 2026,
            reportCode: FinancialReportCode.halfYear,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: now,
          ),
        );
        for (var i = 0; i < 7; i++) {
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: '9000000$i',
              name: 'Annual $i',
              stockCode: '90000$i',
              market: Market.kosdaq,
              fiscalMonth: 12,
            ),
          );
          await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '2026031900000$i',
              corpCode: c.corpCode,
              companyId: c.id,
              reportName: '사업보고서 (2025.12)',
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
              discoveredAt: now,
            ),
          );
        }
        final job = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await FinancialFactsSync(
          session,
          client,
          job.id!,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
          scheduleResume: (at) async {
            reservations.add(at);
          },
        ).run();
        expect(reservations, [now.add(const Duration(seconds: 30))]);
        final done = (await IngestJob.db.findById(session, job.id!))!;
        expect(done.apiCalls, 1); // Existing global filing-feed allowance.
        expect(client.financialCalls, 0);
        expect(done.message, contains('남은'));
        final half = (await DartFiling.db.findFirstRow(
          session,
          where: (t) => t.rceptNo.equals('20260813000889'),
        ))!;
        expect(half.separateStatus, FilingFetchStatus.stored);
        expect(half.consolidatedStatus, FilingFetchStatus.failed);
        expect(half.attempts, 0);
      } finally {
        await session.close();
        client.close();
      }
    });
    test('exact OFS stores quarter and cumulative from actual source while unavailable CFS fails finitely', () async {
      final session = builder.build();
      final client = HalfClient();
      try {
        final now = DateTime.utc(2026, 10, 2);
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00960623',
            name: '덕산넵코어스 주식회사',
            stockCode: '489790',
            market: Market.kosdaq,
            fiscalMonth: 12,
          ),
        );
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: '20260813000889',
            corpCode: company.corpCode,
            companyId: company.id,
            reportName: '반기보고서 (2026.06)',
            bsnsYear: 2026,
            reportCode: FinancialReportCode.halfYear,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: now,
          ),
        );
        Future<IngestJob> run() async {
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            corpCode: company.corpCode,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          return (await IngestJob.db.findById(session, job.id!))!;
        }

        final job = await run();
        expect(job.apiCalls, 0);
        final report = (await FinancialReport.db.find(session)).single;
        expect(report.rceptNo, filing.rceptNo);
        expect(report.fsDiv, FsDiv.separate);
        expect(report.reportCode, FinancialReportCode.halfYear);
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.reference, filing.rceptNo);
        expect(source.title, contains('반기 부분 핵심7계정'));
        expect(source.url, contains('rcp_no=${filing.rceptNo}'));
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts.length, 7);
        final revenue = facts.singleWhere(
          (f) => f.accountId == 'ifrs-full_Revenue',
        );
        expect(revenue.amount, BigInt.from(11795577500));
        expect(revenue.cumulativeAmount, BigInt.from(23769258694));
        final cf = facts.singleWhere(
          (f) =>
              f.accountId == 'ifrs-full_CashFlowsFromUsedInOperatingActivities',
        );
        expect(cf.amount, BigInt.from(-4053641467));
        final audit = (await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'pending-half-xbrl-source:${filing.rceptNo}:separate',
          ),
        ))!;
        expect((jsonDecode(audit.title) as Map)['coreRows'], 7);
        var current = (await DartFiling.db.findById(session, filing.id!))!;
        expect(current.separateStatus, FilingFetchStatus.stored);
        expect(current.consolidatedStatus, FilingFetchStatus.failed);
        expect(current.attempts, 0);
        final sourceId = report.sourceId;
        final ids = facts.map((f) => f.id).toSet();
        await run();
        await run();
        await run();
        current = (await DartFiling.db.findById(session, filing.id!))!;
        expect(current.attempts, 0);
        expect(current.lastError, contains('attempt=3'));
        expect(client.publicCalls, 3);
        expect(current.consolidatedStatus, FilingFetchStatus.failed);
        expect(
          (await FinancialReport.db.findById(session, report.id!))!.sourceId,
          sourceId,
        );
        expect(
          (await FinancialFact.db.find(session)).map((f) => f.id).toSet(),
          ids,
        );
        final nextJob = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now.add(const Duration(days: 1)),
          ),
        );
        await FinancialFactsSync(
          session,
          client,
          nextJob.id!,
          corpCode: company.corpCode,
          dailyBudget: 20,
          clock: () => now.add(const Duration(days: 1)),
          callInterval: Duration.zero,
        ).run();
        current = (await DartFiling.db.findById(session, filing.id!))!;
        expect(current.consolidatedStatus, FilingFetchStatus.noData);
        expect(current.separateStatus, FilingFetchStatus.stored);
        expect(client.publicCalls, 3);
      } finally {
        client.close();
        await session.close();
      }
    });
    test(
      'cancellation after ZIP leaves numbers, audits and attempts untouched',
      () async {
        final session = builder.build(), client = HalfClient();
        try {
          final now = DateTime.utc(2026, 10, 2);
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: '00960623',
              name: '덕산넵코어스',
              stockCode: '489790',
              market: Market.kosdaq,
              fiscalMonth: 12,
            ),
          );
          final f = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '20260813000889',
              corpCode: c.corpCode,
              companyId: c.id,
              reportName: '반기보고서 (2026.06)',
              bsnsYear: 2026,
              reportCode: FinancialReportCode.halfYear,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.pending,
              discoveredAt: now,
            ),
          );
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          client.afterZip = () async {
            await IngestJob.db.updateRow(
              session,
              job.copyWith(status: IngestStatus.cancelled),
            );
          };
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            corpCode: c.corpCode,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(await FinancialReport.db.count(session), 0);
          expect(await FinancialFact.db.count(session), 0);
          expect(await Source.db.count(session), 0);
          final current = (await DartFiling.db.findById(session, f.id!))!;
          expect(current.attempts, 0);
          expect(current.separateStatus, FilingFetchStatus.pending);
        } finally {
          client.close();
          await session.close();
        }
      },
    );
  });
}
