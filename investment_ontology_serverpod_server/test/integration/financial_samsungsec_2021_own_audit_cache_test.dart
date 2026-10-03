import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/samsungsec_2021_own_audit_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'SamsungSec own 2021 CFS/OFS distinct audit source8',
    (builder, endpoints) {
      test('normal API0 queue preserves both own audit eight cells, mixed precision, correction and replay', () async {
        final session = builder.asAdmin.build();
        final now = DateTime.utc(2026, 10, 3);
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00104856',
            name: '삼성증권(주)',
            stockCode: '016360',
            fiscalMonth: 12,
            market: Market.kospi,
          ),
        );
        await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-03',
            calls: 20000,
          ),
        );
        final entry = VerifiedAnnualSourceRegistry.find(
          '20220310000784',
          FsDiv.consolidated,
        )!;
        final manifest = jsonDecode(
          File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
        );
        final cover = (manifest['sources'] as List).singleWhere(
          (v) => v['label'] == 'cover',
        );
        final correction = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title:
                'Same-receipt existing correction cover SHA256:${cover['sha256']}',
            reference: entry.receipt,
            url: cover['url'],
            retrievedAt: now.subtract(const Duration(days: 1)),
          ),
        );
        final correctionBefore = correction.toJson();
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id!,
            corpCode: company.corpCode,
            rceptNo: entry.receipt,
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: '[기재정정]사업보고서 (2021.12)',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 7,
            lastError: 'api-noData-annual-public:attempt=3; original failure',
            discoveredAt: now,
          ),
        );
        var reads = 0;
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            reads++;
            return File(path).readAsBytes();
          },
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
            sourceCache: cache,
          ).run();
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          return (await IngestJob.db.findById(session, job.id!))!;
        }

        final first = await run();
        expect(first.status, IngestStatus.succeeded);
        final after = (await DartFiling.db.findById(session, filing.id!))!;
        expect(
          first.updated,
          2,
          reason: '${first.message}; ${after.lastError}',
        );
        expect(after.consolidatedStatus, FilingFetchStatus.stored);
        expect(after.separateStatus, FilingFetchStatus.stored);
        expect(after.attempts, 7);
        final reports = await FinancialReport.db.find(
          session,
          orderBy: (t) => t.id,
        );
        expect(reports, hasLength(2));
        expect(reports.map((r) => r.sourceId).toSet(), hasLength(2));
        for (final report in reports) {
          final basis = report.fsDiv == FsDiv.consolidated ? 'cfs' : 'ofs';
          final profile =
              SamsungSec2021OwnAuditSource.profiles[basis]
                  as Map<String, dynamic>;
          final expectedURI = (profile['sources'] as List).singleWhere(
            (v) => v['label'] == basis,
          )['url'];
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(8));
          expect(detail.report.factCount, 8);
          expect(detail.source!.url, expectedURI);
          expect(
            detail.facts.every(
              (f) =>
                  f.accountId == null &&
                  f.ord != null &&
                  f.sourceId == detail.source!.id &&
                  f.fsDiv == report.fsDiv,
            ),
            true,
          );
          for (final core in profile['core'] as List) {
            final fact = detail.facts.singleWhere(
              (f) => f.ord == core['physicalOrd'],
            );
            expect(fact.amount, BigInt.parse(core['value']));
            expect(fact.accountName, core['label']);
          }
          final amountSource = await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${entry.receipt}:${report.fsDiv.name}',
            ),
          );
          final payload = jsonDecode(amountSource!.title);
          expect(payload['coreRows'], 8);
          final provenance = payload['coreRowProvenance'] as List;
          expect(
            provenance.every(
              (r) =>
                  r['html_provenance']['source'] == expectedURI &&
                  r['html_provenance']['fullStatementCollected'] == false,
            ),
            true,
          );
          final ni = provenance.singleWhere(
            (r) => r['account_nm'] == profile['core'][5]['label'],
          );
          expect(
            ni['html_provenance']['currentCell'],
            profile['core'][5]['printed'],
          );
          final gross = provenance.singleWhere(
            (r) => r['account_nm'] == '영업수익',
          );
          expect(
            gross['html_provenance']['currentCell'],
            basis == 'cfs' ? '9,809,518,741' : '9,665,173,191',
          );
          expect(gross['html_provenance']['printedUnit'], '천원');
          expect(gross['html_provenance']['precisionUnit'], '1000');
          expect(gross['html_provenance']['printedPhysicalLabel'], '소계');
          expect(gross['html_provenance']['printedCategory'], '영업수익');
          expect(gross['html_provenance']['source'], expectedURI);
          final op = provenance.singleWhere(
            (r) => r['account_nm'] == profile['core'][4]['label'],
          );
          expect(op['html_provenance']['precisionUnit'], '1');
          expect(
            op['thstrm_amount'],
            basis == 'cfs' ? '1308683292414' : '1288559477610',
          );
          expect(
            op['html_provenance']['sourceDiscrepancies'][0]['convertedDifferenceWon'],
            basis == 'cfs' ? 414 : -390,
          );
          final summary = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: report.fsDiv,
          ))!;
          const keys = [
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
            'capex',
          ];
          for (var i = 0; i < keys.length; i++) {
            expect(
              summary.periods.single.lines
                  .singleWhere((l) => l.key == keys[i])
                  .amount,
              BigInt.parse(profile['core'][i]['value']),
            );
          }
          // A superseded own-period report stays inspectable but is excluded from active summary.
          final oldSource = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'Isolated superseded fixture',
              reference: 'superseded-test-$basis',
              retrievedAt: now,
            ),
          );
          final old = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: '20220310000783',
              fsDiv: report.fsDiv,
              bsnsYear: 2021,
              reportCode: FinancialReportCode.annual,
              reportName: 'Isolated superseded fixture',
              factCount: 1,
              sourceId: oldSource.id!,
              supersededById: report.id!,
              fetchedAt: now,
            ),
          );
          final currentNI = detail.facts.singleWhere(
            (f) => f.accountName == profile['core'][5]['label'],
          );
          await FinancialFact.db.insertRow(
            session,
            FinancialFact(
              reportId: old.id!,
              companyId: company.id!,
              bsnsYear: 2021,
              reportCode: FinancialReportCode.annual,
              fsDiv: report.fsDiv,
              statement: currentNI.statement,
              accountId: currentNI.accountId,
              accountName: currentNI.accountName,
              ord: currentNI.ord,
              amount: BigInt.one,
              sourceId: oldSource.id!,
              supersededById: currentNI.id,
            ),
          );
          final stillCurrent = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: report.fsDiv,
          ))!;
          expect(
            stillCurrent.periods.single.lines
                .singleWhere((l) => l.key == 'netIncome')
                .amount,
            BigInt.parse(profile['core'][5]['value']),
          );
        }
        expect(
          (await Source.db.findById(session, correction.id!))!.toJson(),
          correctionBefore,
        );
        expect(
          (await endpoints.ingest.coverage(builder.asAdmin))
              .financialFailedFilings,
          0,
        );
        final sourceBefore = (await Source.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((s) => s.toJson()).toList();
        final reportsBefore = (await FinancialReport.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((r) => r.toJson()).toList();
        final factsBefore = (await FinancialFact.db.find(
          session,
          orderBy: (t) => t.id,
        )).map((f) => f.toJson()).toList();
        final ledgerBefore = after.toJson();
        final firstReads = reads;
        final replay = await run();
        expect(replay.status, IngestStatus.succeeded);
        expect(replay.updated, 0);
        expect(reads, firstReads);
        expect(
          (await Source.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((s) => s.toJson()).toList(),
          sourceBefore,
        );
        expect(
          (await FinancialReport.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((r) => r.toJson()).toList(),
          reportsBefore,
        );
        expect(
          (await FinancialFact.db.find(
            session,
            orderBy: (t) => t.id,
          )).map((f) => f.toJson()).toList(),
          factsBefore,
        );
        expect(
          (await DartFiling.db.findById(session, filing.id!))!.toJson(),
          ledgerBefore,
        );
      });
    },
  );
  withServerpod('SamsungSec own audit exact source refusal', (
    builder,
    endpoints,
  ) {
    test(
      'opposite body or changed NI cannot write facts or report noData',
      () async {
        final session = builder.asAdmin.build();
        final now = DateTime.utc(2026, 10, 3);
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00104856',
            name: '삼성증권(주)',
            stockCode: '016360',
            fiscalMonth: 12,
            market: Market.kospi,
          ),
        );
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id!,
            corpCode: company.corpCode,
            rceptNo: '20220310000784',
            bsnsYear: 2021,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2021.12)',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 7,
            lastError: 'api-noData-annual-public:attempt=3; original failure',
            discoveredAt: now,
          ),
        );
        await ApiCallUsage.db.insertRow(
          session,
          ApiCallUsage(
            provider: ApiProvider.dart,
            day: '2026-10-03',
            calls: 20000,
          ),
        );
        final cfs = VerifiedAnnualSourceRegistry.find(
          filing.rceptNo,
          FsDiv.consolidated,
        )!;
        final ofs = VerifiedAnnualSourceRegistry.find(
          filing.rceptNo,
          FsDiv.separate,
        )!;
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            if (path == '${cfs.assetDirectory}/audit-primary.html') {
              return File('${ofs.assetDirectory}/audit-primary.html')
                  .readAsBytes();
            }
            if (path == '${ofs.assetDirectory}/audit-primary.html') {
              return utf8.encode(
                File(path)
                    .readAsStringSync()
                    .replaceFirst('936,741,374,045', '936,741,374,046'),
              );
            }
            return File(path).readAsBytes();
          },
        );
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
          sourceCache: cache,
        ).run();
        expect(client.calls, 0);
        final result = (await IngestJob.db.findById(session, job.id!))!;
        expect(result.status, IngestStatus.failed);
        expect(result.updated, 0);
        final after = (await DartFiling.db.findById(session, filing.id!))!;
        expect(after.consolidatedStatus, FilingFetchStatus.failed);
        expect(after.separateStatus, FilingFetchStatus.failed);
        expect(await FinancialReport.db.find(session), isEmpty);
        expect(await FinancialFact.db.find(session), isEmpty);
        expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
        expect(
          (await endpoints.ingest.coverage(builder.asAdmin))
              .financialFailedFilings,
          1,
        );
      },
    );
  });
}
