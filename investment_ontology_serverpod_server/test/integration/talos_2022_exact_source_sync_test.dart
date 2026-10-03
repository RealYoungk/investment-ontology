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
  withServerpod('Talos own 2022 exact source', (
    builder,
    endpoints,
  ) {
    test('normal failed ledger stores actual own eight current facts without API and replays identically', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      final entries = VerifiedAnnualSourceRegistry.entries
          .where(
            (e) => e.ruleVersion == 'talos-own-2022-current-eight-v1',
          )
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
        expect(filing.consolidatedStatus, FilingFetchStatus.failed);
        expect(filing.separateStatus, FilingFetchStatus.stored);
        expect(filing.attempts, 3);
        expect(filing.lastError, contains('attempt=3'));
        expect(filing.bsnsYear, e.year);
        final report = (await FinancialReport.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt),
        )).single;
        expect(report.fsDiv, FsDiv.separate);
        expect(report.bsnsYear, 2022);
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
        expect(facts, hasLength(8));
        expect(
          facts.every((f) => f.sourceId == source.id && f.amount != null),
          isTrue,
        );
        expect(facts.map((f) => f.amount.toString()).toSet(), {
          '13096422929',
          '6749016414',
          '6347406515',
          '12856659431',
          '2330213967',
          '885239045',
          '1837532540',
          '217935190',
        });
        expect(
          await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          ),
          hasLength(1),
        );
      }
      expect(await FinancialFact.db.find(s), hasLength(8));
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
      expect(await FinancialFact.db.find(s), hasLength(8));
      expect([
        for (final f in await FinancialFact.db.find(s)) f.toJson(),
      ], factsBefore);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
