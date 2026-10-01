import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_revision.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given 재무·시세 데이터', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asReader;
    late Session session;
    late Company samsung;
    late Company hynix;
    late Source source;

    Future<Company> company(
      String corpCode,
      String name,
      Market market,
      String industryCode,
      String jurirNo,
    ) {
      final cls = KsicSeeder.classify(industryCode);
      return Company.db.insertRow(
        session,
        Company(
          corpCode: corpCode,
          name: name,
          market: market,
          industryCode: industryCode,
          sectionCode: cls.section,
          divisionCode: cls.division,
          jurirNo: jurirNo,
        ),
      );
    }

    Future<FinancialReport> report(
      Company c,
      FsDiv div,
      int year,
      FinancialReportCode code,
      String rceptNo,
      Map<String, int> amounts, {
      int? supersededById,
    }) async {
      final month = switch (code) {
        FinancialReportCode.annual => '12',
        FinancialReportCode.q3 => '09',
        FinancialReportCode.halfYear => '06',
        FinancialReportCode.q1 => '03',
      };
      final reportName = '정기보고서 ($year.$month)';
      final financialSource = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'bound test',
          reference: rceptNo,
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      if (await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(rceptNo),
          ) ==
          null) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: rceptNo,
            corpCode: c.corpCode,
            companyId: c.id,
            reportName: reportName,
            bsnsYear: year,
            reportCode: code,
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.stored,
            discoveredAt: DateTime.now().toUtc(),
          ),
        );
      }

      final r = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: c.id!,
          rceptNo: rceptNo,
          fsDiv: div,
          bsnsYear: year,
          reportCode: code,
          reportName: reportName,
          factCount: amounts.length,
          sourceId: financialSource.id!,
          supersededById: supersededById,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      await FinancialFact.db.insert(session, [
        for (final e in amounts.entries)
          FinancialFact(
            reportId: r.id!,
            companyId: c.id!,
            bsnsYear: year,
            reportCode: code,
            fsDiv: div,
            statement: e.key == 'ifrs-full_Assets'
                ? FinancialStatementKind.balanceSheet
                : FinancialStatementKind.incomeStatement,
            accountId: e.key,
            accountName: e.key,
            periodName: '제 $year 기',
            amount: BigInt.from(e.value),
            sourceId: financialSource.id!,
          ),
      ]);
      return r;
    }

    Future<void> quote(
      Company? c,
      String isin,
      String code,
      int cap, {
      Market market = Market.kospi,
    }) async {
      final s = await Security.db.insertRow(
        session,
        Security(
          isinCode: isin,
          shortCode: code,
          name: code,
          market: market,
          companyId: c?.id,
          lastSeenDate: DateTime.utc(2026, 9, 16),
        ),
      );
      for (final (date, factor) in [
        (DateTime.utc(2026, 9, 15), 1),
        (DateTime.utc(2026, 9, 16), 2),
      ]) {
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: s.id!,
            baseDate: date,
            closePrice: BigInt.from(1000),
            marketCap: BigInt.from(cap * factor),
            sourceId: source.id!,
          ),
        );
      }
    }

    setUp(() async {
      session = sessionBuilder.build();
      await KsicSeeder.seed(session);
      await KsicRevision.invalidate(session);
      source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.manual,
          title: 'test',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      samsung = await company(
        '00126380',
        '삼성전자',
        Market.kospi,
        '264',
        '1301110006246',
      );
      hynix = await company(
        '00164779',
        'SK하이닉스',
        Market.kospi,
        '261',
        '1344110001387',
      );
      final kakao = await company(
        '00258801',
        '카카오',
        Market.kospi,
        '631',
        '1101110000001',
      );

      final old = await report(
        samsung,
        FsDiv.consolidated,
        2025,
        FinancialReportCode.annual,
        '20260310000001',
        {
          'ifrs-full_Revenue': 100,
          'dart_OperatingIncomeLoss': 10,
        },
      );
      final corrected = await report(
        samsung,
        FsDiv.consolidated,
        2025,
        FinancialReportCode.annual,
        '20260630000002',
        {
          'ifrs-full_Revenue': 101,
          'dart_OperatingIncomeLoss': 11,
          'ifrs-full_Assets': 500,
          'ifrs-full_CostOfSales': 70,
        },
      );
      await FinancialReport.db.updateRow(
        session,
        old.copyWith(supersededById: corrected.id),
      );
      await report(
        samsung,
        FsDiv.consolidated,
        2026,
        FinancialReportCode.halfYear,
        '20260814000003',
        {
          'ifrs-full_Revenue': 60,
        },
      );
      await report(
        samsung,
        FsDiv.consolidated,
        2026,
        FinancialReportCode.q1,
        '20260515000004',
        {
          'ifrs-full_Revenue': 30,
        },
      );
      await report(
        samsung,
        FsDiv.separate,
        2025,
        FinancialReportCode.annual,
        '20260310000001',
        {
          'ifrs-full_Revenue': 80,
        },
      );

      await quote(samsung, 'KR7005930003', '005930', 400);
      await quote(samsung, 'KR7005931001', '005935', 40);
      await quote(hynix, 'KR7000660001', '000660', 100);
      await quote(kakao, 'KR7035720002', '035720', 20);
      await quote(null, 'KR7999999999', '999999', 7);
      for (final date in [
        DateTime.utc(2026, 9, 15),
        DateTime.utc(2026, 9, 16),
      ]) {
        await MarketSnapshotDay.db.insertRow(
          session,
          MarketSnapshotDay(
            baseDate: date,
            rowCount: 5,
            sourceId: source.id,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
      }
    });

    test('summary: 연결 우선, 현재 보고서만 기간 순서로, 핵심 계정만', () async {
      final result = (await endpoints.financial.summary(
        sessionBuilder,
        '00126380',
      ))!;

      expect(result.fsDiv, FsDiv.consolidated);
      expect(result.availableFsDivs, [FsDiv.consolidated, FsDiv.separate]);
      expect(
        result.periods.map((p) => (p.bsnsYear, p.reportCode)),
        [
          (2025, FinancialReportCode.annual),
          (2026, FinancialReportCode.q1),
          (2026, FinancialReportCode.halfYear),
        ],
      );
      final annual = result.periods.first;
      expect(annual.rceptNo, '20260630000002');
      expect(annual.supersededCount, 1);
      expect(
        {for (final l in annual.lines) l.key: l.amount},
        {
          'revenue': BigInt.from(101),
          'operatingIncome': BigInt.from(11),
          'assets': BigInt.from(500),
        },
      );

      final market = result.market!;
      expect(market.baseDate, DateTime.utc(2026, 9, 16));
      expect(market.marketCap, BigInt.from(880), reason: '보통주 800 + 우선주 80');
      expect(market.securities, hasLength(2));
    });

    test('summary: 별도를 고르면 별도', () async {
      final result = (await endpoints.financial.summary(
        sessionBuilder,
        '00126380',
        fsDiv: FsDiv.separate,
      ))!;
      expect(result.periods.single.lines.single.amount, BigInt.from(80));
    });

    test('report: 모든 사실과 정정 이력', () async {
      final summary = (await endpoints.financial.summary(
        sessionBuilder,
        '00126380',
      ))!;
      final detail = (await endpoints.financial.report(
        sessionBuilder,
        summary.periods.first.reportId,
      ))!;

      expect(detail.facts, hasLength(4));
      expect(detail.history.map((r) => r.rceptNo), [
        '20260310000001',
        '20260630000002',
      ]);
    });

    test('companyCapHistory: 공개 읽기·월말 합산·원천·없는 기업', () async {
      final rows = await endpoints.market.companyCapHistory(
        anonymous,
        samsung.corpCode,
        years: 5,
      );
      expect(rows, hasLength(1));
      expect(rows.single.baseDate, DateTime.utc(2026, 9, 16));
      expect(rows.single.marketCap, BigInt.from(880));
      expect(rows.single.securities, hasLength(2));
      expect(rows.single.source?.id, source.id);
      expect(
        await endpoints.market.companyCapHistory(
          anonymous,
          'missing',
          years: 5,
        ),
        isEmpty,
      );
    });

    test('industryTreemap: 대분류 → 그 안 기업, 기업에 안 이어진 종목은 따로', () async {
      final map = await endpoints.market.industryTreemap(sessionBuilder);

      expect(map.baseDate, DateTime.utc(2026, 9, 16));
      expect(map.total, BigInt.from(880 + 200 + 40));
      expect(map.unlinkedSecurityCount, 1);
      expect(map.unlinkedMarketCap, BigInt.from(14));
      final c = map.nodes.first;
      expect(c.code, 'C');
      expect(c.marketCap, BigInt.from(1080));
      expect(c.companyCount, 2);
      // 첫 화면에서 이름을 보여 주도록 대분류 아래는 바로 기업 (시가총액 순).
      expect(c.children.map((n) => (n.name, n.marketCap)), [
        ('삼성전자', BigInt.from(880)),
        ('SK하이닉스', BigInt.from(200)),
      ]);
      expect(map.nodes.last.code, 'J');
    });

    test('industryTreemap: 대분류 안에서는 중분류 → 기업', () async {
      final map = await endpoints.market.industryTreemap(
        sessionBuilder,
        sectionCode: 'C',
      );

      expect(map.sectionName, isNotNull);
      expect(map.total, BigInt.from(1080));
      final division = map.nodes.single;
      expect(division.children.map((n) => (n.name, n.marketCap)), [
        ('삼성전자', BigInt.from(880)),
        ('SK하이닉스', BigInt.from(200)),
      ]);
    });
  });
}
