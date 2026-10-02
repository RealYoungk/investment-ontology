import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Registry cache normal admin ingest', (builder, endpoints) {
    for (final entry in VerifiedAnnualSourceRegistry.entries) {
      final scenarios = [
        'success-and-rerun',
        if (entry.receipt == '20260323000661' ||
            entry.receipt == '20260323000763') ...[
          'sha-failed-and-rerun',
          'cancel-during-read',
          'newer-final-receipt',
        ],
      ];
      for (final scenario in scenarios) {
        test('${entry.receipt}:${entry.basis.name}:$scenario', () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: entry.corpCode,
              name: entry.companyName,
              stockCode: '123456',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          final opposite = entry.basis == FsDiv.consolidated
              ? FsDiv.separate
              : FsDiv.consolidated;
          String? dtoPath;
          if (entry.receipt == '20260323000763') dtoPath = 'test/fixtures/financial_html/elivision-cfs-none/20260323000763/stored-ofs-public-dto.json';
          if (entry.receipt == VerifiedAnnualSourceCache.receipt) dtoPath = 'test/fixtures/financial_html/talos-current/stored-ofs-public-dto.json';
          if (entry.receipt == VerifiedAnnualSourceCache.pimReceipt) dtoPath = 'test/fixtures/financial_html/pim-cfs-whole-ce/stored-ofs-public-dto.json';
          final dto = dtoPath == null
              ? null
              : jsonDecode(File(dtoPath).readAsStringSync()) as Map;
          // Public DTO when available; otherwise explicitly synthetic preservation sentinel.
          final oldSource = await Source.db.insertRow(
            session,
            dto == null
                ? Source(
                    kind: SourceKind.dartReport,
                    reference: entry.receipt,
                    url:
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}',
                    title: 'Synthetic opposite-basis preservation sentinel',
                    retrievedAt: now,
                  )
                : Source.fromJson(Map<String, dynamic>.from(dto['source']))
                      .copyWith(id: null),
          );
          final oldReport = await FinancialReport.db.insertRow(
            session,
            dto == null
                ? FinancialReport(
                    companyId: company.id!,
                    rceptNo: entry.receipt,
                    fsDiv: opposite,
                    bsnsYear: entry.year,
                    reportCode: FinancialReportCode.annual,
                    reportName: '사업보고서 (${entry.year}.12)',
                    factCount: 1,
                    invalidAmountCount: 0,
                    sourceId: oldSource.id!,
                    fetchedAt: now,
                  )
                : FinancialReport.fromJson(
                    Map<String, dynamic>.from(dto['report']),
                  ).copyWith(
                    id: null,
                    companyId: company.id!,
                    sourceId: oldSource.id!,
                  ),
          );
          final oldFacts = await FinancialFact.db.insert(
            session,
            dto == null
                ? [
                    FinancialFact(
                      companyId: company.id!,
                      reportId: oldReport.id!,
                      bsnsYear: entry.year,
                      reportCode: FinancialReportCode.annual,
                      fsDiv: opposite,
                      statement: FinancialStatementKind.balanceSheet,
                      accountId: 'ifrs-full_Assets',
                      accountName: '합성 보존값',
                      amount: BigInt.from(1234567),
                      currency: 'KRW',
                      sourceId: oldSource.id!,
                    ),
                  ]
                : (dto['facts'] as List)
                      .map(
                        (r) =>
                            FinancialFact.fromJson(Map<String, dynamic>.from(r))
                                .copyWith(
                                  id: null,
                                  companyId: company.id!,
                                  reportId: oldReport.id!,
                                  sourceId: oldSource.id!,
                                ),
                      )
                      .toList(),
          );
          final sourceBefore = oldSource.toJson(),
              reportBefore = oldReport.toJson(),
              factsBefore = [for (final f in oldFacts) f.toJson()];
          final target = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: entry.corpCode,
              rceptNo: entry.receipt,
              reportName: '사업보고서 (${entry.year}.12)',
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: entry.basis == FsDiv.consolidated
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              separateStatus: entry.basis == FsDiv.separate
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              attempts: 7,
              lastError: 'api-noData-annual-public:attempt=3; original failure',
              discoveredAt: now,
            ),
          );
          if (scenario == 'newer-final-receipt') {
            await DartFiling.db.insertRow(
              session,
              target.copyWith(
                id: null,
                rceptNo: '20260930009999',
                consolidatedStatus: FilingFetchStatus.noData,
                separateStatus: FilingFetchStatus.noData,
              ),
            );
          }
          var reads = 0, runs = 0;
          Future<void> run() async {
            final job = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final client = SourceClient();
            final cache = VerifiedAnnualSourceCache(
              readAsset: (path) async {
                reads++;
                if (scenario == 'cancel-during-read' && reads == 1) {
                  await IngestJob.db.updateRow(
                    session,
                    job.copyWith(status: IngestStatus.cancelled),
                  );
                }
                final bytes = await File(path).readAsBytes();
                return scenario == 'sha-failed-and-rerun' &&
                        path.endsWith('manifest.json')
                    ? [...bytes, 32]
                    : bytes;
              },
            );
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
            final finished = (await IngestJob.db.findById(session, job.id!))!;
            final numeric =
                scenario == 'success-and-rerun' &&
                    runs == 0 &&
                    entry.absenceLiteral == null
                ? 1
                : 0;
            expect(finished.updated, numeric);
            if (scenario != 'cancel-during-read') {
              expect(finished.message, contains('저장한 재무제표 $numeric벌'));
            }
            runs++;
          }

          await run();
          final firstReads = reads;
          final ledger = (await DartFiling.db.findById(session, target.id!))!;
          expect(ledger.attempts, 7);
          expect(
            ledger.lastError,
            contains('api-noData-annual-public:attempt=3;'),
          );
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.equals(entry.auditReference),
          );
          final sourceReports = await FinancialReport.db.find(
            session,
            where: (t) =>
                t.rceptNo.equals(entry.receipt) & t.fsDiv.equals(entry.basis),
          );
          final result = entry.basis == FsDiv.consolidated
              ? ledger.consolidatedStatus
              : ledger.separateStatus;
          if (scenario == 'success-and-rerun') {
            expect(audits.length, 1);
            expect(
              result,
              entry.absenceLiteral == null
                  ? FilingFetchStatus.stored
                  : FilingFetchStatus.noData,
            );
            final audit = jsonDecode(audits.single.title);
            expect(audit['manifestDigest'], entry.manifestDigest);
            expect(audit['fsDiv'], entry.basis.name);
            expect(audit['networkRequests'], 0);
            expect(audit['apiCalls'], 0);
            if (entry.absenceLiteral == null) {
              expect(sourceReports.length, 1);
              final report = sourceReports.single;
              final source = (await Source.db.findById(
                session,
                report.sourceId,
              ))!;
              final manifest = jsonDecode(
                File('${entry.assetDirectory}/manifest.json')
                    .readAsStringSync(),
              );
              final statement = (manifest['sources'] as List).singleWhere(
                (s) => s['label'] == entry.statementLabel,
              );
              expect(source.reference, entry.receipt);
              expect(source.url, statement['url']);
              final cover = File('${entry.assetDirectory}/cover.html')
                      .readAsStringSync(),
                  body = File(
                    '${entry.assetDirectory}/${entry.statementLabel}.html',
                  ).readAsStringSync();
              expect(
                source.title,
                contains(
                  'SHA256:${sha256.convert(utf8.encode('$cover\n$body'))}',
                ),
              );
              final facts = await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(report.id!),
              );
              expect(facts.length, inInclusiveRange(7, 8));
              expect(
                facts.every(
                  (f) =>
                      f.accountId == null &&
                      f.sourceId == source.id &&
                      f.currency == 'KRW',
                ),
                true,
              );
              final summary = await endpoints.financial.summary(
                builder,
                entry.corpCode,
                fsDiv: entry.basis,
              );
              expect(
                summary!.periods.single.lines
                    .singleWhere((l) => l.key == 'netIncome')
                    .amount,
                isNotNull,
              );
            } else {
              expect(sourceReports, isEmpty);
            }
            await run();
            expect(reads, firstReads);
            expect(
              (await Source.db.find(
                session,
                where: (t) => t.reference.equals(entry.auditReference),
              )).length,
              1,
            );
          } else if (scenario == 'sha-failed-and-rerun') {
            expect(audits.length, 1);
            expect(jsonDecode(audits.single.title)['status'], 'failed');
            expect(sourceReports, isEmpty);
            expect(result, FilingFetchStatus.failed);
            await run();
            expect(reads, firstReads);
            expect(
              (await Source.db.find(
                session,
                where: (t) => t.reference.equals(entry.auditReference),
              )).length,
              1,
            );
          } else {
            expect(audits, isEmpty);
            expect(sourceReports, isEmpty);
            if (scenario == 'newer-final-receipt') expect(reads, 0);
          }
          expect(
            (await Source.db.findById(session, oldSource.id!))!.toJson(),
            sourceBefore,
          );
          expect(
            (await FinancialReport.db.findById(
              session,
              oldReport.id!,
            ))!.toJson(),
            reportBefore,
          );
          for (var i = 0; i < oldFacts.length; i++) {
            expect(
              (await FinancialFact.db.findById(
                session,
                oldFacts[i].id!,
              ))!.toJson(),
              factsBefore[i],
            );
          }
        });
      }
    }
    for (final failAll in [false, true]) {
      test(
        'registry shares maximum10 and circuit6 with bounded resume failAll=$failAll',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final companies = <String, Company>{},
              filings = <String, DartFiling>{};
          for (final entry in VerifiedAnnualSourceRegistry.entries) {
            final company = companies[entry.corpCode] ??= await Company.db
                .insertRow(
                  session,
                  Company(
                    corpCode: entry.corpCode,
                    name: entry.companyName,
                    stockCode: '123456',
                    fiscalMonth: 12,
                    market: Market.konex,
                  ),
                );
            if (!filings.containsKey(entry.receipt)) {
              filings[entry.receipt] = await DartFiling.db.insertRow(
                session,
                DartFiling(
                  companyId: company.id,
                  corpCode: entry.corpCode,
                  rceptNo: entry.receipt,
                  reportName: '사업보고서 (${entry.year}.12)',
                  bsnsYear: entry.year,
                  reportCode: FinancialReportCode.annual,
                  consolidatedStatus: FilingFetchStatus.failed,
                  separateStatus: FilingFetchStatus.failed,
                  attempts: 7,
                  lastError:
                      'api-noData-annual-public:attempt=3; original failure',
                  discoveredAt: now,
                ),
              );
            }
          }
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final client = SourceClient();
          final resumes = <DateTime>[];
          var reads = 0;
          final cache = VerifiedAnnualSourceCache(
            readAsset: (path) async {
              reads++;
              final bytes = await File(path).readAsBytes();
              return failAll && path.endsWith('manifest.json')
                  ? [...bytes, 32]
                  : bytes;
            },
          );
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            sourceCache: cache,
            scheduleResume: (at) async => resumes.add(at),
          ).run();
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.like('financial-cache-replay:%'),
          );
          expect(audits.length, failAll ? 6 : 10);
          expect(reads, failAll ? 6 : 40);
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          final numeric = audits
              .where(
                (a) =>
                    jsonDecode(a.title)['status'] == 'completed-source-numeric',
              )
              .length;
          final finished = (await IngestJob.db.findById(session, job.id!))!;
          expect(finished.updated, numeric);
          expect(
            finished.message,
            contains(
              '고정 공식 원문 재검증 ${audits.length}건·남은 ${17 - audits.length}건',
            ),
          );
          expect(resumes, [
            now.add(
              failAll
                  ? const Duration(minutes: 15)
                  : const Duration(seconds: 30),
            ),
          ]);
          for (final f in filings.values) {
            final after = (await DartFiling.db.findById(session, f.id!))!;
            expect(after.attempts, 7);
            expect(
              after.lastError,
              contains('api-noData-annual-public:attempt=3;'),
            );
          }
        },
      );
    }
  });
}
