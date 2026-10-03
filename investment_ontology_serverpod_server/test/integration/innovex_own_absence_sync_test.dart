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
  withServerpod('Innovex three own annual printed absences', (
    builder,
    endpoints,
  ) {
    test('normal ledger uses exact current-period source with independently approved opposite basis and no API and replays identically', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      final entries = VerifiedAnnualSourceRegistry.entries
          .where(
            (e) =>
                e.ruleVersion == 'innovex-own-primary-cfs-printed-absence-v1',
          )
          .toList();
      expect(entries, hasLength(3));
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
        final opposite = VerifiedAnnualSourceRegistry.find(
          e.receipt,
          FsDiv.separate,
        );
        expect(
          filing.separateStatus,
          opposite == null
              ? FilingFetchStatus.failed
              : FilingFetchStatus.stored,
        );
        expect(filing.attempts, 3);
        expect(filing.lastError, contains('attempt=3'));
        expect(filing.bsnsYear, e.year);
        final source = (await Source.db.find(
          s,
          where: (t) => t.reference.equals(
            'financial-public-basis-not-applicable:${e.receipt}:consolidated',
          ),
        )).single;
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        final body = (manifest['sources'] as List).singleWhere(
          (x) => x['label'] == e.statementLabel,
        );
        final audit = jsonDecode(source.title) as Map;
        expect(source.kind, SourceKind.dartReport);
        expect(source.url, body['url']);
        expect(audit['receipt'], e.receipt);
        expect(audit['corpCode'], company.corpCode);
        expect(audit['fsDiv'], 'consolidated');
        expect(audit['periodStart'], DateTime.utc(e.year).toIso8601String());
        expect(
          audit['periodEnd'],
          DateTime.utc(e.year, 12, 31).toIso8601String(),
        );
        expect(audit['evidence'], '해당사항없음');
        expect(audit['sha256'], isNotEmpty);
        expect(
          await FinancialReport.db.find(
            s,
            where: (t) =>
                t.rceptNo.equals(e.receipt) &
                t.fsDiv.equals(FsDiv.consolidated),
          ),
          isEmpty,
        );
        expect(
          await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          ),
          hasLength(1),
        );
      }
      expect(await FinancialFact.db.find(s), hasLength(8));
      final ownOfs = VerifiedAnnualSourceRegistry.find(
        '20250320001369',
        FsDiv.separate,
      )!;
      final report = (await FinancialReport.db.find(s)).single;
      expect(report.rceptNo, ownOfs.receipt);
      expect(report.fsDiv, FsDiv.separate);
      final source = (await Source.db.findById(s, report.sourceId))!;
      final ownManifest = jsonDecode(
        File('${ownOfs.assetDirectory}/manifest.json').readAsStringSync(),
      ) as Map;
      final ownBody = (ownManifest['sources'] as List).singleWhere(
        (v) => v['label'] == 'ofs',
      );
      expect(source.url, ownBody['url']);
      expect(source.reference, ownOfs.receipt);
      final ownFacts = await FinancialFact.db.find(s);
      expect(
        ownFacts.every(
          (v) => v.reportId == report.id && v.sourceId == source.id,
        ),
        isTrue,
      );
      final factsBefore = [for (final v in ownFacts) v.toJson()];
      final before = [for (final x in await Source.db.find(s)) x.toJson()];
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
        for (final v in await FinancialFact.db.find(s)) v.toJson(),
      ], factsBefore);
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
