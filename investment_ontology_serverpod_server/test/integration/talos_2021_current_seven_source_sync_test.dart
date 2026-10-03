import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Talos own 2021 current seven', (builder, endpoints) {
    test(
      'normal own current seven keeps missing PPE and replays without API',
      () async {
        final s = builder.asAdmin.build();
        final now = DateTime.utc(2026, 10, 3);
        final entries = VerifiedAnnualSourceRegistry.entries
            .where((e) => e.ruleVersion == 'talos-own-2021-current-seven-v1')
            .toList();
        expect(entries, hasLength(1));
        final company = await Company.db.insertRow(
          s,
          Company(
            corpCode: entries.first.corpCode,
            name: entries.first.companyName,
            stockCode: '000001',
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
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=3; Exact annual legal issuer corroboration failed',
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
          final filing = (await DartFiling.db.find(
            s,
            where: (t) => t.rceptNo.equals(e.receipt),
          )).single;
          expect(filing.consolidatedStatus, FilingFetchStatus.noData);
          final ownCfs = VerifiedAnnualSourceRegistry.find(
            e.receipt,
            FsDiv.consolidated,
          )!;
          final absenceSource = (await Source.db.find(
            s,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:${e.receipt}:consolidated',
            ),
          )).single;
          final ownCfsManifest = jsonDecode(
            File('${ownCfs.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          final ownCfsBody = (ownCfsManifest['sources'] as List).singleWhere(
            (v) => v['label'] == 'cfs',
          );
          expect(absenceSource.url, ownCfsBody['url']);
          final absenceAudit = jsonDecode(absenceSource.title) as Map;
          expect(absenceAudit['fsDiv'], 'consolidated');
          expect(absenceAudit['receipt'], e.receipt);
          expect(absenceAudit['corpCode'], e.corpCode);
          expect(absenceAudit['evidence'], ownCfs.absenceLiteral);
          expect(filing.separateStatus, FilingFetchStatus.stored);
          expect(filing.attempts, 3);
          expect(filing.lastError, contains('attempt=3'));
          expect(filing.bsnsYear, e.year);
          final report = (await FinancialReport.db.find(
            s,
            where: (t) => t.rceptNo.equals(e.receipt),
          )).single;
          expect(report.fsDiv, FsDiv.separate);
          expect(report.bsnsYear, 2021);
          final source = (await Source.db.findById(s, report.sourceId))!;
          final manifest = jsonDecode(
            File('${e.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          final body = (manifest['sources'] as List).singleWhere(
            (x) => x['label'] == 'ofs',
          );
          expect(source.kind, SourceKind.dartReport);
          expect(source.url, body['url']);
          expect(source.reference, e.receipt);
          final facts = await FinancialFact.db.find(
            s,
            where: (t) => t.reportId.equals(report.id!),
          );
          expect(facts, hasLength(7));
          expect(
            facts.every((f) => f.sourceId == source.id && f.amount != null),
            isTrue,
          );
          expect(facts.map((f) => f.amount.toString()).toSet(), {
            '12715300000',
            '7922322000',
            '4792978000',
            '8552935000',
            '630513000',
            '268403000',
            '1284415000',
          });
          expect(facts.any((f) => f.accountName.contains('유형자산')), isFalse);

          expect(
            await Source.db.find(
              s,
              where: (t) => t.reference.equals(e.auditReference),
            ),
            hasLength(1),
          );
        }
        expect(await FinancialFact.db.find(s), hasLength(7));
        final before = [for (final x in await Source.db.find(s)) x.toJson()];
        final factsBefore = [
          for (final f in await FinancialFact.db.find(s)) f.toJson(),
        ];
        final ledgerBefore = [
          for (final x in await DartFiling.db.find(s)) x.toJson(),
        ];
        await run();
        expect([for (final x in await Source.db.find(s)) x.toJson()], before);
        expect([
          for (final x in await DartFiling.db.find(s)) x.toJson(),
        ], ledgerBefore);
        expect(await FinancialReport.db.find(s), hasLength(1));
        expect(await FinancialFact.db.find(s), hasLength(7));
        expect([
          for (final f in await FinancialFact.db.find(s)) f.toJson(),
        ], factsBefore);
        expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
