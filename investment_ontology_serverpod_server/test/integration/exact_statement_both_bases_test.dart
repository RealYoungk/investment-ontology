import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_statement_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:test/test.dart';

import '../unit/verified_annual_source_registry_test.dart' as fixture;
import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exact independent CFS/OFS enrichment', (builder, endpoints) {
    test('same receipt appends both approved original bases and replays zero', () async {
      final session = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      const receipt = '20220310001159';
      final entry = VerifiedAnnualSourceRegistry.find(
        receipt,
        FsDiv.consolidated,
      )!;
      final company = await Company.db.insertRow(
        session,
        fixture.company(entry).copyWith(id: null, market: Market.konex),
      );
      final filing = await DartFiling.db.insertRow(
        session,
        fixture
            .filing(entry)
            .copyWith(
              id: null,
              companyId: company.id,
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
            ),
      );
      final originals = <FsDiv, Source>{};
      final reports = <FsDiv, FinancialReport>{};
      final originalFacts = <FinancialFact>[];
      for (final basis in FsDiv.values) {
        final prepared = await ExactStatementRows.prepare(
          filing,
          company,
          basis,
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: receipt,
            url: prepared.primary.statementSource.toString(),
            title:
                'DART 원문 HTML 부분 핵심계정 · SHA256:${prepared.primary.sourceDigest}',
            retrievedAt: now,
          ),
        );
        final report = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: company.id!,
            rceptNo: receipt,
            fsDiv: basis,
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: filing.reportName,
            factCount: 8,
            sourceId: source.id!,
            fetchedAt: now,
          ),
        );
        final parsed = FinancialRows.toFacts(
          prepared.coreRows,
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: 2021,
          reportCode: FinancialReportCode.annual,
          fsDiv: basis,
          sourceId: source.id!,
        );
        originalFacts.addAll(
          await FinancialFact.db.insert(session, parsed.facts),
        );
        originals[basis] = source;
        reports[basis] = report;
      }
      expect(
        originals[FsDiv.consolidated]!.url,
        isNot(originals[FsDiv.separate]!.url),
      );
      final originalSourceSnapshots = {
        for (final e in originals.entries) e.key: e.value.toJson(),
      };
      final originalFactSnapshots = {
        for (final f in originalFacts) f.id!: f.toJson(),
      };
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
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
        ).run();
        expect(client.calls, 0);
        expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
        return (await IngestJob.db.findById(session, job.id!))!;
      }

      final first = await run();
      expect(first.status, IngestStatus.succeeded);
      expect(first.message, contains('원문 행 보완 2기간·378금액행·실패 0기간'));
      for (final basis in FsDiv.values) {
        final report = (await FinancialReport.db.findById(
          session,
          reports[basis]!.id!,
        ))!;
        final expected = basis == FsDiv.consolidated ? 212 : 182;
        expect(report.factCount, expected);
        expect(report.sourceId, originals[basis]!.id);
        final detail = (await endpoints.financial.report(
          builder.asAnonymous,
          report.id!,
        ))!;
        expect(detail.facts, hasLength(expected));
        final appended = detail.facts
            .where((f) => f.sourceId != report.sourceId)
            .toList();
        expect(appended.every((f) => f.ord != null), true);
        expect(appended.map((f) => f.ord).toSet(), hasLength(expected - 8));
        expect(detail.sources, hasLength(2));
        expect(detail.source!.id, originals[basis]!.id);
        final additional = detail.sources!.singleWhere(
          (s) => s.id != report.sourceId,
        );
        final proof = jsonDecode(
          additional.title.substring(additional.title.indexOf('{')),
        ) as Map;
        expect(proof['basis'], basis.name);
        expect(proof['source'], originals[basis]!.url);
        expect(proof['additionalMonetaryFacts'], expected - 8);
        expect(proof['fullStatementCollected'], false);
        expect(
          (await Source.db.findById(session, originals[basis]!.id!))!.toJson(),
          originalSourceSnapshots[basis],
        );
      }
      for (final fact in originalFacts) {
        expect(
          (await FinancialFact.db.findById(session, fact.id!))!.toJson(),
          originalFactSnapshots[fact.id!],
        );
      }
      final beforeFacts = [
        for (final f in await FinancialFact.db.find(session)) f.toJson(),
      ];
      final beforeSources = [
        for (final s in await Source.db.find(session)) s.toJson(),
      ];
      final retry = await run();
      expect(
        retry.status,
        IngestStatus.succeeded,
        reason: retry.toJson().toString(),
      );
      expect(retry.updated, 0);
      expect([
        for (final f in await FinancialFact.db.find(session)) f.toJson(),
      ], beforeFacts);
      expect([
        for (final s in await Source.db.find(session)) s.toJson(),
      ], beforeSources);
    });
  });
}
