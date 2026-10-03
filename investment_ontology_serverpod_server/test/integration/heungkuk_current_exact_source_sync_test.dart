import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/heungkuk_current_exact_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Heungkuk own current cash scope eight', (builder, endpoints) {
    test('normal exact own OFS restores current eight without rewriting prior notes or consuming API', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      final entries = VerifiedAnnualSourceRegistry.entries
          .where((e) => HeungkukCurrentExactSource.supports(e.ruleVersion))
          .toList();
      expect(entries, hasLength(2));
      final company = await Company.db.insertRow(
        s,
        Company(
          corpCode: '00103176',
          name: '흥국화재해상보험(주)',
          stockCode: '000540',
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
      for (final e in entries) {
        await DartFiling.db.insertRow(
          s,
          DartFiling(
            companyId: company.id,
            corpCode: company.corpCode,
            rceptNo: e.receipt,
            reportName: '사업보고서 (${e.year}.12)',
            bsnsYear: e.year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'api-noData-annual-public:attempt=3; public annual source verification failed: cash scope',
            discoveredAt: now,
          ),
        );
      }
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
      for (final e in entries) {
        final f = (await DartFiling.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt),
        )).single;
        expect(f.consolidatedStatus, FilingFetchStatus.noData);
        expect(f.separateStatus, FilingFetchStatus.stored);
        expect(f.attempts, 3);
        expect(f.lastError, contains('attempt=3'));
        final report = (await FinancialReport.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt),
        )).single;
        expect(report.fsDiv, FsDiv.separate);
        expect(report.bsnsYear, e.year);
        final source = (await Source.db.findById(s, report.sourceId))!;
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        expect(source.kind, SourceKind.dartReport);
        expect(
          source.url,
          (manifest['sources'] as List).singleWhere(
            (r) => r['label'] == 'ofs',
          )['url'],
        );
        expect(source.reference, e.receipt);
        final facts = await FinancialFact.db.find(
          s,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts, hasLength(8));
        expect(
          facts.every((v) => v.sourceId == source.id && v.amount != null),
          true,
        );
        final lines = FinancialAccounts.pick(facts);
        expect(
          lines.where(
            (v) => [
              'assets',
              'liabilities',
              'equity',
              'revenue',
              'operatingIncome',
              'netIncome',
              'operatingCashFlow',
              'capex',
            ].contains(v.key),
          ),
          hasLength(8),
        );
        expect(
          facts.map((v) => v.amount.toString()).toSet(),
          e.year == 2022
              ? {
                  '13966098000000',
                  '13246051000000',
                  '720047000000',
                  '4528860000000',
                  '185978000000',
                  '147508000000',
                  '356205000000',
                  '7445000000',
                }
              : {
                  '13762260000000',
                  '13071612000000',
                  '690648000000',
                  '4514595000000',
                  '77138000000',
                  '62045000000',
                  '389598000000',
                  '4844000000',
                },
        );
        final provenance = jsonDecode(
          (await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          )).single.title,
        ) as Map;
        expect(provenance['status'], 'completed-source-numeric');
        expect(provenance['manifestDigest'], e.manifestDigest);
        expect(provenance['ruleVersion'], e.ruleVersion);
        expect(provenance['numericCoreRows'], 8);
        expect(provenance['networkRequests'], 0);
        expect(provenance['apiCalls'], 0);
        final originalSource = (await Source.db.find(
          s,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${e.receipt}:OFS',
          ),
        )).single;
        expect(originalSource.url, source.url);
        final originalProof = jsonDecode(originalSource.title) as Map;
        expect(originalProof['corpCode'], e.corpCode);
        expect(originalProof['targetReceipt'], e.receipt);
        expect(originalProof['fsDiv'], 'OFS');
        final rowProofs = originalProof['coreRowProvenance'] as List;
        expect(rowProofs, hasLength(8));
        for (final rowProof in rowProofs) {
          final detail = rowProof['html_provenance'] as Map;
          expect(detail['fullStatementCollected'], false);
          expect(detail['notesVerified'], false);
          expect(detail['numericCellCorrection'], false);
          final cash = detail['cashScopeProof'] as Map;
          expect(cash['priorNote43CashConflict'], e.year == 2021);
          expect(
            cash['priorNote43DifferencePrintedMillion'],
            e.year == 2021 ? 1 : 0,
          );
          expect(cash['genericRoundingTolerance'], false);
          final note6 = cash['note6CashScope'] as Map;
          expect(note6['currentComponentSumResidualPrintedMillion'], 0);
          expect(note6['priorCashConflict'], e.year == 2021);
          final classification =
              cash['currentNote43VsNote6Classification'] as Map;
          expect(classification['aggregateCashDifferencePrintedMillion'], 0);
          expect(
            classification['bankDepositDifferencePrintedMillion'],
            e.year == 2022 ? 1 : 0,
          );
          expect(
            classification['otherDepositDifferencePrintedMillion'],
            e.year == 2022 ? -1 : 0,
          );
          expect(classification['roundingAssumed'], false);
        }
      }
      expect(await FinancialFact.db.find(s), hasLength(16));
      expect(await FinancialReport.db.find(s), hasLength(2));
      final sources = [for (final v in await Source.db.find(s)) v.toJson()];
      final facts = [
        for (final v in await FinancialFact.db.find(s)) v.toJson(),
      ];
      final filings = [for (final v in await DartFiling.db.find(s)) v.toJson()];
      await run();
      expect([for (final v in await Source.db.find(s)) v.toJson()], sources);
      expect([
        for (final v in await FinancialFact.db.find(s)) v.toJson(),
      ], facts);
      expect([
        for (final v in await DartFiling.db.find(s)) v.toJson(),
      ], filings);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    });
  });
}
