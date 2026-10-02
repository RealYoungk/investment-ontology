import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';

import '../unit/public_financial_html_two_exact_none_test.dart' as actual;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class SourceClient extends DartClient {
  SourceClient(this.index)
    : super(
        'synthetic',
        httpClient: MockClient(
          (r) async => throw StateError('No external/API request'),
        ),
      );
  final int index;
  @override
  Future<List<Map<String, dynamic>>?> fetchFinancialStatements({
    required String corpCode,
    required int bsnsYear,
    required String reportCode,
    required String fsDiv,
  }) async => throw StateError('Do not repeat API');
  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async => throw const FormatException('Fixture tests HTML only');
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
    if (!consolidated) throw StateError('Existing OFS must not fetch');
    return actual.actual(index);
  }
}

void main() {
  withServerpod('Annual source company/title formats', (builder, endpoints) {
    for (var index = 0; index < actual.cases.length * 2; index++) {
      final i = index % actual.cases.length;
      final publicAttempt = index < actual.cases.length ? 2 : 3;
      final receipt = actual.cases[i].$1;
      test(
        'normal ingest preserves actual printed rows and sources $receipt public$publicAttempt',
        () async {
          final session = builder.asAdmin.build();
          final corp = actual.cases[i].$2;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: corp,
              name: actual.cases[i].$3,
              stockCode: '123456',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: corp,
              rceptNo: receipt,
              reportName: '사업보고서 (2022.12)',
              bsnsYear: 2022,
              reportCode: FinancialReportCode.annual,
              discoveredAt: DateTime.now().toUtc(),
              attempts: 3,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.stored,
              lastError:
                  'api-noData-annual-public:attempt=$publicAttempt; public annual source verification failed',
            ),
          );
          final oldSource = await Source.db.insertRow(
            session,
            Source(
              retrievedAt: DateTime.utc(2026),
              kind: SourceKind.dartReport,
              title: 'Existing OFS source must stay',
              reference: receipt,
              url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
            ),
          );
          final oldReport = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: receipt,
              fsDiv: FsDiv.separate,
              bsnsYear: 2022,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (2022.12)',
              factCount: 1,
              sourceId: oldSource.id!,
              fetchedAt: DateTime.utc(2026),
            ),
          );
          final oldFact = await FinancialFact.db.insertRow(
            session,
            FinancialFact(
              reportId: oldReport.id!,
              companyId: company.id!,
              bsnsYear: 2022,
              reportCode: FinancialReportCode.annual,
              fsDiv: FsDiv.separate,
              statement: FinancialStatementKind.balanceSheet,
              accountId: 'ifrs-full_Assets',
              accountName: '자산총계',
              amount: BigInt.from(123),
              priorAmount: BigInt.from(100),
              sourceId: oldSource.id!,
            ),
          );
          final originalFact = oldFact.toJson(),
              originalReport = oldReport.toJson(),
              originalSource = oldSource.toJson();
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: DateTime.now().toUtc(),
            ),
          );
          final client = SourceClient(i);
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            corpCode: corp,
            callInterval: Duration.zero,
          ).run();
          final current = (await DartFiling.db.findById(session, filing.id!))!;
          expect(current.separateStatus, FilingFetchStatus.stored);
          expect(current.consolidatedStatus, FilingFetchStatus.noData);
          final audits = await Source.db.find(session);
          final audit = audits.singleWhere(
            (x) =>
                x.reference ==
                'financial-public-basis-not-applicable:$receipt:consolidated',
          );
          expect(audit.kind, SourceKind.dartReport);
          expect(audit.url, contains('rcpNo=$receipt'));
          expect(audit.title, contains(actual.cases[i].$6));
          expect(audit.title, contains(receipt));
          expect(audit.title, contains(corp));
          expect(
            audit.title,
            contains('official-exact-annual-consolidated-not-applicable'),
          );
          expect(
            audit.title,
            contains('rcpNo=$receipt'),
          );
          expect(await FinancialReport.db.count(session), 1);
          expect(
            (await FinancialReport.db.findById(
              session,
              oldReport.id!,
            ))!.toJson(),
            originalReport,
          );
          expect(
            (await FinancialFact.db.findById(session, oldFact.id!))!.toJson(),
            originalFact,
          );
          expect(
            (await Source.db.findById(session, oldSource.id!))!.toJson(),
            originalSource,
          );
          expect(await FinancialFact.db.count(session), 1);
          expect(client.calls, 0);
          expect((await IngestJob.db.findById(session, job.id!))!.updated, 0);
          expect(current.attempts, 3);
        },
      );
    }
  });
}
