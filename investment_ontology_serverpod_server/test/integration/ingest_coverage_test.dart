import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'auth_test_sessions.dart';

void main() {
  withServerpod('Given 수집 현황', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asAdmin;
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

    test('과거 중간보고서와 5개년 밖 대기는 장부에 남기고 현재 수집 현황에서 제외한다', () async {
      final company = (await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals('00000001'),
      ))!;
      Future<DartFiling> add(
        String receipt,
        int year,
        FinancialReportCode code,
      ) => DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: company.id,
          corpCode: company.corpCode,
          rceptNo: receipt,
          bsnsYear: year,
          reportCode: code,
          reportName: '정기보고서',
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.utc(2026),
        ),
      );
      final historical = await add(
        '20241114000001',
        2024,
        FinancialReportCode.q3,
      );
      final beyondFive = await add(
        '20200310000001',
        2019,
        FinancialReportCode.annual,
      );
      final q1 = await add('20260514000001', 2026, FinancialReportCode.q1);
      await add('20260814000001', 2026, FinancialReportCode.halfYear);
      final coverage = await endpoints.ingest.coverage(sessionBuilder);
      expect(coverage.filingsTotal, 2, reason: '최종 FY2025 연간 + 최신 FY2026 반기');
      expect(coverage.filingsPending, 2);
      expect(
        await DartFiling.db.count(session),
        6,
        reason: '과거 공시 장부는 삭제하지 않는다',
      );
      for (final filing in [historical, beyondFive, q1]) {
        expect(
          (await DartFiling.db.findById(
            session,
            filing.id!,
          ))!.consolidatedStatus,
          FilingFetchStatus.pending,
          reason: '범위 밖 자료를 수집 완료로 바꾸지 않는다',
        );
      }
    });

    test('층마다 받은 수와 전체 수를 센다', () async {
      final v = await endpoints.ingest.coverage(sessionBuilder);
      expect(v.listedCompanies, 2);
      expect(v.filingsTotal, 1, reason: '같은 기간의 최종 정정 접수번호만 수집 대상이다');
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
