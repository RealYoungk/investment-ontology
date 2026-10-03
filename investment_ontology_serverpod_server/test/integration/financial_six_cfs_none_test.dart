import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import '../unit/public_financial_html_six_cfs_none_test.dart' as fixture;
import 'financial_facts_sync_test.dart' show AnnualNoDataClient;
import 'test_tools/serverpod_test_tools.dart';

class SixClient extends AnnualNoDataClient {
  @override
  Future<PublicFinancialHtmlSource> fetchAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    if (!consolidated) throw StateError('OFS sentinel must remain untouched');
    htmlRequests++;
    return fixture.actual(
      fixture.cases().indexWhere((r) => r['rceptNo'] == receipt),
    );
  }
}

void main() {
  withServerpod('Six actual CFS none source', (builder, endpoints) {
    test('normal API0 six CFS audit preserves all old OFS numbers sources attempts', () async {
      final session = builder.build(), now = DateTime.utc(2026, 10, 2);
      final snapshots =
          <
            ({
              DartFiling filing,
              FinancialReport report,
              FinancialFact fact,
              Source source,
            })
          >[];
      final byCorp = <String, Company>{};
      for (final c in fixture.cases()) {
        final company =
            byCorp[c['corpCode']] ??
            await Company.db.insertRow(
              session,
              Company(
                corpCode: c['corpCode'],
                name: c['name'],
                market: Market.konex,
                stockCode: '000001',
                fiscalMonth: 12,
              ),
            );
        byCorp[c['corpCode']] = company;
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: c['rceptNo'],
            corpCode: c['corpCode'],
            companyId: company.id,
            reportName: c['reportName'],
            bsnsYear: c['bsnsYear'],
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.stored,
            attempts: 3,
            lastError: 'api-noData-annual-public:attempt=2',
            discoveredAt: now,
          ),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: '기존 OFS 원본 보존',
            reference: c['rceptNo'],
            url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${c['rceptNo']}',
            retrievedAt: now,
          ),
        );
        final report = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: company.id!,
            rceptNo: c['rceptNo'],
            fsDiv: FsDiv.separate,
            bsnsYear: c['bsnsYear'],
            reportCode: FinancialReportCode.annual,
            reportName: c['reportName'],
            factCount: 1,
            sourceId: source.id!,
            fetchedAt: now,
          ),
        );
        final fact = await FinancialFact.db.insertRow(
          session,
          FinancialFact(
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: c['bsnsYear'],
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            statement: FinancialStatementKind.balanceSheet,
            accountId: 'ifrs-full_Assets',
            accountName: '자산총계',
            amount: BigInt.from(123456),
            sourceId: source.id!,
          ),
        );
        snapshots.add((
          filing: filing,
          report: report,
          fact: fact,
          source: source,
        ));
      }
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final client = SixClient();
      await FinancialFactsSync(
        session,
        client,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(client.financialRequests, 0);
      expect(client.htmlRequests, 6);
      expect(await FinancialReport.db.count(session), 6);
      expect(await FinancialFact.db.count(session), 6);
      for (final old in snapshots) {
        final f = (await DartFiling.db.findById(session, old.filing.id!))!;
        expect(f.consolidatedStatus, FilingFetchStatus.noData);
        expect(f.separateStatus, FilingFetchStatus.stored);
        expect(f.attempts, 3);
        expect(
          (await FinancialReport.db.findById(
            session,
            old.report.id!,
          ))!.toJson(),
          old.report.toJson(),
        );
        expect(
          (await FinancialFact.db.findById(session, old.fact.id!))!.toJson(),
          old.fact.toJson(),
        );
        expect(
          (await Source.db.findById(session, old.source.id!))!.toJson(),
          old.source.toJson(),
        );
        final audit = (await Source.db.find(
          session,
          where: (t) => t.reference.equals(
            'financial-public-basis-not-applicable:${f.rceptNo}:consolidated',
          ),
        )).single;
        final proof = jsonDecode(audit.title) as Map;
        expect(proof['sha256'], matches(r'^[a-f0-9]{64}$'));
        expect(proof['receipt'], f.rceptNo);
        expect(
          proof['periodEnd'],
          DateTime.utc(f.bsnsYear!, 12, 31).toIso8601String(),
        );
      }
      final done = (await IngestJob.db.findById(session, job.id!))!;
      expect(done.updated, 0);
    });
  });
}
