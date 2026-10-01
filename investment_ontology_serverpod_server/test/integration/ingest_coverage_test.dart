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

    test(
      'business-only ledger rows never increase major 28-section coverage',
      () async {
        final before = await endpoints.ingest.coverage(sessionBuilder);
        final bodyOnly = (await Company.db.findFirstRow(
          session,
          where: (t) => t.corpCode.equals('00000002'),
        ))!;
        final statuses = [
          FilingFetchStatus.stored,
          FilingFetchStatus.noData,
          FilingFetchStatus.pending,
          FilingFetchStatus.failed,
        ];
        for (var i = 0; i < statuses.length; i++) {
          final year = 2022 + i;
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '${year}0310000001',
              corpCode: bodyOnly.corpCode,
              companyId: bodyOnly.id,
              reportName: '사업보고서 ($year.12)',
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
              discoveredAt: DateTime.utc(2026),
            ),
          );
          await DartFilingSection.db.insertRow(
            session,
            DartFilingSection(
              filingId: filing.id!,
              companyId: bodyOnly.id!,
              bsnsYear: year,
              yearRank: i,
              section: DartSection.businessContent,
              tier: 2,
              status: statuses[i],
              attempts: statuses[i] == FilingFetchStatus.failed ? 3 : 0,
            ),
          );
        }
        final after = await endpoints.ingest.coverage(sessionBuilder);
        expect(after.sections, before.sections);
        expect(after.sectionsDone, before.sectionsDone);
        expect(after.sectionsFailed, before.sectionsFailed);
        expect(
          after.companiesWithDisclosures,
          before.companiesWithDisclosures,
          reason: '본문만 보유한 기업은 주요정보 보유 기업이 아니다',
        );
        expect(after.prioritySections, before.prioritySections);
        expect(after.prioritySectionsDone, before.prioritySectionsDone);
        expect(
          await DartFilingSection.db.count(session),
          8,
          reason: '원문 장부는 보존한다',
        );
        expect(after.bodyScopeTotal, before.bodyScopeTotal! + 4);
        expect(
          after.bodyScopeStored,
          before.bodyScopeStored,
          reason: '본문 장부 stored는 실제 본문 확보로 부풀리지 않는다',
        );
        expect(after.bodyScopeFailed, before.bodyScopeFailed! + 1);
        expect(after.bodyScopePending, before.bodyScopePending! + 3);
      },
    );

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

    test('재시도 한도에 도달한 빈 본문은 대기가 아닌 실패로 표시한다', () async {
      final filing = (await DartFiling.db.find(
        session,
        orderBy: (t) => t.rceptNo.desc(),
      )).first;
      await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: filing.id!,
          companyId: filing.companyId!,
          bsnsYear: filing.bsnsYear!,
          section: DartSection.businessContent,
          tier: 2,
          status: FilingFetchStatus.noData,
          attempts: 3,
        ),
      );
      final value = await endpoints.ingest.coverage(sessionBuilder);
      expect(value.bodyScopeStored, 0);
      expect(value.bodyScopePending, 0);
      expect(value.bodyScopeFailed, 1);
    });

    for (final basis in [FsDiv.consolidated, FsDiv.separate]) {
      test(
        'actual closing month and original source anchor govern $basis availability',
        () async {
          final company = (await Company.db.findFirstRow(
            session,
            where: (t) => t.corpCode.equals('00000002'),
          ))!;
          final now = DateTime.utc(2026, 1, 1);
          Future<DartFiling> filing(String receipt, String month) =>
              DartFiling.db.insertRow(
                session,
                DartFiling(
                  companyId: company.id,
                  corpCode: company.corpCode,
                  rceptNo: receipt,
                  bsnsYear: 2025,
                  reportCode: FinancialReportCode.annual,
                  reportName: '사업보고서 (2025.$month)',
                  discoveredAt: now,
                  consolidatedStatus: FilingFetchStatus.stored,
                  separateStatus: FilingFetchStatus.stored,
                ),
              );
          Future<Source> source(String receipt) => Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: '실제 공시 원접수',
              reference: receipt,
              url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
              retrievedAt: now,
            ),
          );
          Future<FinancialReport> report(
            String receipt,
            String month,
            Source evidence,
          ) => FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: receipt,
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              fsDiv: basis,
              reportName: '사업보고서 (2025.$month)',
              factCount: 1,
              sourceId: evidence.id!,
              fetchedAt: now,
            ),
          );
          Future<void> fact(FinancialReport r, Source evidence) async {
            await FinancialFact.db.insertRow(
              session,
              FinancialFact(
                reportId: r.id!,
                companyId: company.id!,
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                fsDiv: basis,
                statement: FinancialStatementKind.balanceSheet,
                accountName: '자산총계',
                amount: BigInt.from(100),
                sourceId: evidence.id!,
              ),
            );
          }

          // A June original cannot establish the December target's availability.
          await filing('20250811000001', '06');
          await filing('20260310000002', '12');
          final juneSource = await source('20250811000001');
          final june = await report('20250811000001', '06', juneSource);
          await fact(june, juneSource);
          var coverage = await endpoints.ingest.coverage(sessionBuilder);
          expect(
            coverage.financialStoredFilings,
            1,
            reason: 'June source covers only June, not same-FY December',
          );
          // A fabricated report title cannot change its original receipt's period.
          await FinancialReport.db.updateRow(
            session,
            june.copyWith(reportName: '사업보고서 (2025.12)'),
          );
          coverage = await endpoints.ingest.coverage(sessionBuilder);
          expect(
            coverage.financialStoredFilings,
            0,
            reason: 'Report title matches December but source receipt ledger is June',
          );
          // An earlier December original is valid for its final correction,
          // but neither an empty report nor another source's facts suffice.
          await filing('20260310000001', '12');
          final decemberSource = await source('20260310000001');
          final december = await report('20260310000001', '12', decemberSource);
          expect(
            (await endpoints.ingest.coverage(sessionBuilder))
                .financialStoredFilings,
            0,
            reason:
                'Correct original anchor without actual facts is not stored',
          );
          await fact(december, juneSource);
          expect(
            (await endpoints.ingest.coverage(sessionBuilder))
                .financialStoredFilings,
            0,
            reason: 'Facts must bind the report source, not a different period source',
          );
          await fact(december, decemberSource);
          coverage = await endpoints.ingest.coverage(sessionBuilder);
          expect(
            coverage.financialStoredFilings,
            1,
            reason: 'Actual December original anchor and its source-bound amount cover final December',
          );
        },
      );
    }

    test('층마다 받은 수와 전체 수를 센다', () async {
      final v = await endpoints.ingest.coverage(sessionBuilder);
      expect(v.listedCompanies, 2);
      expect(v.filingsTotal, 1, reason: '같은 기간의 최종 정정 접수번호만 수집 대상이다');
      expect(v.filingsPending, 1);
      expect(v.financialStoredFilings, 0, reason: 'stored 장부만 있고 실제 숫자·출처는 없음');
      expect(v.financialPendingFilings, 1);
      expect(v.financialFailedFilings, 0);
      expect(v.bodyScopeTotal, 1);
      expect(v.bodyScopeStored, 0, reason: '공시 섹션 처리와 실제 본문 저장은 별개');
      expect(v.bodyScopePending, 1);
      expect(v.marketLatestPriceDate, isNull);
      expect(v.marketScopeThrough, isNull);

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
