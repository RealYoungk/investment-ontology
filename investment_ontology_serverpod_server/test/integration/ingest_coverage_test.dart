import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 수집 현황', (sessionBuilder, endpoints) {
    late Session session;

    setUp(() async {
      session = sessionBuilder.build();
      final now = DateTime.utc(2026, 9, 19);
      final listed = await Company.db.insertRow(
        session,
        Company(corpCode: '00000001', name: '가나', stockCode: '000001'),
      );
      await Company.db.insertRow(
        session,
        Company(corpCode: '00000002', name: '다라', stockCode: '000002'),
      );
      DartFiling filing(String rcept, FilingFetchStatus status) => DartFiling(
        rceptNo: rcept,
        corpCode: listed.corpCode,
        companyId: listed.id,
        reportName: '사업보고서',
        bsnsYear: 2025,
        reportCode: FinancialReportCode.annual,
        consolidatedStatus: status,
        separateStatus: FilingFetchStatus.stored,
        discoveredAt: now,
      );
      final done = await DartFiling.db.insertRow(
        session,
        filing('1', FilingFetchStatus.stored),
      );
      await DartFiling.db.insertRow(
        session,
        filing('2', FilingFetchStatus.pending),
      );
      for (final (section, tier, rank, status) in [
        (DartSection.values[0], 0, 0, FilingFetchStatus.stored),
        (DartSection.values[1], 0, 0, FilingFetchStatus.pending),
        (DartSection.values[2], 1, 0, FilingFetchStatus.noData),
        (DartSection.values[3], 0, 1, FilingFetchStatus.failed),
      ]) {
        await DartFilingSection.db.insertRow(
          session,
          DartFilingSection(
            filingId: done.id!,
            companyId: listed.id!,
            bsnsYear: 2025,
            yearRank: rank,
            section: section,
            tier: tier,
            status: status,
          ),
        );
      }
    });

    test('층마다 받은 수와 전체 수를 센다', () async {
      final v = await endpoints.ingest.coverage(sessionBuilder);
      expect(v.listedCompanies, 2);
      expect(v.filingsTotal, 2);
      expect(v.filingsPending, 1);
      expect(v.prioritySections, 2);
      expect(v.prioritySectionsDone, 1);
      expect(v.sections, 4);
      expect(v.sectionsDone, 2);
      expect(v.sectionsFailed, 1);
      expect(v.companiesWithDisclosures, 1);
      expect(v.dartDailyLimit, 20000);
    });
  });
}
