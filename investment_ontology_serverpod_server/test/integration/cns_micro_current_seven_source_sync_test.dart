import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/cns_micro_current_seven_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('CNS Micro exact own7', (builder, endpoints) {
    for (final e in VerifiedAnnualSourceRegistry.entries.where(
      (e) => CnsMicroCurrentSevenSource.supports(e.ruleVersion),
    )) {
      test(
        '${e.receipt} normal original own7, no synthetic PPE or opposite source transplant',
        () async {
          final s = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 3);
          final profile = CnsMicroCurrentSevenSource.profiles.singleWhere(
            (p) => p['receipt'] == e.receipt,
          ) as Map;
          final ofs = (profile['sources'] as List).singleWhere(
            (p) => p['label'] == 'ofs',
          ) as Map;
          final company = await Company.db.insertRow(
            s,
            Company(
              corpCode: e.corpCode,
              name: e.companyName,
              stockCode: e.year == 2022 ? '245450' : '178780',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          await ApiCallUsage.db.insertRow(
            s,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-03',
              calls: 20000,
            ),
          );
          await DartFiling.db.insertRow(
            s,
            DartFiling(
              companyId: company.id,
              corpCode: e.corpCode,
              rceptNo: e.receipt,
              reportName: '사업보고서 (${e.year}.12)',
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: e.year == 2022
                  ? FilingFetchStatus.noData
                  : FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=3; public annual source verification failed: Annual current statement title period mismatch',
              discoveredAt: now,
            ),
          );
          Future<void> run() async {
            final job = await IngestJob.db.insertRow(
              s,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final client = SourceClient();
            await FinancialFactsSync(
              s,
              client,
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(client.calls, 0);
          }

          await run();
          final filing = (await DartFiling.db.find(s)).single;
          expect(filing.separateStatus, FilingFetchStatus.stored);
          expect(filing.attempts, 3);
          expect(filing.lastError, contains('attempt=3'));
          if (e.year == 2022) {
            expect(filing.consolidatedStatus, FilingFetchStatus.noData);
          }
          final report = (await FinancialReport.db.find(
            s,
            where: (t) => t.fsDiv.equals(FsDiv.separate),
          )).single;
          expect(report.bsnsYear, e.year);
          expect(report.rceptNo, e.receipt);
          final source = (await Source.db.findById(s, report.sourceId))!;
          expect(source.url, ofs['url']);
          expect(source.reference, e.receipt);
          expect(source.kind, SourceKind.dartReport);
          final facts = await FinancialFact.db.find(
            s,
            where: (t) => t.reportId.equals(report.id!),
          );
          expect(facts, hasLength(7));
          expect(
            facts.every(
              (f) =>
                  f.sourceId == source.id &&
                  f.bsnsYear == e.year &&
                  f.fsDiv == FsDiv.separate,
            ),
            true,
          );
          expect(
            facts.map((f) => f.amount.toString()).toSet(),
            e.year == 2022
                ? {
                    '8857831382',
                    '6935338185',
                    '1922493197',
                    '19991208651',
                    '-147756862',
                    '-412587926',
                    '331138751',
                  }
                : {
                    '25104359650',
                    '14798747907',
                    '10305611743',
                    '8349068677',
                    '590611790',
                    '166398850',
                    '-465157269',
                  },
          );
          expect(FinancialAccounts.pick(facts).map((r) => r.key).toSet(), {
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
          });
          // Micro's already-registered independent CFS audit can run normally; it must
          // never use this separate source or turn the separate rows into CFS facts.
          for (final other in await FinancialReport.db.find(
            s,
            where: (t) => t.fsDiv.equals(FsDiv.consolidated),
          )) {
            expect(
              (await Source.db.findById(s, other.sourceId))!.url,
              isNot(ofs['url']),
            );
            expect(other.bsnsYear, e.year);
          }
          final audit = jsonDecode(
            (await Source.db.find(
              s,
              where: (t) => t.reference.equals(e.auditReference),
            )).single.title,
          ) as Map;
          expect(audit['status'], 'completed-source-numeric');
          expect(audit['manifestDigest'], e.manifestDigest);
          expect(audit['numericCoreRows'], 7);
          expect(audit['apiCalls'], 0);
          expect(audit['networkRequests'], 0);
          final proof = jsonDecode(
            (await Source.db.find(
              s,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:${e.receipt}:${e.basis.name}',
              ),
            )).single.title,
          ) as Map;
          expect(proof['corpCode'], e.corpCode);
          expect(proof['targetReceipt'], e.receipt);
          expect(proof['fsDiv'], e.basis.name);
          final rows = proof['coreRowProvenance'] as List;
          expect(rows, hasLength(7));
          for (final row in rows) {
            final p = row['html_provenance'] as Map;
            expect(p['partialCore7'], true);
            expect(p['uncollectedOptionalAccounts'], ['capex']);
            expect(p['printedCurrentPeriodAnomaly'], profile['anomaly']);
            expect(p['fullStatementVerified'], false);
            expect(p['numericCellCorrection'], false);
            expect(p['priorNumericPeriodsCollected'], false);
            expect(p['sourceSha256'], ofs['sha256']);
          }
          final beforeFacts = [
            for (final v in await FinancialFact.db.find(s)) v.toJson(),
          ];
          final beforeSources = [
            for (final v in await Source.db.find(s)) v.toJson(),
          ];
          final beforeFilings = [filing.toJson()];
          await run();
          expect([
            for (final v in await FinancialFact.db.find(s)) v.toJson(),
          ], beforeFacts);
          expect([
            for (final v in await Source.db.find(s)) v.toJson(),
          ], beforeSources);
          expect([
            for (final v in await DartFiling.db.find(s)) v.toJson(),
          ], beforeFilings);
          expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
          expect(
            await FinancialReport.db.find(
              s,
              where: (t) => t.fsDiv.equals(FsDiv.separate),
            ),
            hasLength(1),
          );
        },
      );
    }
  });
}
