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
  withServerpod('historical three own CFS absence', (builder, endpoints) {
    test('normal ledger preserves failed OFS and raw history while exact absence replays without API', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      final entries = VerifiedAnnualSourceRegistry.entries
          .where(
            (e) =>
                e.ruleVersion ==
                'historical-receipt-bound-cfs-explicit-none-v1',
          )
          .toList();
      expect(entries, hasLength(3));
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      for (final e in entries) {
        final company = await Company.db.insertRow(
          s,
          Company(
            corpCode: e.corpCode,
            name: e.companyName,
            stockCode: e.receipt.substring(8),
            fiscalMonth: 12,
            market: Market.konex,
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
        final f = (await DartFiling.db.find(
          s,
          where: (t) => t.rceptNo.equals(e.receipt),
        )).single;
        expect(f.consolidatedStatus, FilingFetchStatus.noData);
        expect(f.separateStatus, FilingFetchStatus.failed);
        expect(f.attempts, 3);
        expect(f.lastError, contains('attempt=3'));
        final source = (await Source.db.find(
          s,
          where: (t) => t.reference.equals(
            'financial-public-basis-not-applicable:${e.receipt}:consolidated',
          ),
        )).single;
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        expect(source.kind, SourceKind.dartReport);
        expect(
          source.url,
          (manifest['sources'] as List).singleWhere(
            (r) => r['label'] == 'cfs',
          )['url'],
        );
        final proof = jsonDecode(source.title) as Map;
        expect(proof['corpCode'], e.corpCode);
        expect(proof['receipt'], e.receipt);
        expect(proof['periodStart'], DateTime.utc(e.year).toIso8601String());
        expect(
          proof['periodEnd'],
          DateTime.utc(e.year, 12, 31).toIso8601String(),
        );
        expect(proof['evidence'], e.absenceLiteral);
        final history = proof['historicalCompanyIdentity'] as Map;
        expect(history['corpCode'], e.corpCode);
        expect(history['receipt'], e.receipt);
        expect(history['numericApproval'], 'false');
        expect(history['legalNameEvidenceSha256'], hasLength(64));
        expect(
          await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          ),
          hasLength(1),
        );
      }
      expect(await FinancialReport.db.find(s), isEmpty);
      expect(await FinancialFact.db.find(s), isEmpty);
      final sources = [for (final r in await Source.db.find(s)) r.toJson()];
      final filings = [for (final r in await DartFiling.db.find(s)) r.toJson()];
      await run();
      expect([for (final r in await Source.db.find(s)) r.toJson()], sources);
      expect([
        for (final r in await DartFiling.db.find(s)) r.toJson(),
      ], filings);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    });
  });
}
