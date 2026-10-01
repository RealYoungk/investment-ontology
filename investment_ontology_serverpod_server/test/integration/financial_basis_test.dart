import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/screen_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Financial basis edge cases', (builder, endpoints) {
    late Session session;
    late Company company;
    late Source source;
    var receipt = 0;
    const revenue = 'ifrs-full_Revenue';
    const net = 'ifrs-full_ProfitLoss';
    const assets = 'ifrs-full_Assets';
    const capex =
        'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities';
    const cash = 'ifrs-full_CashFlowsFromUsedInOperatingActivities';

    Future<FinancialReport> report(
      FsDiv div,
      int year,
      FinancialReportCode code,
      Map<String, int> values, {
      bool superseded = false,
      bool details = false,
    }) async {
      final r = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: company.id!,
          fsDiv: div,
          bsnsYear: year,
          reportCode: code,
          rceptNo: '${++receipt}'.padLeft(14, '0'),
          reportName: '$year ${code.name}',
          sourceId: source.id!,
          factCount: values.length,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      await FinancialFact.db.insert(session, [
        for (final e in values.entries)
          FinancialFact(
            companyId: company.id!,
            reportId: r.id!,
            fsDiv: div,
            bsnsYear: year,
            reportCode: code,
            statement: e.key == assets
                ? FinancialStatementKind.balanceSheet
                : e.key == cash || e.key == capex
                ? FinancialStatementKind.cashFlow
                : FinancialStatementKind.incomeStatement,
            accountId: e.key,
            accountName: e.key,
            accountDetail: details ? 'segment' : null,
            amount: BigInt.from(e.value),
            cumulativeAmount: BigInt.from(e.value),
            sourceId: source.id!,
          ),
      ]);
      if (superseded) {
        r.supersededById = r.id;
        await FinancialReport.db.updateRow(session, r);
      }
      return r;
    }

    Future<CompanyFinancials> summary({FsDiv? div}) async =>
        (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: div,
        ))!;

    setUp(() async {
      session = builder.build();
      source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartApi,
          title: 'test',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      company = await Company.db.insertRow(
        session,
        Company(corpCode: 'EDGE0001', name: 'edge', market: Market.kosdaq),
      );
      ScreenEndpoint.clearCache();
      ScreenEndpoint.serveStaleWhileRefreshing = false;
    });
    tearDown(() async {
      await session.close();
      ScreenEndpoint.clearCache();
      ScreenEndpoint.serveStaleWhileRefreshing = true;
    });

    test('IPO comparison columns supply TTM, with own-period precedence', () async {
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        revenue: 133,
        cash: -100,
        capex: -20,
      });
      final r = await report(
        FsDiv.consolidated,
        2026,
        FinancialReportCode.halfYear,
        {revenue: 120, cash: -30, capex: -10},
      );
      for (final f in await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(r.id!),
      )) {
        if (f.accountId == revenue) {
          f.priorCumulativeAmount = BigInt.from(48);
          f.priorQuarterAmount = BigInt.from(
            19,
          ); // 3 months, never use as cumulative
        } else {
          f.priorQuarterAmount = BigInt.from(f.accountId == cash ? -40 : 5);
        }
        await FinancialFact.db.updateRow(session, f);
      }
      final rows = await session.db.unsafeQuery(
        'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT acc,v FROM ttm',
      );
      final values = {for (final r in rows) '${r[0]}': num.parse('${r[1]}')};
      expect(values[revenue], 205);
      expect(values[cash], -90);
      expect(values[capex], 25);
      final d = await summary();
      expect(
        d.periods.last.lines
            .firstWhere((l) => l.key == 'revenue')
            .priorSameCumulativeAmount,
        BigInt.from(48),
      );
      expect(d.periods.length, 2);
      await report(FsDiv.consolidated, 2025, FinancialReportCode.halfYear, {
        revenue: 50,
      });
      final own = await session.db.unsafeQuery(
        "WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT v FROM ttm WHERE acc='$revenue'",
      );
      expect(num.parse('${own.single[0]}'), 203);
    });

    test('inconsistent owners comparison is blocked by both SQL and summary', () async {
      const owners = 'ifrs-full_ProfitLossAttributableToOwnersOfParent';
      const minority =
          'ifrs-full_ProfitLossAttributableToNoncontrollingInterests';
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        owners: -2808000,
        net: -2808000,
      });
      final r = await report(
        FsDiv.consolidated,
        2026,
        FinancialReportCode.halfYear,
        {owners: -2226000, net: -2226000, minority: 0},
      );
      for (final f in await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(r.id!),
      )) {
        f.priorCumulativeAmount = BigInt.from(
          f.accountId == net ? -2716000 : 0,
        );
        await FinancialFact.db.updateRow(session, f);
      }
      final rows = await session.db.unsafeQuery(
        "WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT v FROM ttm WHERE acc='$owners'",
      );
      expect(rows.single[0], isNull);
      final d = await summary();
      expect(
        d.periods.last.lines
            .firstWhere((l) => l.key == 'netIncomeOwners')
            .priorSameUnavailableReason,
        contains('합계 불일치'),
      );
    });

    test('annual TTM and basis currency use the current filing despite historical currency changes', () async {
      final old = await report(
        FsDiv.separate,
        2025,
        FinancialReportCode.annual,
        {revenue: 100},
      );
      for (final f in await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(old.id!),
      )) {
        f.currency = 'USD';
        await FinancialFact.db.updateRow(session, f);
      }
      await report(FsDiv.separate, 2026, FinancialReportCode.annual, {
        revenue: 200,
      });
      final rows = await session.db.unsafeQuery(
        "WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT t.v,b.currency FROM ttm t JOIN basis_currency b ON b.id=t.id AND b.fs=t.fs WHERE t.acc='$revenue'",
      );
      expect(num.parse('${rows.single[0]}'), 200);
      expect(rows.single[1], 'KRW');
    });

    test('TTM capex normalizes filing signs consistently with the header', () async {
      await report(FsDiv.separate, 2025, FinancialReportCode.halfYear, {
        capex: 30,
      });
      await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
        capex: -100,
      });
      await report(FsDiv.separate, 2026, FinancialReportCode.halfYear, {
        capex: 40,
      });
      final rows = await session.db.unsafeQuery(
        "WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT v FROM ttm WHERE acc='$capex'",
      );
      expect(num.parse('${rows.single[0]}'), 110);
    });

    test('unidentified exact totals agree between summary and SQL; duplicates fail closed', () async {
      final r = await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
        assets: 500000000,
      });
      final unknown = await FinancialFact.db.insertRow(
        session,
        FinancialFact(
          companyId: company.id!,
          reportId: r.id!,
          fsDiv: FsDiv.separate,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          statement: FinancialStatementKind.comprehensiveIncome,
          accountName: '당기순이익(손실)',
          amount: BigInt.from(2399315356),
          sourceId: source.id!,
        ),
      );
      var result = await summary();
      expect(
        result.periods.single.lines
            .singleWhere((f) => f.key == 'netIncome')
            .amount,
        BigInt.from(2399315356),
      );
      expect(
        result.periods.single.lines
            .singleWhere((f) => f.key == 'netIncome')
            .accountId,
        isNull,
      );
      Future<List<List<dynamic>>> totals() async => session.db.unsafeQuery(
        'WITH ${FinancialBasis.ctes(companyId: company.id!)} SELECT acc,v FROM ttm',
      );
      expect(
        (await totals()).any(
          (r) => r[0] == net && r[1].toString() == '2399315356',
        ),
        isTrue,
      );
      await FinancialFact.db.insertRow(session, unknown.copyWith(id: null));
      result = await summary();
      expect(
        result.periods.single.lines.any((f) => f.key == 'netIncome'),
        isFalse,
      );
      expect((await totals()).any((r) => r[0] == net), isFalse);
      await FinancialFact.db.insertRow(
        session,
        unknown.copyWith(id: null, accountId: net, amount: BigInt.from(100)),
      );
      result = await summary();
      expect(
        result.periods.single.lines
            .singleWhere((f) => f.key == 'netIncome')
            .amount,
        BigInt.from(100),
      );
      expect(
        (await totals()).any((r) => r[0] == net && r[1].toString() == '100'),
        isTrue,
      );
    });

    test(
      'no financials and explicit missing basis never silently substitute',
      () async {
        expect((await summary()).fsDiv, isNull);
        await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
          net: 10,
        });
        final explicit = await summary(div: FsDiv.consolidated);
        expect(explicit.fsDiv, FsDiv.consolidated);
        expect(explicit.periods, isEmpty);
        expect((await summary()).basisReason, 'separate_only');
      },
    );
    for (final amount in [100, 0, -100]) {
      test('consolidated priority includes zero and loss ($amount)', () async {
        await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
          net: amount,
        });
        await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
          net: 500,
        });
        expect((await summary()).fsDiv, FsDiv.consolidated);
      });
    }
    test(
      'missing prior half year uses coherent separate TTM and matches screener',
      () async {
        await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
          net: 100,
          assets: 1000000000,
        });
        await report(FsDiv.consolidated, 2026, FinancialReportCode.halfYear, {
          net: 50,
          assets: 1000000000,
        });
        await report(FsDiv.separate, 2025, FinancialReportCode.halfYear, {
          net: 20,
        });
        await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
          net: 90,
        });
        await report(FsDiv.separate, 2026, FinancialReportCode.halfYear, {
          net: 40,
          assets: 1000000000,
        });
        final result = await summary();
        expect(result.fsDiv, FsDiv.separate);
        expect(result.basisReason, 'incomplete_consolidated');
        final security = await Security.db.insertRow(
          session,
          Security(
            isinCode: 'KR_EDGE',
            shortCode: '999999',
            name: 'edge',
            companyId: company.id,
            lastSeenDate: DateTime.utc(2026, 9, 23),
          ),
        );
        await MarketSnapshot.db.insertRow(
          session,
          MarketSnapshot(
            securityId: security.id!,
            baseDate: DateTime.utc(2026, 9, 23),
            marketCap: BigInt.from(1100),
            sourceId: source.id!,
          ),
        );
        await MarketSnapshotDay.db.insertRow(
          session,
          MarketSnapshotDay(
            baseDate: DateTime.utc(2026, 9, 23),
            rowCount: 1,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        final screen = await ScreenEndpoint().list(
          session,
          corpCodes: [company.corpCode],
        );
        expect(screen.items.single.fsDiv, result.fsDiv);
        expect(screen.items.single.netIncome, BigInt.from(110));
        expect(screen.items.single.per, 10);
        expect((await summary(div: FsDiv.consolidated)).periods.length, 2);
      },
    );
    test('auto returns to consolidated when missing history arrives; manual stays separate', () async {
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        net: 100,
      });
      await report(FsDiv.consolidated, 2026, FinancialReportCode.halfYear, {
        net: 50,
      });
      await report(FsDiv.separate, 2025, FinancialReportCode.halfYear, {
        net: 20,
      });
      await report(FsDiv.separate, 2025, FinancialReportCode.annual, {net: 90});
      await report(FsDiv.separate, 2026, FinancialReportCode.halfYear, {
        net: 40,
      });
      expect((await summary()).fsDiv, FsDiv.separate);
      await report(FsDiv.consolidated, 2025, FinancialReportCode.halfYear, {
        net: 30,
      });
      expect((await summary()).fsDiv, FsDiv.consolidated);
      expect((await summary(div: FsDiv.separate)).fsDiv, FsDiv.separate);
    });
    test('do not lose available cash flow to gain revenue', () async {
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        cash: 10,
      });
      await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
        revenue: 100,
      });
      expect((await summary()).fsDiv, FsDiv.consolidated);
    });
    test(
      'both incomplete keeps consolidated instead of mixing periods',
      () async {
        for (final div in FsDiv.values) {
          await report(div, 2026, FinancialReportCode.halfYear, {net: 10});
        }
        expect((await summary()).fsDiv, FsDiv.consolidated);
      },
    );
    test(
      'old complete separate never replaces fresh incomplete consolidated',
      () async {
        await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
          net: 100,
        });
        await report(FsDiv.consolidated, 2026, FinancialReportCode.halfYear, {
          net: 10,
        });
        expect((await summary()).fsDiv, FsDiv.consolidated);
      },
    );
    test('newer separate selected over stale consolidated', () async {
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        net: 100,
      });
      await report(FsDiv.separate, 2026, FinancialReportCode.halfYear, {
        net: 10,
      });
      expect((await summary()).basisReason, 'newer_separate');
    });
    test(
      'superseded report cannot establish newest period or completeness',
      () async {
        await report(FsDiv.consolidated, 2026, FinancialReportCode.halfYear, {
          net: 10,
        }, superseded: true);
        await report(FsDiv.separate, 2025, FinancialReportCode.annual, {
          net: 10,
        });
        expect((await summary()).basisReason, 'separate_only');
      },
    );
    test('segment facts do not qualify as company totals', () async {
      await report(FsDiv.consolidated, 2025, FinancialReportCode.annual, {
        net: 10,
      }, details: true);
      await report(FsDiv.separate, 2025, FinancialReportCode.annual, {net: 10});
      expect((await summary()).basisReason, 'incomplete_consolidated');
    });
  });
}
