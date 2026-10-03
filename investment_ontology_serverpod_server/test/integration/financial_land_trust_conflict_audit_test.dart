import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_conflict.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/land_trust_own_source_conflicts.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

final conflictCases = [
  for (final p in LandTrustOwnSourceConflicts.profiles.values)
    {
      ...Map<String, dynamic>.from(p as Map),
      'basis': (p['basis'] as String).toLowerCase(),
      'reportName': '사업보고서 (${p['year']}.12)',
      'name': '한국토지신탁',
      'sources': [
        {'sha256': p['coverSHA']},
        {'sha256': p['sourceSHA']},
      ],
    },
];
int year(Map e) => e['year'] as int;
Uri sourceUri(Map e, String label) =>
    Uri.parse((label == 'cover' ? e['coverURI'] : e['sourceURI']) as String);
Future<PublicFinancialHtmlSource> fetchConflict(
  Map e, {
  String? corp,
  bool? cfs,
}) async {
  KnownAnnualSourceConflicts.verify(
    receipt: e['receipt'],
    corpCode: corp ?? e['corpCode'],
    consolidated: cfs ?? e['basis'] == 'cfs',
    start: DateTime.utc(year(e)),
    end: DateTime.utc(year(e), 12, 31),
    coverSource: sourceUri(e, 'cover'),
    statementSource: sourceUri(e, e['basis']),
    coverHtml: File(
      'test/fixtures/financial_html/landtrust-conflicts/${e['receipt']}/cover.html',
    ).readAsStringSync(),
    statementHtml: File(
      'test/fixtures/financial_html/landtrust-conflicts/${e['receipt']}/${e['basis']}.html',
    ).readAsStringSync(),
  );
  throw StateError(
    'Exact source conflict must reject before any numerical rows',
  );
}

class ConflictClient extends SourceClient {
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
    return fetchConflict(
      conflictCases.singleWhere(
        (e) =>
            e['receipt'] == receipt &&
            e['basis'] == (consolidated ? 'cfs' : 'ofs'),
      ),
      corp: corpCode,
      cfs: consolidated,
    );
  }
}

void main() {
  withServerpod('LandTrust exact ordinary conflict audit', (
    builder,
    endpoints,
  ) {
    for (final e in conflictCases) {
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
              url: sourceUri(e, 'cover').toString(),
              title: 'immutable opposite',
              retrievedAt: now,
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              fsDiv: opposite,
              bsnsYear: year(e),
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
              bsnsYear: year(e),
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
              bsnsYear: year(e),
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
          final client = ConflictClient();
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
          expect(after.lastError, contains('KnownAnnualSourceConflict'));
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
              'financial-source-conflict:${e['receipt']}:${div.name}',
            ),
          );
          expect(audits, hasLength(1));
          expect(audits.single.url, sourceUri(e, e['basis']).toString());
          final payload = jsonDecode(audits.single.title);
          expect(payload['status'], 'failed');
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
