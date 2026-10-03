import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import '../unit/public_financial_html_nine_historical_cfs_test.dart' as fixture;
import 'financial_facts_sync_test.dart' show AnnualNoDataClient;
import 'test_tools/serverpod_test_tools.dart';

class NineHistoricalClient extends AnnualNoDataClient {
  final requested = <String>[];
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
    requested.add(receipt);
    if (!fixture.cases().any((c) => c['rceptNo'] == receipt)) {
      throw const FormatException('Unsupported generic source');
    }
    return fixture.actual(
      fixture.cases().indexWhere((r) => r['rceptNo'] == receipt),
    );
  }
}

void main() {
  withServerpod('Nine actual CFS none source', (builder, endpoints) {
    test('normal API0 nine CFS audit preserves all old OFS numbers sources attempts', () async {
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
      // Generic later-period failures are inserted first. Finite reviewed sources
      // must consume the normal ten-attempt batch before these unrelated rows.
      for (var i = 0; i < 10; i++) {
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '8${i.toString().padLeft(7, '0')}',
            name: 'Generic $i',
            market: Market.konex,
            stockCode: i.toString().padLeft(6, '0'),
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id,
            corpCode: company.corpCode,
            rceptNo: '20260930${i.toString().padLeft(6, '0')}',
            reportName: '사업보고서 (2025.12)',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 1,
            lastError: 'api-noData-annual-public:attempt=2',
            discoveredAt: now,
          ),
        );
      }
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
                fiscalMonth: c['month'],
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
      final client = NineHistoricalClient();
      await FinancialFactsSync(
        session,
        client,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(client.financialRequests, 0);
      expect(client.requested.take(9).toSet(), {
        for (final c in fixture.cases()) c['rceptNo'],
      });
      expect(client.htmlRequests, 10);
      expect(await FinancialReport.db.count(session), 9);
      expect(await FinancialFact.db.count(session), 9);
      for (final old in snapshots) {
        final f = (await DartFiling.db.findById(session, old.filing.id!))!;
        expect(f.consolidatedStatus, FilingFetchStatus.noData);
        expect(f.separateStatus, FilingFetchStatus.stored);
        expect(f.attempts, 3);
        expect(f.lastError, contains('api-noData-annual-public:attempt=2'));
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
        final c = fixture.cases().singleWhere((c) => c['rceptNo'] == f.rceptNo);
        expect(proof['corpCode'], f.corpCode);
        expect(audit.kind, SourceKind.dartReport);
        expect(proof['statementSource'], contains('rcpNo=${f.rceptNo}&'));
        expect(proof['fsDiv'], 'consolidated');
        expect(
          proof['periodStart'],
          (c['month'] == 9
                  ? DateTime.utc(c['bsnsYear'] - 1, 10)
                  : DateTime.utc(c['bsnsYear']))
              .toIso8601String(),
        );
        expect(
          proof['periodEnd'],
          DateTime.utc(f.bsnsYear!, c['month'] + 1, 0).toIso8601String(),
        );
      }
      final done = (await IngestJob.db.findById(session, job.id!))!;
      expect(done.updated, 0);
    });
  });
}
