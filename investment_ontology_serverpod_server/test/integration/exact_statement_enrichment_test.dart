import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_statement_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/exact_statement_enrichment.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';

import '../unit/verified_annual_source_registry_test.dart' as fixture;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Exact current statement enrichment', (builder, endpoints) {
    for (final (receipt, basis, count) in [
      ('20250320000036', FsDiv.separate, 116),
      ('20220310001159', FsDiv.consolidated, 204),
      ('20230321000015', FsDiv.separate, 115),
      ('20220310001159', FsDiv.separate, 174),
      ('20240320001114', FsDiv.separate, 103),
      ('20250314001145', FsDiv.separate, 91),
      ('20250321000964', FsDiv.separate, 166),
      ('20250321001653', FsDiv.consolidated, 105),
      ('20250321001825', FsDiv.separate, 94),
    ]) {
      for (final scenario in [
        'normal-worker-idempotent',
        'cancelled',
        'core-conflict',
        'newer-final',
      ]) {
        test('$receipt:${basis.name}:$scenario sources', () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 3);
          final entry = VerifiedAnnualSourceRegistry.find(receipt, basis)!;
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
                  consolidatedStatus: basis == FsDiv.consolidated
                      ? FilingFetchStatus.stored
                      : FilingFetchStatus.noData,
                  separateStatus: basis == FsDiv.separate
                      ? FilingFetchStatus.stored
                      : FilingFetchStatus.noData,
                ),
          );
          final prepared = await ExactStatementRows.prepare(
            filing,
            company,
            basis,
          );
          final original = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title:
                  'DART 원문 HTML 부분 핵심계정 · SHA256:${prepared.primary.sourceDigest}',
              reference: receipt,
              url: prepared.primary.statementSource.toString(),
              retrievedAt: now,
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: receipt,
              fsDiv: basis,
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              reportName: filing.reportName,
              factCount: 8,
              sourceId: original.id!,
              fetchedAt: now,
            ),
          );
          final core = FinancialRows.toFacts(
            prepared.coreRows,
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: entry.year,
            reportCode: FinancialReportCode.annual,
            fsDiv: basis,
            sourceId: original.id!,
          );
          final old = await FinancialFact.db.insert(session, core.facts);
          Future<List<List<Object?>>> metricInputs() async => [
            for (final row in await session.db.unsafeQuery(
              'WITH ${FinancialBasis.ctes(companyId: company.id!)} '
              'SELECT resolved_id,amount::text FROM picked_facts ORDER BY resolved_id',
            ))
              row.toList(),
          ];
          final metricBefore = await metricInputs();
          if (scenario == 'core-conflict') {
            await FinancialFact.db.updateRow(
              session,
              old.first.copyWith(amount: BigInt.one),
            );
          }
          final preserved = [
            for (final fact in await FinancialFact.db.find(session))
              fact.toJson(),
          ];
          final sourceBefore = original.toJson(),
              filingBefore = filing.toJson();
          if (scenario == 'newer-final') {
            await DartFiling.db.insertRow(
              session,
              filing.copyWith(
                id: null,
                rceptNo: '20261003009999',
                consolidatedStatus: FilingFetchStatus.pending,
                separateStatus: FilingFetchStatus.pending,
              ),
            );
          }
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: 'financial_facts',
              status: scenario == 'cancelled'
                  ? IngestStatus.cancelled
                  : IngestStatus.running,
              startedAt: now,
            ),
          );
          if (scenario == 'normal-worker-idempotent') {
            await ApiCallUsage.db.insertRow(
              session,
              ApiCallUsage(
                provider: ApiProvider.dart,
                day: '2026-10-03',
                calls: 20000,
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
            final all = await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(report.id!),
            );
            expect(all, hasLength(8 + count));
            final additional = all
                .where((f) => f.sourceId != original.id)
                .toList();
            expect(additional.every((f) => f.ord != null), true);
            expect(additional.map((f) => f.ord).toSet(), hasLength(count));
            expect(
              (await IngestJob.db.findById(session, job.id!))!.status,
              IngestStatus.succeeded,
            );
            expect(
              all
                  .where(
                    (f) => f.statement == FinancialStatementKind.equityChanges,
                  )
                  .every((f) => f.accountDetail != null),
              true,
            );
            final detail = await endpoints.financial.report(
              builder.asAnonymous,
              report.id!,
            );
            expect(detail!.facts, hasLength(8 + count));
            expect(detail.sources, hasLength(2));
            expect(detail.source!.id, original.id);
            final newSource = detail.sources!.singleWhere(
              (s) => s.id != original.id,
            );
            final payload = jsonDecode(
              newSource.title.substring(newSource.title.indexOf('{')),
            ) as Map;
            expect(payload['additionalMonetaryFacts'], count);
            expect(payload['fullStatementCollected'], false);
            expect(payload['ledger'], isNotEmpty);
            final sourcesBefore = [
              for (final s in await Source.db.find(session)) s.toJson(),
            ];
            final factsBefore = [for (final f in all) f.toJson()];
            final retry = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: 'financial_facts',
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            await FinancialFactsSync(
              session,
              SourceClient(),
              retry.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(
              (await IngestJob.db.findById(session, retry.id!))!.status,
              IngestStatus.succeeded,
            );
            expect([
              for (final s in await Source.db.find(session)) s.toJson(),
            ], sourcesBefore);
            expect([
              for (final f in await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(report.id!),
              ))
                f.toJson(),
            ], factsBefore);
          } else {
            Future<int> append() => ExactStatementEnrichment.append(
              session,
              jobId: job.id!,
              report: report,
              filing: filing,
              company: company,
              prepared: prepared,
            );
            if (scenario == 'cancelled' || scenario == 'newer-final') {
              expect(await append(), 0);
            } else {
              await expectLater(append(), throwsA(isA<FormatException>()));
            }
            expect(await Source.db.count(session), 1);
            expect(await FinancialFact.db.count(session), 8);
          }
          for (final fact in preserved) {
            expect(
              (await FinancialFact.db.findById(
                session,
                fact['id'] as int,
              ))!.toJson(),
              fact,
            );
          }
          expect(
            (await Source.db.findById(session, original.id!))!.toJson(),
            sourceBefore,
          );
          expect(
            (await DartFiling.db.findById(session, filing.id!))!.toJson(),
            filingBefore,
          );
          if (scenario == 'normal-worker-idempotent') {
            expect(await metricInputs(), metricBefore);
          }
        });
      }
    }
  });
}
