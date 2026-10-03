import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/suntech_own_cf_scope.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('SunTech own FY2024 CFS direct CF selection', (
    builder,
    endpoints,
  ) {
    test('normal API0 partial eight retains physical CF accounts and source; invalid Source/duplicates cannot select NI/PPE', () async {
      final session = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
      final e = VerifiedAnnualSourceRegistry.find(
        SuntechOwnCfScope.receipt,
        FsDiv.consolidated,
      )!;
      final c = await Company.db.insertRow(
        session,
        Company(
          corpCode: e.corpCode,
          name: e.companyName,
          stockCode: '123456',
          market: Market.konex,
          fiscalMonth: 12,
        ),
      );
      final original = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: e.receipt,
          title: 'Existing original correction witness',
          retrievedAt: now,
        ),
      );
      final originalBefore = original.toJson();
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      final f = await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: c.id!,
          corpCode: c.corpCode,
          rceptNo: e.receipt,
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (2024.12)',
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 7,
          lastError: 'api-noData-annual-public:attempt=3; original failure',
          discoveredAt: now,
        ),
      );
      var reads = 0;
      final cache = VerifiedAnnualSourceCache(
        readAsset: (path) async {
          reads++;
          // The actual opposite package remains separately approved. Its unavailable
          // cache in this isolated scenario must stay failed, never become absence.
          if (!path.startsWith('${e.assetDirectory}/')) {
            throw const FileSystemException(
              'Isolated opposite-source read failure',
            );
          }
          return File(path).readAsBytes();
        },
      );
      Future<IngestJob> run() async {
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
          sourceCache: cache,
        ).run();
        expect(client.calls, 0);
        expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
        return (await IngestJob.db.findById(session, job.id!))!;
      }

      final first = await run();
      expect(first.status, IngestStatus.failed);
      expect(first.updated, 1);
      expect(first.failed, 1);
      final after = (await DartFiling.db.findById(session, f.id!))!;
      expect(after.consolidatedStatus, FilingFetchStatus.stored);
      expect(after.separateStatus, FilingFetchStatus.failed);
      expect(after.attempts, 7);
      expect(after.lastError, contains('attempt=3'));
      final report = (await FinancialReport.db.find(
        session,
        where: (t) => t.companyId.equals(c.id!),
      )).single;
      expect(report.factCount, 8);
      expect(report.fsDiv, FsDiv.consolidated);
      expect(report.bsnsYear, 2024);
      final source = (await Source.db.findById(session, report.sourceId))!;
      expect(source.title, SuntechOwnCfScope.sourceTitle(report.reportName));
      expect(SuntechOwnCfScope.validSource(c, report, source), true);
      final detail = (await endpoints.financial.report(builder, report.id!))!;
      expect(detail.facts.length, 8);
      expect(detail.facts.every((x) => x.accountId == null), true);
      final targetFacts = <String, FinancialFact>{};
      for (final key in SuntechOwnCfScope.keys) {
        final t = detail.facts.singleWhere(
          (x) => x.accountName == SuntechOwnCfScope.cell(key)['label'],
        );
        targetFacts[key] = t;
        expect(t.statement, FinancialStatementKind.cashFlow);
        expect(t.amount, BigInt.parse(SuntechOwnCfScope.cell(key)['value']));
        expect(t.sourceId, source.id);
      }
      final proof = jsonDecode(
        source.title.substring(source.title.indexOf(' · {') + 3),
      );
      expect(proof['CECurrencyVerified'], false);
      expect(proof['wholePLNISynthesized'], false);
      expect(proof['notesVerified'], false);
      expect(proof['fullStatementCollected'], false);
      final security = await Security.db.insertRow(
        session,
        Security(
          isinCode: 'KR7123456000',
          shortCode: '123456',
          name: c.name,
          market: Market.konex,
          companyId: c.id,
          lastSeenDate: now,
        ),
      );
      await MarketSnapshot.db.insertRow(
        session,
        MarketSnapshot(
          securityId: security.id!,
          baseDate: now,
          marketCap: BigInt.from(1000000000),
          closePrice: BigInt.from(10000),
          sourceId: original.id!,
        ),
      );
      await MarketSnapshotDay.db.insertRow(
        session,
        MarketSnapshotDay(
          baseDate: now,
          rowCount: 1,
          sourceId: original.id,
          fetchedAt: now,
        ),
      );
      Future<void> parity(Set<String> accepted) async {
        final summary = (await endpoints.financial.summary(
          builder,
          c.corpCode,
          fsDiv: FsDiv.consolidated,
        ))!;
        final lines = summary.periods.expand((p) => p.lines);
        for (final key in SuntechOwnCfScope.keys) {
          final selected = lines.where((x) => x.key == key).toList();
          expect(selected.length, accepted.contains(key) ? 1 : 0);
          if (selected.isNotEmpty) {
            expect(selected.single.statement, FinancialStatementKind.cashFlow);
            expect(selected.single.accountId, isNull);
            expect(
              selected.single.accountName,
              SuntechOwnCfScope.cell(key)['label'],
            );
            expect(
              selected.single.amount,
              BigInt.parse(SuntechOwnCfScope.cell(key)['value']),
            );
          }
          final sql = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f.id=@id',
            parameters: QueryParameters.named({'id': targetFacts[key]!.id!}),
          );
          expect(
            sql.single.first,
            accepted.contains(key)
                ? key == 'netIncome'
                      ? 'ifrs-full_ProfitLoss'
                      : 'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'
                : null,
          );
        }
        final page = await endpoints.screen.list(
          builder,
          corpCodes: [c.corpCode],
        );
        if (accepted.length == 2) {
          expect(page.items.length, 1);
          expect(page.items.single.netIncome, BigInt.from(-1288353219));
          expect(page.items.single.freeCashFlow, BigInt.from(-3163996338));
        } else {
          expect(page.items.length, lessThanOrEqualTo(1));
          if (!accepted.contains('netIncome')) {
            expect(page.items.every((x) => x.netIncome == null), true);
          }
          if (!accepted.contains('capex')) {
            expect(page.items.every((x) => x.freeCashFlow == null), true);
          }
        }
      }

      await parity(SuntechOwnCfScope.keys);
      for (final bad in [
        source.copyWith(title: '${source.title} '),
        source.copyWith(reference: 'wrong'),
        source.copyWith(url: 'https://dart.fss.or.kr/wrong'),
        source.copyWith(kind: SourceKind.manual),
      ]) {
        await Source.db.updateRow(session, bad);
        await parity({});
        await Source.db.updateRow(session, source);
      }
      for (final key in SuntechOwnCfScope.keys) {
        final target = targetFacts[key]!;
        final duplicate = await FinancialFact.db.insertRow(
          session,
          target.copyWith(id: null),
        );
        await parity(SuntechOwnCfScope.keys.difference({key}));
        await FinancialFact.db.deleteRow(session, duplicate);
        for (final bad in [
          target.copyWith(amount: BigInt.zero),
          target.copyWith(statement: FinancialStatementKind.incomeStatement),
          target.copyWith(accountId: 'ifrs-full_ProfitLoss'),
          target.copyWith(periodName: '2023-01-01~2023-12-31'),
          target.copyWith(ord: 1),
        ]) {
          await FinancialFact.db.updateRow(session, bad);
          await parity(SuntechOwnCfScope.keys.difference({key}));
          await FinancialFact.db.updateRow(session, target);
        }
      }
      await parity(SuntechOwnCfScope.keys);
      expect(
        (await Source.db.findById(session, original.id!))!.toJson(),
        originalBefore,
      );
      final sourceBefore = (await Source.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          factsBefore = (await FinancialFact.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList(),
          reportBefore = (await FinancialReport.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((x) => x.toJson()).toList();
      final readCount = reads;
      final replay = await run();
      expect(replay.updated, 0);
      expect(replay.status, IngestStatus.failed);
      expect(reads, readCount);
      expect(
        (await Source.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList(),
        sourceBefore,
      );
      expect(
        (await FinancialFact.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList(),
        factsBefore,
      );
      expect(
        (await FinancialReport.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((x) => x.toJson()).toList(),
        reportBefore,
      );
    });
  });
}
