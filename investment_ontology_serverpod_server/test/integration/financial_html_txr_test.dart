import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';

import '../unit/public_financial_html_txr_test.dart' as actual;
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
  }) => actual.fetch(cfs: consolidated);
}

void main() {
  withServerpod('Annual source company/title formats', (builder, endpoints) {
    for (final receipt in ['20250526000504']) {
      test(
        'normal ingest preserves actual printed rows and sources $receipt',
        () async {
          final session = builder.asAdmin.build();
          final corp = '01458161';
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: corp,
              name: '(주)티엑스알로보틱스',
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
              reportName: '사업보고서 (2024.12)',
              bsnsYear: 2024,
              reportCode: FinancialReportCode.annual,
              discoveredAt: DateTime.now().toUtc(),
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
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
          expect(current.separateStatus, FilingFetchStatus.stored);
          expect(current.consolidatedStatus, FilingFetchStatus.noData);
          final audits = await Source.db.find(session);
          expect(audits.any((s) => s.title.contains('- 해당사항이 없습니다.')), isTrue);
          final reports = await FinancialReport.db.find(session);
          expect(reports.length, 1);
          for (final report in reports) {
            expect(report.rceptNo, receipt);
            final source = (await Source.db.findById(
              session,
              report.sourceId,
            ))!;
            expect(source.reference, receipt);
            expect(source.url, contains(receipt));
            final facts = await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(report.id!),
            );
            expect(facts.length, greaterThanOrEqualTo(7));
          }
          final storedFacts = await FinancialFact.db.find(session);
          expect(storedFacts.every((f) => f.accountId == null), isTrue);
          expect(
            storedFacts
                .singleWhere((f) => f.accountName == '매출 (주25,36)')
                .amount,
            BigInt.parse('57227363835'),
          );
          final chosenRevenue = BigInt.parse(
            '57227363835',
          );
          final summary = (await FinancialEndpoint().summary(session, corp))!;
          expect(
            summary.periods.single.lines
                .singleWhere((x) => x.key == 'revenue')
                .amount,
            chosenRevenue,
          );
          final day = DateTime.utc(2026, 10, 2);
          final source = (await Source.db.findById(
            session,
            reports.first.sourceId,
          ))!;
          final security = await Security.db.insertRow(
            session,
            Security(
              isinCode: 'KR$corp',
              shortCode: '123456',
              name: company.name,
              companyId: company.id,
              lastSeenDate: day,
            ),
          );
          await MarketSnapshot.db.insertRow(
            session,
            MarketSnapshot(
              securityId: security.id!,
              baseDate: day,
              marketCap: BigInt.from(1000000000000),
              sourceId: source.id!,
            ),
          );
          await MarketSnapshotDay.db.insertRow(
            session,
            MarketSnapshotDay(baseDate: day, rowCount: 1, fetchedAt: day),
          );
          final screen = await ScreenEndpoint().list(
            session,
            corpCodes: [corp],
          );
          expect(screen.items.single.revenue, chosenRevenue);
          expect(client.calls, 0);
        },
      );
    }
  });
}
