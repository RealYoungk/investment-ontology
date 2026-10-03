import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Actual historical CFS and OFS own source completion', (
    builder,
    endpoints,
  ) {
    final proofs = jsonDecode(
      File('test/fixtures/financial_html/historical-cfs-source/cases.json')
          .readAsStringSync(),
    ) as List;
    for (final proof in proofs) {
      final receipt = proof['receipt'] as String;
      test(
        '$receipt actual both-failed public3 normal queue independently resolves bases',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final e = VerifiedAnnualSourceRegistry.find(
            receipt,
            FsDiv.consolidated,
          )!;
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: e.corpCode,
              name: e.companyName,
              stockCode: '123456',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final reportName =
              '${receipt == '20230714000217' ? '[기재정정]' : ''}사업보고서 (${e.year}.12)';
          final filing = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: e.corpCode,
              rceptNo: receipt,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              reportName: reportName,
              discoveredAt: now,
              attempts: 3,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              lastError: 'api-noData-annual-public:attempt=3; previous exact issuer failure',
            ),
          );
          final numericCount = e.absenceLiteral == null ? 2 : 1;
          Future<void> run(int expected) async {
            final client = SourceClient();
            final job = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
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
            expect(
              (await IngestJob.db.findById(session, job.id!))!.updated,
              expected,
            );
          }

          await run(numericCount);
          final actual = (await DartFiling.db.findById(session, filing.id!))!;
          expect(actual.attempts, 3);
          expect(actual.lastError, filing.lastError);
          expect(actual.separateStatus, FilingFetchStatus.stored);
          expect(
            actual.consolidatedStatus,
            e.absenceLiteral == null
                ? FilingFetchStatus.stored
                : FilingFetchStatus.noData,
          );
          final reports = await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(company.id!),
            orderBy: (t) => t.id,
          );
          expect(reports, hasLength(numericCount));
          final snapshots = <Map<String, dynamic>>[];
          for (final report in reports) {
            final own = VerifiedAnnualSourceRegistry.find(
              receipt,
              report.fsDiv,
            )!;
            final source = (await Source.db.findById(
              session,
              report.sourceId,
            ))!;
            final manifest = jsonDecode(
              File('${own.assetDirectory}/manifest.json').readAsStringSync(),
            );
            final statement = (manifest['sources'] as List).singleWhere(
              (s) => s['label'] == own.statementLabel,
            );
            expect(source.reference, receipt);
            expect(source.url, statement['url']);
            final facts = await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(report.id!),
              orderBy: (t) => t.id,
            );
            expect(facts, hasLength(receipt == '20230315000460' ? 6 : 7));
            expect(
              facts.every(
                (f) =>
                    f.fsDiv == report.fsDiv &&
                    f.accountId == null &&
                    f.sourceId == source.id,
              ),
              true,
            );
            final audit = (await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:$receipt:${report.fsDiv.name}',
              ),
            )).single;
            final auditRows =
                jsonDecode(audit.title)['coreRowProvenance'] as List;
            expect(
              auditRows.every(
                (r) =>
                    r['html_provenance']['basis'] ==
                    (report.fsDiv == FsDiv.consolidated ? 'CFS' : 'OFS'),
              ),
              true,
            );
            if (report.fsDiv == FsDiv.consolidated) {
              final expected = proof['expectedRows'] as List;
              expect(facts, hasLength(expected.length));
              final summary = await endpoints.financial.summary(
                builder,
                e.corpCode,
                fsDiv: FsDiv.consolidated,
              );
              const keys = [
                'assets',
                'liabilities',
                'equity',
                'revenue',
                'operatingIncome',
                'netIncome',
                'operatingCashFlow',
              ];
              for (var i = 0; i < expected.length; i++) {
                expect(
                  facts
                      .singleWhere((f) => f.accountName == expected[i][0])
                      .amount,
                  BigInt.parse(expected[i][1]),
                );
                expect(
                  summary!.periods.single.lines
                      .singleWhere((l) => l.key == keys[i])
                      .amount,
                  BigInt.parse(expected[i][1]),
                );
              }
            }
            snapshots.add({
              'report': report.toJson(),
              'source': source.toJson(),
              'facts': [for (final fact in facts) fact.toJson()],
            });
          }
          final cfsAudit = (await Source.db.find(
            session,
            where: (t) => t.reference.equals(e.auditReference),
          )).single;
          final payload = jsonDecode(cfsAudit.title);
          expect(payload['publicAttemptPreserved'], 3);
          expect(payload['networkRequests'], 0);
          expect(payload['apiCalls'], 0);
          if (e.absenceLiteral != null) {
            expect(payload['status'], 'completed-source-not-applicable');
            expect(payload['evidence'], ': 해당사항 없음');
            expect(payload['periodStart'], '2022-01-01T00:00:00.000Z');
            expect(payload['periodEnd'], '2022-12-31T00:00:00.000Z');
            final typed = (await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:$receipt:consolidated',
              ),
            )).single;
            expect(typed.url, PureunStatement.url);
            expect(jsonDecode(typed.title)['sha256'], isNotEmpty);
            final separateAudit = (await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:$receipt:separate',
              ),
            )).single;
            final separateEvidence = jsonDecode(separateAudit.title) as Map;
            expect(separateEvidence['coreRows'], 6);
            expect(separateEvidence['missingRequiredAccounts'], ['revenue']);
            expect(separateEvidence['uncollectedOptionalAccounts'], ['capex']);
            final summary = await endpoints.financial.summary(
              builder,
              e.corpCode,
              fsDiv: FsDiv.separate,
            );
            expect(
              summary!.periods.single.lines.where((l) => l.key == 'revenue'),
              isEmpty,
            );
          }
          await run(0);
          expect(
            (await Source.db.find(
              session,
              where: (t) => t.reference.equals(e.auditReference),
            )),
            hasLength(1),
          );
          for (final snapshot in snapshots) {
            final r = snapshot['report'];
            final s = snapshot['source'];
            expect(
              (await FinancialReport.db.findById(session, r['id']))!.toJson(),
              r,
            );
            expect((await Source.db.findById(session, s['id']))!.toJson(), s);
            expect([
              for (final fact in await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(r['id']),
                orderBy: (t) => t.id,
              ))
                fact.toJson(),
            ], snapshot['facts']);
          }
        },
      );
    }
  });
}

abstract final class PureunStatement {
  static const url =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=17&offset=137261&length=142&dtd=dart3.xsd';
}
