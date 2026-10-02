import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';

import '../unit/public_financial_two_cfs_absence_test.dart' as actual;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class SourceClient extends DartClient {
  SourceClient()
    : super(
        'synthetic',
        httpClient: MockClient(
          (r) async => throw StateError('No external/API request'),
        ),
      );
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
  }) => actual.fetch(receipt, cfs: consolidated);
}

void main() {
  withServerpod('Annual source company/title formats', (builder, endpoints) {
    for (final receipt in ['20250318000596', '20260318001043']) {
      test(
        'normal ingest preserves actual printed rows and sources $receipt',
        () async {
          final session = builder.asAdmin.build();
          final corp = actual.proof(receipt)['corpCode'] as String;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: corp,
              name: actual.proof(receipt)['name'],
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
              reportName: actual.proof(receipt)['reportName'],
              bsnsYear: actual.proof(receipt)['bsnsYear'],
              reportCode: FinancialReportCode.annual,
              discoveredAt: DateTime.now().toUtc(),
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              lastError: 'api-noData-annual-public:attempt=1; public annual source verification failed',
            ),
          );
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: DateTime.now().toUtc(),
            ),
          );
          final client = SourceClient();
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            corpCode: corp,
            callInterval: Duration.zero,
          ).run();
          final current = (await DartFiling.db.findById(session, filing.id!))!;
          expect(current.separateStatus, FilingFetchStatus.failed);
          expect(current.consolidatedStatus, FilingFetchStatus.noData);
          final audits = await Source.db.find(session);
          final audit = audits.singleWhere(
            (x) =>
                x.reference ==
                'financial-public-basis-not-applicable:$receipt:consolidated',
          );
          expect(audit.kind, SourceKind.dartReport);
          expect(audit.url, actual.source(receipt, 'cfs').toString());
          expect(audit.title, contains(receipt));
          expect(audit.title, contains(corp));
          expect(
            audit.title,
            contains('official-exact-annual-consolidated-not-applicable'),
          );
          expect(
            audit.title,
            contains(actual.source(receipt, 'cover').toString()),
          );
          expect(await FinancialReport.db.count(session), 0);
          expect(await FinancialFact.db.count(session), 0);
          expect(client.calls, 0);
        },
      );
    }
  });
}
