import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Actual failed basis completion', (builder, endpoints) {
    test(
      'six actual filings resolve both bases within normal cache budget',
      () async {
        final session = builder.asAdmin.build();
        final now = DateTime.utc(2026, 10, 2);
        final usage = await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-02',
            calls: 20000,
          ),
        );
        final beforeUsage = usage.toJson();
        final cases = [
          ('20250328001780', '01563667', '(주)더즌', 2024, false),
          ('20250321001825', '00990396', '(주)레드우즈', 2024, false),
          ('20230320000571', '01267958', '주식회사 프로티아', 2022, true),
          ('20230317000589', '01113499', '(주)아이티센피엔에스', 2022, true),
          ('20240320000248', '01507810', '애니메디솔루션 주식회사', 2023, true),
          ('20230323000586', '01507810', '애니메디솔루션 주식회사', 2022, true),
        ];
        final companies = <String, Company>{};
        final filings = <DartFiling>[];
        for (final (receipt, corp, name, year, _) in cases) {
          companies[corp] ??= await Company.db.insertRow(
            session,
            Company(
              corpCode: corp,
              name: name,
              stockCode: '${companies.length + 100000}',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          filings.add(
            await DartFiling.db.insertRow(
              session,
              DartFiling(
                companyId: companies[corp]!.id,
                corpCode: corp,
                rceptNo: receipt,
                reportName: '사업보고서 ($year.12)',
                bsnsYear: year,
                reportCode: FinancialReportCode.annual,
                discoveredAt: now,
                consolidatedStatus: corp == '01507810'
                    ? FilingFetchStatus.noData
                    : FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.failed,
                attempts: 2,
                lastError: 'api-noData-annual-public:attempt=3; previous original source failure',
              ),
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
        final client = SourceClient();
        await FinancialFactsSync(
          session,
          client,
          job.id!,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
        expect(client.calls, 0);
        expect(
          (await ApiCallUsage.db.findById(session, usage.id!))!.toJson(),
          beforeUsage,
        );
        final reports = await FinancialReport.db.find(session);
        expect(reports.length, 8);
        for (var i = 0; i < filings.length; i++) {
          final f = (await DartFiling.db.findById(session, filings[i].id!))!;
          expect(f.separateStatus, FilingFetchStatus.stored, reason: f.rceptNo);
          expect(
            f.consolidatedStatus,
            cases[i].$5 ? FilingFetchStatus.noData : FilingFetchStatus.stored,
            reason: f.rceptNo,
          );
          expect(f.attempts, 2);
          final bases = reports
              .where((r) => r.rceptNo == f.rceptNo)
              .map((r) => r.fsDiv)
              .toSet();
          expect(
            bases,
            cases[i].$5 ? {FsDiv.separate} : FsDiv.values.toSet(),
            reason: f.rceptNo,
          );
        }
        expect(
          (await IngestJob.db.findById(session, job.id!))!.status,
          IngestStatus.succeeded,
        );
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });
}
