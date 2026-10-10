import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:test/test.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('shareholder return year', (builder, _) {
    test('latest interim stock and dividend rows remain separate from annual series', () async {
      final session = builder.build();
      addTearDown(session.close);
      final c = await Company.db.insertRow(
        session,
        Company(corpCode: '01526806', name: '삼기에너지솔루션즈'),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '원문',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: c.id!,
          corpCode: c.corpCode,
          rceptNo: '20260814000001',
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          reportName: '반기보고서 (2026.06)',
          consolidatedStatus: FilingFetchStatus.stored,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: DateTime.utc(2026, 8, 14),
        ),
      );
      for (final (year, code, amount) in [
        (2025, FinancialReportCode.annual, 100.0),
        (2026, FinancialReportCode.halfYear, 20.0),
      ]) {
        for (final section in [
          DartSection.dividend,
          DartSection.stockTotal,
          DartSection.treasuryStock,
        ]) {
          final report = await DisclosureReport.db.insertRow(
            session,
            DisclosureReport(
              companyId: c.id!,
              section: section,
              rceptNo: '$year',
              bsnsYear: year,
              reportCode: code,
              sourceId: source.id!,
              rowCount: 1,
              fetchedAt: DateTime.utc(2026),
            ),
          );
          if (section == DartSection.dividend)
            await DividendEntry.db.insertRow(
              session,
              DividendEntry(
                reportId: report.id!,
                companyId: c.id!,
                bsnsYear: year,
                ord: 0,
                item: '주당 현금배당금',
                unit: '원',
                current: amount,
              ),
            );
          if (section == DartSection.stockTotal)
            await DisclosureRow.db.insertRow(
              session,
              DisclosureRow(
                reportId: report.id!,
                ord: 0,
                isTotal: false,
                rowJson: '{"se":"보통주","istc_totqy":"$year"}',
              ),
            );
          if (section == DartSection.treasuryStock)
            await TreasuryStockEntry.db.insertRow(
              session,
              TreasuryStockEntry(
                reportId: report.id!,
                companyId: c.id!,
                bsnsYear: year,
                ord: 0,
                sharesEnd: BigInt.from(year),
                isTotal: true,
              ),
            );
        }
      }
      final annualDividend = (await DisclosureReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(c.id!) &
            t.section.equals(DartSection.dividend) &
            t.bsnsYear.equals(2025),
      )).single;
      final entry = (await DividendEntry.db.find(
        session,
        where: (t) => t.reportId.equals(annualDividend.id!),
      )).single;
      await DividendEntry.db.insertRow(
        session,
        DividendEntry(
          reportId: entry.reportId,
          companyId: entry.companyId,
          bsnsYear: entry.bsnsYear,
          ord: 1,
          item: entry.item,
          unit: entry.unit,
          current: entry.current,
        ),
      );
      for (final (ord, json) in [
        (0, '{"se":"현금배당","thstrm":"100"}'),
        (1, '{"thstrm":"100","se":"현금배당"}'),
        (2, '{"se":"현금배당","thstrm":"200"}'),
      ]) {
        await DisclosureRow.db.insertRow(
          session,
          DisclosureRow(
            reportId: annualDividend.id!,
            ord: ord,
            isTotal: false,
            rowJson: json,
          ),
        );
      }
      final endpoint = DisclosureEndpoint();
      final table = (await endpoint.table(
        session,
        c.corpCode,
        DartSection.dividend,
        bsnsYear: 2025,
      ))!;
      expect(table.rows, hasLength(2));

      final data = (await endpoint.shareholderReturn(session, c.corpCode))!;
      expect(data.dividends.single.bsnsYear, 2025);
      expect(data.dividends.single.current, 100);
      expect(data.interimDividends!.single.current, 20);
      expect(data.interimReportName, '2026년 상반기');
      expect(data.treasury.single.sharesEnd, BigInt.from(2026));
      expect(data.stockTotals.single.issued, BigInt.from(2026));
      expect(data.latestStockTotalStatus, 'stored');
      expect(data.annualEndYear, 2025);
      final old = (await endpoint.shareholderReturn(
        session,
        c.corpCode,
        bsnsYear: 2025,
      ))!;
      expect(old.stockTotalYear, 2025);
      expect(old.interimDividends!.single.current, 20);
    });
    test(
      'requested stock totals use their own year without latest fallback',
      () async {
        final session = builder.build();
        addTearDown(session.close);
        final c = await Company.db.insertRow(
          session,
          Company(corpCode: '00139719', name: '와이지-원'),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: '연도별 주식 수',
            retrievedAt: DateTime.now().toUtc(),
          ),
        );
        for (final year in [2021, 2025]) {
          final r = await DisclosureReport.db.insertRow(
            session,
            DisclosureReport(
              companyId: c.id!,
              section: DartSection.stockTotal,
              rceptNo: '${year}1231000001',
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              rowCount: 1,
              sourceId: source.id!,
              fetchedAt: DateTime.now().toUtc(),
            ),
          );
          await DisclosureRow.db.insertRow(
            session,
            DisclosureRow(
              reportId: r.id!,
              ord: 0,
              isTotal: false,
              rowJson: '{"se":"보통주","istc_totqy":"$year"}',
            ),
          );
        }
        final endpoint = DisclosureEndpoint();
        final old = await endpoint.shareholderReturn(
          session,
          c.corpCode,
          bsnsYear: 2021,
        );
        expect(old!.stockTotalYear, 2021);
        expect(old.stockTotals.single.issued, BigInt.from(2021));
        final latest = await endpoint.shareholderReturn(session, c.corpCode);
        expect(latest!.stockTotalYear, 2025);
        final missing = await endpoint.shareholderReturn(
          session,
          c.corpCode,
          bsnsYear: 2022,
        );
        expect(missing!.stockTotals, isEmpty);
        expect(missing.stockTotalYear, isNull);
      },
    );
  });
}
