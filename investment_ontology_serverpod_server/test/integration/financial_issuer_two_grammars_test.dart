import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

import '../unit/public_issuer_two_grammars_test.dart' as actual;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class SourceClient extends DartClient {
  final String target;
  SourceClient(this.target)
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
  }) async {
    if (consolidated) {
      throw const FormatException('CFS not verified by this fixture');
    }
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      issuerProof: actual.evidence(receipt),
      coverHtml: actual.raw(receipt, 'cover'),
      coverSource: actual.uri(receipt, 'cover'),
      statementHtml: actual.raw(receipt, 'ofs'),
      statementSource: actual.uri(receipt, 'ofs'),
      periodStart: DateTime.utc(2025, 1, 1),
      periodEnd: DateTime.utc(2025, 12, 31),
      rows: PublicFinancialHtml.parseStandardAnnual(
        coverHtml: actual.raw(receipt, 'cover'),
        statementHtml: actual.raw(receipt, 'ofs'),
        coverSource: actual.uri(receipt, 'cover'),
        statementSource: actual.uri(receipt, 'ofs'),
        receipt: receipt,
        corpCode: corpCode,
        companyName: companyName,
        periodStart: DateTime.utc(2025),
        periodEnd: periodEnd,
        consolidated: false,
        issuerProof: actual.evidence(receipt),
      ),
    );
  }
}

void main() {
  withServerpod('Annual source company/title formats', (builder, endpoints) {
    for (final receipt in ['20260330001331', '20260319001111']) {
      test(
        'normal ingest preserves actual printed rows and sources $receipt',
        () async {
          final session = builder.asAdmin.build();
          final solumix = receipt == '20260330001331';
          final corp = solumix ? '01118643' : '01188730';
          final revenue = solumix ? '225000000' : '80265105377';
          final cfo = solumix ? '5727142089' : '-143087632260';
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: corp,
              name: solumix ? '(주)솔루믹스' : 'SK시그넷(주)',
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
              reportName: '사업보고서 (2025.12)',
              bsnsYear: 2025,
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
          final client = SourceClient(receipt);
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
          expect(current.consolidatedStatus, FilingFetchStatus.failed);
          final audits = await Source.db.find(session);
          expect(
            audits.any(
              (s) =>
                  s.title.contains(
                    'declaredLegalName',
                  ) &&
                  s.title.contains('2025-01-01') &&
                  s.title.contains('2025-12-31'),
            ),
            isTrue,
          );
          final reports = await FinancialReport.db.find(session);
          expect(reports.length, 1);
          for (final report in reports) {
            expect(report.rceptNo, receipt);
            final source = (await Source.db.findById(
              session,
              report.sourceId,
            ))!;
            expect(source.reference, receipt);
            expect(source.kind, SourceKind.dartReport);
            expect(source.url, actual.uri(receipt, 'ofs').toString());
            expect(source.url, contains(receipt));
            final facts = await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(report.id!),
            );
            expect(facts.length, 7);
            expect(facts.every((f) => f.sourceId == source.id), isTrue);
          }
          final storedFacts = await FinancialFact.db.find(session);
          expect(storedFacts.every((f) => f.accountId == null), isTrue);
          expect(
            storedFacts
                .singleWhere(
                  (f) =>
                      f.accountName == (solumix ? 'I. 매출액' : 'Ⅰ. 매출액(주석19,21)'),
                )
                .amount,
            BigInt.parse(revenue),
          );
          final chosenRevenue = BigInt.parse(
            revenue,
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
          expect(
            summary.periods.single.lines
                .singleWhere((v) => v.key == 'netIncome')
                .amount,
            BigInt.parse(solumix ? '-1846578034' : '-49397330798'),
          );
          expect(
            summary.periods.single.lines
                .singleWhere((v) => v.key == 'equity')
                .amount,
            BigInt.parse(solumix ? '13324304913' : '26900536152'),
          );
          expect(client.calls, 0);
          expect(
            summary.periods.single.lines
                .singleWhere((v) => v.key == 'operatingCashFlow')
                .amount,
            BigInt.parse(cfo),
          );
          final sqlCfo = await session.db.unsafeQuery(
            "SELECT amount FROM financial_fact f WHERE f.\"reportId\" = ${reports.single.id} AND ${FinancialAccounts.resolvedIdSql('f')} = 'ifrs-full_CashFlowsFromUsedInOperatingActivities'",
          );
          expect(sqlCfo.single.first.toString(), cfo);
        },
      );
    }
  });
}
