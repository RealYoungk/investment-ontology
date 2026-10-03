import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/ls_kiwoom_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import '../unit/ls_kiwoom_current_source_test.dart' show expected;
import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('LS Kiwoom exact current source', (builder, endpoints) {
    for (final receipt in [
      '20220324000600',
      '20230316001115',
      '20220317000673',
    ]) {
      test(
        '$receipt normal cache worker preserves own basis/period/cells/APIbudget and replay',
        () async {
          final s = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
          final entries = VerifiedAnnualSourceRegistry.entries
              .where(
                (e) =>
                    e.receipt == receipt &&
                    LsKiwoomCurrentSource.supports(e.ruleVersion),
              )
              .toList();
          final first = entries.first;
          final company = await Company.db.insertRow(
            s,
            Company(
              corpCode: first.corpCode,
              name: first.companyName,
              stockCode: first.corpCode == '00296290' ? '039490' : '078020',
              fiscalMonth: 12,
              market: Market.kospi,
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
              corpCode: first.corpCode,
              rceptNo: receipt,
              reportName: '사업보고서 (${first.year}.12)',
              bsnsYear: first.year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=3; original own source validation failure',
              discoveredAt: now,
            ),
          );
          Future<IngestJob> run() async {
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
            return (await IngestJob.db.findById(s, job.id!))!;
          }

          final job = await run();
          expect(job.status, IngestStatus.succeeded);
          final filing = (await DartFiling.db.find(s)).single;
          expect(filing.consolidatedStatus, FilingFetchStatus.stored);
          expect(filing.separateStatus, FilingFetchStatus.stored);
          expect(filing.attempts, 3);
          expect(filing.lastError, contains('attempt=3'));
          for (final e in entries) {
            final report = (await FinancialReport.db.find(
              s,
              where: (t) => t.fsDiv.equals(e.basis),
            )).single;
            expect(report.companyId, company.id);
            expect(report.rceptNo, receipt);
            expect(report.bsnsYear, e.year);
            expect(report.reportCode, FinancialReportCode.annual);
            final p = LsKiwoomCurrentSource.profiles.singleWhere(
              (p) => p['rule'] == e.ruleVersion,
            ) as Map;
            final main = (p['sources'] as List).singleWhere(
              (s) => s['label'] == e.statementLabel,
            ) as Map;
            final src = (await Source.db.findById(s, report.sourceId))!;
            expect(src.kind, SourceKind.dartReport);
            expect(src.url, main['url']);
            expect(src.reference, receipt);
            final titleScope = jsonDecode(
              src.title.substring(src.title.indexOf(' · {') + 3),
            ) as Map;
            expect(titleScope['targetReceipt'], receipt);
            expect(titleScope['fsDiv'], e.basis.name);
            expect(titleScope['coreRows'], p['rows'].length);
            final savedTitleProof =
                titleScope['coreRowProvenance'][0]['html_provenance'] as Map;
            expect(savedTitleProof['notesVerified'], false);
            expect(
              (savedTitleProof['cashScopeEvidence']
                  as Map)['cashDetailResidual'],
              first.corpCode == '00296290' ? '-1' : '0',
            );
            final facts = await FinancialFact.db.find(
              s,
              where: (t) => t.reportId.equals(report.id!),
            );
            expect(facts.length, p['rows'].length);
            expect(
              facts.map((f) => f.amount.toString()).toSet(),
              expected['$receipt:${e.basis.name}']!.toSet(),
            );
            expect(
              facts.every(
                (f) =>
                    f.companyId == company.id &&
                    f.fsDiv == e.basis &&
                    f.bsnsYear == e.year &&
                    f.sourceId == src.id,
              ),
              true,
            );
            final keys = FinancialAccounts.pick(facts)
                .map((a) => a.key)
                .toSet();
            expect(keys, {
              'revenue',
              'operatingIncome',
              'netIncome',
              'assets',
              'liabilities',
              'equity',
              'operatingCashFlow',
              if (first.corpCode == '00296290') 'capex',
            });
            final audit = jsonDecode(
              (await Source.db.find(
                s,
                where: (t) => t.reference.equals(e.auditReference),
              )).single.title,
            ) as Map;
            expect(audit['status'], 'completed-source-numeric');
            expect(audit['manifestDigest'], e.manifestDigest);
            expect(audit['numericCoreRows'], p['rows'].length);
            expect(audit['apiCalls'], 0);
            expect(audit['networkRequests'], 0);
            final proof = jsonDecode(
              (await Source.db.find(
                s,
                where: (t) => t.reference.equals(
                  'financial-api-noData-source:$receipt:${e.basis.name}',
                ),
              )).single.title,
            ) as Map;
            expect(proof['corpCode'], e.corpCode);
            expect(proof['fsDiv'], e.basis.name);
            expect(proof['targetReceipt'], receipt);
            expect(proof['sourceReceipt'], receipt);
            final rows = proof['coreRowProvenance'] as List;
            expect(rows, hasLength(p['rows'].length));
            for (final row in rows) {
              final v = row['html_provenance'] as Map;
              expect(v['unit'], '원');
              expect(v['basis'], e.basis == FsDiv.consolidated ? 'CFS' : 'OFS');
              expect(v['periodStart'], '${e.year}-01-01');
              expect(v['periodEnd'], '${e.year}-12-31');
              expect(v['fullStatementVerified'], false);
              expect(v['notesVerified'], false);
              expect(v['priorNumericPeriodsCollected'], false);
              final n = v['cashScopeEvidence'] as Map;
              expect(n['printedUnit'], '천원');
              expect(n['crossPrecisionEqualityClaim'], false);
              expect(
                n['cashDetailResidual'],
                first.corpCode == '00296290' ? '-1' : '0',
              );
              expect(
                v['uncollectedOptionalAccounts'],
                first.corpCode == '00296290' ? isEmpty : ['capex'],
              );
            }
          }
          // The existing independent Kiwoom OFS package may also recover, but must
          // never point at this CFS source or reuse its whole entity values.
          if (first.corpCode == '00296290') {
            final opposite = (await FinancialReport.db.find(
              s,
              where: (t) => t.fsDiv.equals(FsDiv.separate),
            )).single;
            expect(
              (await Source.db.findById(s, opposite.sourceId))!.url,
              isNot(
                (LsKiwoomCurrentSource.profiles.first['sources'] as List)
                    .singleWhere((p) => p['label'] == 'cfs')['url'],
              ),
            );
          }
          final beforeFacts = [
            for (final f in await FinancialFact.db.find(s)) f.toJson(),
          ];
          final beforeSources = [
            for (final v in await Source.db.find(s)) v.toJson(),
          ];
          final beforeReports = [
            for (final v in await FinancialReport.db.find(s)) v.toJson(),
          ];
          final beforeFilings = [
            for (final v in await DartFiling.db.find(s)) v.toJson(),
          ];
          await run();
          expect([
            for (final v in await FinancialFact.db.find(s)) v.toJson(),
          ], beforeFacts);
          expect([
            for (final v in await Source.db.find(s)) v.toJson(),
          ], beforeSources);
          expect([
            for (final v in await FinancialReport.db.find(s)) v.toJson(),
          ], beforeReports);
          expect([
            for (final v in await DartFiling.db.find(s)) v.toJson(),
          ], beforeFilings);
          expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
        },
      );
    }
    test('cancelled normal job emits no new facts or sources', () async {
      final s = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
      final e = VerifiedAnnualSourceRegistry.entries.firstWhere(
        (e) => LsKiwoomCurrentSource.supports(e.ruleVersion),
      );
      final c = await Company.db.insertRow(
        s,
        Company(
          corpCode: e.corpCode,
          name: e.companyName,
          stockCode: '039490',
          fiscalMonth: 12,
        ),
      );
      final f = await DartFiling.db.insertRow(
        s,
        DartFiling(
          companyId: c.id,
          corpCode: e.corpCode,
          rceptNo: e.receipt,
          reportName: '사업보고서 (${e.year}.12)',
          bsnsYear: e.year,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'api-noData-annual-public:attempt=3; previous error',
          discoveredAt: now,
        ),
      );
      final before = f.toJson();
      final job = await IngestJob.db.insertRow(
        s,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.cancelled,
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
      expect(await FinancialFact.db.find(s), isEmpty);
      expect(await FinancialReport.db.find(s), isEmpty);
      expect(await Source.db.find(s), isEmpty);
      expect((await DartFiling.db.findById(s, f.id!))!.toJson(), before);
      expect(
        (await IngestJob.db.findById(s, job.id!))!.status,
        IngestStatus.cancelled,
      );
    });
  });
}
