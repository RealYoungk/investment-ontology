import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/filing_series_cfs_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Eleven source-bound filing-series CFS-none originals', (
    builder,
    endpoints,
  ) {
    for (final p in FilingSeriesCfsAbsence.profiles) {
      test(
        '${p['receipt']} normal API0 own absence, original opposite API noData preserved and replay',
        () async {
          final s = builder.asAdmin.build(), now = DateTime.utc(2026, 10, 3);
          final e = VerifiedAnnualSourceRegistry.find(
            p['receipt'],
            FsDiv.consolidated,
          )!;
          final c = await Company.db.insertRow(
            s,
            Company(
              corpCode: e.corpCode,
              name: e.companyName,
              stockCode: '000001',
              market: Market.konex,
              fiscalMonth: 12,
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
          // Existing raw API noData is not proof of statement absence; this fixture isolates the CFS recovery and retains that distinct original state.
          final apiSource = await Source.db.insertRow(
            s,
            Source(
              kind: SourceKind.dartApi,
              url: 'https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json',
              reference: 'fixture-api-noData:${e.receipt}:separate',
              title: jsonEncode({
                'status': '013',
                'message': '조회된 데이타가 없습니다.',
                'receipt': e.receipt,
                'fs_div': 'OFS',
              }),
              retrievedAt: now,
            ),
          );
          final apiBefore = apiSource.toJson();
          final f = await DartFiling.db.insertRow(
            s,
            DartFiling(
              companyId: c.id,
              corpCode: c.corpCode,
              rceptNo: e.receipt,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (${e.year}.12)',
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.noData,
              attempts: 7,
              lastError: 'api-noData-annual-public:attempt=3; original API response retained',
              discoveredAt: now,
            ),
          );
          Future<IngestJob> run() async {
            final j = await IngestJob.db.insertRow(
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
              j.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(client.calls, 0);
            return (await IngestJob.db.findById(s, j.id!))!;
          }

          final first = await run();
          expect(first.failed, 0);
          expect(first.updated, 0);
          final after = (await DartFiling.db.findById(s, f.id!))!;
          expect(after.consolidatedStatus, FilingFetchStatus.noData);
          expect(after.separateStatus, FilingFetchStatus.noData);
          expect(after.attempts, 7);
          final source = (await Source.db.find(
            s,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:${e.receipt}:consolidated',
            ),
          )).single;
          final payload = jsonDecode(source.title) as Map;
          expect(payload['evidence'], p['literal']);
          expect(payload['numericFactsCollected'], 0);
          expect(payload['coreFinancialsVerified'], false);
          expect(payload['fullFinancialsVerified'], false);
          expect(payload['fullStatementCollected'], false);
          expect(payload['jurirContinuityVerified'], false);
          expect(payload['operatingHistoryContinuityVerified'], false);
          expect(payload['sha256'], p['sourceDigest']);
          expect(payload['periodStart'], e.periodStart.toIso8601String());
          expect(payload['periodEnd'], e.periodEnd.toIso8601String());
          expect(
            source.url,
            (p['sources'] as List).singleWhere(
              (v) => v['label'] == 'cfs',
            )['url'],
          );
          final identity = payload['historicalCompanyIdentity'] as Map;
          expect(identity['printedFilingActor'], p['actor']);
          expect(identity['currentMasterName'], p['name']);
          expect(identity['identityScope'], 'official-DART-filing-series-only');
          expect(identity['jurirContinuityVerified'], 'false');
          expect(identity['operatingHistoryContinuityVerified'], 'false');
          expect(identity['numericFactsCollected'], '0');
          expect(identity['coreFinancialsVerified'], 'false');
          expect(identity['fullFinancialsVerified'], 'false');
          expect(identity['printedCurrentShellName'], isNotEmpty);
          expect(payload['note'], contains(p['actor']));
          if (p['historicalSpac'] == true) {
            expect(payload['note'], contains('과거 SPAC 공시기준'));
          }
          expect(await FinancialReport.db.find(s), isEmpty);
          expect(await FinancialFact.db.find(s), isEmpty);
          expect(
            (await Source.db.findById(s, apiSource.id!))!.toJson(),
            apiBefore,
          );
          expect(
            await Source.db.find(
              s,
              where: (t) => t.reference.equals(e.auditReference),
            ),
            hasLength(1),
          );
          final before = [
            for (final v in await Source.db.find(s, orderBy: (t) => t.id))
              v.toJson(),
          ];
          final second = await run();
          expect(second.updated, 0);
          expect([
            for (final v in await Source.db.find(s, orderBy: (t) => t.id))
              v.toJson(),
          ], before);
          expect(
            (await DartFiling.db.findById(s, f.id!))!.toJson(),
            after.toJson(),
          );
          expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
        },
      );
    }
  });
}
