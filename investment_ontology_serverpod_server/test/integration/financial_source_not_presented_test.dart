import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_not_presented.dart';

import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import '../unit/known_annual_source_not_presented_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class NotPresentedClient extends SourceClient {
  int publicCalls = 0;
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
    publicCalls++;
    return actual.fetchNotPresented(
      actual.notPresentedCases.singleWhere((e) => e['receipt'] == receipt),
      corp: corpCode,
      cfs: consolidated,
    );
  }
}

void main() {
  withServerpod('Exact primary statements not presented', (builder, endpoints) {
    for (final e in actual.notPresentedCases) {
      test(
        '${e['receipt']} normal API0 rejection preserves opposite and unique audit',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 3);
          final div = e['basis'] == 'cfs' ? FsDiv.consolidated : FsDiv.separate;
          final opposite = div == FsDiv.consolidated
              ? FsDiv.separate
              : FsDiv.consolidated;
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-03',
              calls: 20000,
            ),
          );
          await DartFilingScan.db.insertRow(
            session,
            DartFilingScan(
              scannedFrom: DateTime.utc(2021, 1, 1),
              scannedThrough: now,
              updatedAt: now,
            ),
          );
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: e['corpCode'],
              name: e['name'],
              stockCode: '123456',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              reference: e['receipt'],
              url: actual.sourceUri(e, 'cover').toString(),
              title: 'immutable opposite',
              retrievedAt: now,
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              fsDiv: opposite,
              bsnsYear: actual.year(e),
              reportCode: FinancialReportCode.annual,
              rceptNo: e['receipt'],
              reportName: e['reportName'],
              sourceId: source.id!,
              factCount: 1,
              fetchedAt: now,
            ),
          );
          final fact = await FinancialFact.db.insertRow(
            session,
            FinancialFact(
              companyId: company.id!,
              reportId: report.id!,
              fsDiv: opposite,
              bsnsYear: actual.year(e),
              reportCode: FinancialReportCode.annual,
              statement: FinancialStatementKind.balanceSheet,
              accountId: 'ifrs-full_Assets',
              accountName: 'sentinel',
              amount: BigInt.from(123),
              sourceId: source.id!,
            ),
          );
          final before = [source.toJson(), report.toJson(), fact.toJson()];
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: e['corpCode'],
              rceptNo: e['receipt'],
              reportName: e['reportName'],
              bsnsYear: actual.year(e),
              reportCode: FinancialReportCode.annual,
              discoveredAt: now,
              attempts: 3,
              consolidatedStatus: div == FsDiv.consolidated
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              separateStatus: div == FsDiv.separate
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              lastError: 'api-noData-annual-public:attempt=1; eligible retry',
            ),
          );
          final client = NotPresentedClient();
          for (var i = 0; i < 3; i++) {
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
              negativeSourceCache: KnownAnnualNotPresentedCache(
                readAsset: (_) async => throw const FileSystemException(
                  'cache unavailable in ordinary-fetch regression',
                ),
              ),
            ).run();
            expect((await IngestJob.db.findById(session, job.id!))!.updated, 0);
            final current = (await DartFiling.db.findById(
              session,
              filing.id!,
            ))!;
            // Existing failed-run policy increments once; the third run is capped.
            expect(current.attempts, i < 2 ? filing.attempts + i + 1 : 5);
            expect(current.lastError, contains('attempt=${i < 2 ? i + 2 : 3}'));
          }
          expect(client.calls, 0);
          expect(client.publicCalls, 2);
          final after = (await DartFiling.db.findById(session, filing.id!))!;
          expect(after.attempts, filing.attempts + 2);
          expect(after.lastError, contains('KnownAnnualSourceNotPresented'));
          expect(after.lastError, contains('attempt=3'));
          expect(
            div == FsDiv.consolidated
                ? after.consolidatedStatus
                : after.separateStatus,
            FilingFetchStatus.failed,
          );
          expect(
            opposite == FsDiv.consolidated
                ? after.consolidatedStatus
                : after.separateStatus,
            FilingFetchStatus.stored,
          );
          expect(await FinancialReport.db.count(session), 1);
          expect(await FinancialFact.db.count(session), 1);
          expect([
            (await Source.db.findById(session, source.id!))!.toJson(),
            (await FinancialReport.db.findById(session, report.id!))!.toJson(),
            (await FinancialFact.db.findById(session, fact.id!))!.toJson(),
          ], before);
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.equals(
              'financial-source-not-presented:${e['receipt']}:${div.name}',
            ),
          );
          expect(audits, hasLength(1));
          expect(audits.single.url, actual.sourceUri(e, e['basis']).toString());
          final payload = jsonDecode(audits.single.title);
          expect(payload['status'], 'failed');
          expect(
            payload['action'],
            'verified-primary-statements-not-presented',
          );
          expect(payload['evidence']['basisNotApplicable'], false);
          expect(payload['evidence']['collectionComplete'], false);
          expect(payload['financialFactsStored'], false);
          expect(
            payload['evidence']['statementSha256'],
            e['sources'][1]['sha256'],
          );
          expect((await ApiCallUsage.db.findFirstRow(session))!.calls, 20000);
        },
      );
    }
  });
}
