import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Animedi actual incomplete status', (builder, endpoints) {
    for (final year in [2022, 2023]) {
      test(
        'actual CFS noData OFS failed $year becomes resolved filing without CFS numbers',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final receipt = year == 2023 ? '20240320000248' : '20230323000586';
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: '01507810',
              name: '애니메디솔루션 주식회사',
              stockCode: '390110',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: company.corpCode,
              rceptNo: receipt,
              reportName: '사업보고서 ($year.12)',
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.failed,
              attempts: 2,
              lastError:
                  'api-noData-annual-public:attempt=3; previous span failure',
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
          final after = (await DartFiling.db.findById(session, filing.id!))!;
          expect(after.consolidatedStatus, FilingFetchStatus.noData);
          expect(after.separateStatus, FilingFetchStatus.stored);
          expect(after.attempts, 2);
          expect(after.lastError, contains('attempt=3;'));
          final reports = await FinancialReport.db.find(session);
          expect(reports.length, 1);
          expect(reports.single.fsDiv, FsDiv.separate);
          final facts = await FinancialFact.db.find(session);
          expect(
            facts.every(
              (x) => x.reportId == reports.single.id && x.accountId == null,
            ),
            true,
          );
          final summary = await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: FsDiv.separate,
          );
          expect(
            summary!.periods.single.lines
                .singleWhere((x) => x.key == 'netIncome')
                .amount,
            BigInt.parse(year == 2023 ? '-4419372266' : '-7014810066'),
          );
          expect((await IngestJob.db.findById(session, job.id!))!.updated, 1);
          expect(
            after.consolidatedStatus == FilingFetchStatus.failed ||
                after.separateStatus == FilingFetchStatus.failed,
            false,
          );
          expect(await ApiCallUsage.db.find(session), isEmpty);
        },
      );
    }
  });
}
