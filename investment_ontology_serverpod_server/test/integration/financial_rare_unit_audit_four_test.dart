import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import '../unit/rare_unit_audit_four_test.dart' show rareAuditCore;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

final expectedCore = {
  for (final e in rareAuditCore.entries)
    e.key: {
      for (var i = 0; i < 7; i++)
        [
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operating',
          'profit',
          'cfo',
        ][i]: e.value[i],
    },
};

class RareAuditFourClient extends SourceClient {
  final requested = <String>[];
  @override
  Future<PublicFinancialHtmlSource> fetchAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    requested.add('$receipt:${consolidated ? 'CFS' : 'OFS'}');
    final dir = VerifiedAnnualSourceRegistry.find(
      receipt,
      consolidated ? FsDiv.consolidated : FsDiv.separate,
    )!.assetDirectory;
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final files = <String, List<int>>{
      for (final row in manifest['sources'])
        row['url']: File('$dir/${row['file']}').readAsBytesSync(),
    };
    return fastFinancialHtmlFetcher(
      MockClient((r) async {
        final b = files[r.url.toString()];
        if (b == null) throw FormatException('Unbound source ${r.url}');
        return http.Response.bytes(b, 200, request: r);
      }),
    ).fetchAnnual(
      receipt,
      reportName: reportName,
      corpCode: corpCode,
      companyName: companyName,
      bsnsYear: bsnsYear,
      periodEnd: periodEnd,
      consolidated: consolidated,
    );
  }
}

void main() {
  withServerpod('직접 단위 감사 원천 4개 정상큐', (builder, endpoints) {
    for (final receipt in expectedCore.keys) {
      for (final div in [
        receipt == '20220331003444' ? FsDiv.consolidated : FsDiv.separate,
      ]) {
        for (final publicAttempt in [2, 3]) {
          final basis = div == FsDiv.consolidated ? 'cfs' : 'ofs';
          final opposite = div == FsDiv.consolidated
              ? FsDiv.separate
              : FsDiv.consolidated;
          test(
            '$receipt:$basis public$publicAttempt normal job preserves synthetic opposite/API0',
            () async {
              final session = builder.asAdmin.build(),
                  now = DateTime.utc(2026, 10, 2);
              final manifest = jsonDecode(
                File(
                  '${VerifiedAnnualSourceRegistry.find(receipt, div)!.assetDirectory}/manifest.json',
                ).readAsStringSync(),
              );
              final p = <String, dynamic>{
                'corp': manifest['corpCode'],
                'cover': manifest['sources'][1],
                'statement': (manifest['sources'] as List).singleWhere(
                  (x) => x['label'] == 'ofs',
                ),
              };
              final year = manifest['year'] as int;

              await ApiCallUsage.db.insertRow(
                session,
                ApiCallUsage(
                  provider: ApiProvider.dart,
                  day: '2026-10-02',
                  calls: 20000,
                ),
              );
              for (var i = 0; i < 10; i++) {
                final corp = '8${i.toString().padLeft(7, '0')}';
                final company = await Company.db.insertRow(
                  session,
                  Company(
                    corpCode: corp,
                    name: 'Generic$i',
                    stockCode: '9${i.toString().padLeft(5, '0')}',
                    market: Market.konex,
                    fiscalMonth: 12,
                  ),
                );
                await DartFiling.db.insertRow(
                  session,
                  DartFiling(
                    companyId: company.id,
                    corpCode: corp,
                    rceptNo: '20260930${i.toString().padLeft(6, '0')}',
                    reportName: '사업보고서 (2025.12)',
                    bsnsYear: 2025,
                    reportCode: FinancialReportCode.annual,
                    discoveredAt: now,
                    attempts: 3,
                    consolidatedStatus: FilingFetchStatus.failed,
                    separateStatus: FilingFetchStatus.failed,
                    lastError:
                        'api-noData-annual-public:attempt=2; previous failure',
                  ),
                );
              }
              final company = await Company.db.insertRow(
                session,
                Company(
                  corpCode: p['corp'],
                  name: VerifiedAnnualSourceRegistry.find(
                    receipt,
                    div,
                  )!.companyName,
                  stockCode: '111111',
                  market: Market.konex,
                  fiscalMonth: 12,
                ),
              );
              final source = await Source.db.insertRow(
                session,
                Source(
                  kind: SourceKind.dartReport,
                  title: 'Preserved opposite basis',
                  url: p['cover']['url'],
                  reference: receipt,
                  retrievedAt: now,
                ),
              );
              final prior = await FinancialReport.db.insertRow(
                session,
                FinancialReport(
                  companyId: company.id!,
                  fsDiv: opposite,
                  bsnsYear: year,
                  reportCode: FinancialReportCode.annual,
                  rceptNo: receipt,
                  reportName: '사업보고서 ($year.12)',
                  sourceId: source.id!,
                  factCount: 1,
                  fetchedAt: now,
                ),
              );
              final fact = await FinancialFact.db.insertRow(
                session,
                FinancialFact(
                  companyId: company.id!,
                  reportId: prior.id!,
                  fsDiv: opposite,
                  bsnsYear: year,
                  reportCode: FinancialReportCode.annual,
                  statement: FinancialStatementKind.balanceSheet,
                  accountId: 'ifrs-full_Assets',
                  accountName: 'immutable opposite',
                  amount: BigInt.from(123),
                  sourceId: source.id!,
                ),
              );
              final before = [source.toJson(), prior.toJson(), fact.toJson()];
              final f = await DartFiling.db.insertRow(
                session,
                DartFiling(
                  companyId: company.id,
                  corpCode: p['corp'],
                  rceptNo: receipt,
                  reportName: '사업보고서 ($year.12)',
                  bsnsYear: year,
                  reportCode: FinancialReportCode.annual,
                  discoveredAt: now,
                  attempts: 3,
                  consolidatedStatus: div == FsDiv.consolidated
                      ? FilingFetchStatus.failed
                      : FilingFetchStatus.stored,
                  separateStatus: div == FsDiv.separate
                      ? FilingFetchStatus.failed
                      : FilingFetchStatus.stored,
                  lastError:
                      'api-noData-annual-public:attempt=$publicAttempt; Ambiguous annual current header',
                ),
              );
              final job = await IngestJob.db.insertRow(
                session,
                IngestJob(
                  kind: FinancialFactsSync.kind,
                  status: IngestStatus.running,
                  startedAt: now,
                ),
              );
              final reader = RareAuditFourClient();
              await FinancialFactsSync(
                session,
                reader,
                job.id!,
                dailyBudget: 0,
                clock: () => now,
                callInterval: Duration.zero,
              ).run();
              if (publicAttempt == 2) {
                expect(
                  reader.requested.first,
                  '$receipt:${div == FsDiv.consolidated ? 'CFS' : 'OFS'}',
                );
              } else {
                expect(
                  reader.requested.any((x) => x.startsWith('$receipt:')),
                  false,
                );
              }
              expect(reader.calls, 0);
              final storedReports = await FinancialReport.db.find(
                session,
                where: (t) =>
                    t.companyId.equals(company.id!) & t.fsDiv.equals(div),
              );
              expect(
                storedReports,
                hasLength(1),
                reason:
                    'filing=${(await DartFiling.db.findById(session, f.id!))!.toJson()} job=${(await IngestJob.db.findById(session, job.id!))!.toJson()} sources=${(await Source.db.find(session)).where((x) => x.reference?.contains(receipt) == true).map((x) => x.toJson()).toList()}',
              );
              final stored = storedReports.single;
              final main = (await Source.db.findById(
                session,
                stored.sourceId,
              ))!;
              final actualReceipt = receipt == '20250317000968'
                  ? '20250317000704'
                  : receipt;
              expect(main.reference, actualReceipt);
              expect(stored.rceptNo, actualReceipt);
              expect(main.url, p['statement']['url']);
              final facts = await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(stored.id!),
              );
              expect(facts.length, greaterThanOrEqualTo(7));
              expect(
                facts.every(
                  (x) => x.accountId == null && x.sourceId == main.id,
                ),
                true,
              );
              final sourceAudit = (await Source.db.find(session))
                  .where(
                    (x) =>
                        x.reference?.contains(receipt) == true &&
                        x.id != main.id,
                  )
                  .toList();
              expect(sourceAudit, isNotEmpty);
              final expectedCacheAudit = jsonDecode(
                File(
                  '${VerifiedAnnualSourceRegistry.find(receipt, div)!.assetDirectory}/manifest.json',
                ).readAsStringSync(),
              );
              final statementRaw = (expectedCacheAudit['sources'] as List)
                  .cast<Map<String, dynamic>>()
                  .singleWhere((x) => x['label'] == 'ofs');
              expect(main.url, statementRaw['url']);
              expect(
                sha256
                    .convert(
                      File(
                        '${VerifiedAnnualSourceRegistry.find(receipt, div)!.assetDirectory}/${statementRaw['file']}',
                      ).readAsBytesSync(),
                    )
                    .toString(),
                statementRaw['sha256'],
              );
              final summary = (await FinancialEndpoint().summary(
                session,
                company.corpCode,
                fsDiv: div,
              ))!;
              expect(
                summary.periods.single.lines
                    .singleWhere((x) => x.key == 'revenue')
                    .amount,
                BigInt.parse(
                  expectedCore[receipt]!['revenue']!,
                ),
              );
              expect(
                (await DartFiling.db.findById(session, f.id!))!.attempts,
                3,
              );
              expect(
                (await DartFiling.db.findById(session, f.id!))!.lastError,
                contains('attempt=${publicAttempt == 2 ? 3 : publicAttempt}'),
              );
              expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
              expect(
                (await IngestJob.db.findById(session, job.id!))!.updated,
                1,
              );
              for (final item in expectedCore[receipt]!.entries) {
                final line = summary.periods.single.lines.singleWhere(
                  (x) =>
                      x.key ==
                      ({
                            'operating': 'operatingIncome',
                            'profit': 'netIncome',
                            'cfo': 'operatingCashFlow',
                          }[item.key] ??
                          item.key),
                );
                expect(line.amount, BigInt.parse(item.value), reason: item.key);
              }
              final assets = summary.periods.single.lines
                  .singleWhere((x) => x.key == 'assets')
                  .amount;
              expect(
                assets,
                BigInt.parse(
                  expectedCore[receipt]!['assets']!,
                ),
              );
              final resolved = await session.db.unsafeQuery(
                'SELECT ${FinancialAccounts.resolvedIdSql("f")} AS account FROM financial_fact f WHERE f."reportId"=@id',
                parameters: QueryParameters.named({'id': stored.id!}),
              );
              expect(
                resolved.map((x) => x[0]).where((x) => x == 'ifrs-full_Assets'),
                hasLength(1),
              );

              expect(
                (await DartFiling.db.findById(
                  session,
                  f.id!,
                ))!.consolidatedStatus,
                FilingFetchStatus.stored,
              );
              expect(
                (await DartFiling.db.findById(session, f.id!))!.separateStatus,
                FilingFetchStatus.stored,
              );
              expect([
                (await Source.db.findById(session, source.id!))!.toJson(),
                (await FinancialReport.db.findById(
                  session,
                  prior.id!,
                ))!.toJson(),
                (await FinancialFact.db.findById(session, fact.id!))!.toJson(),
              ], before);
              if (publicAttempt == 3) {
                final beforeTarget = [
                  stored.toJson(),
                  main.toJson(),
                  ...facts.map((x) => x.toJson()),
                ];
                final nextJob = await IngestJob.db.insertRow(
                  session,
                  IngestJob(
                    kind: FinancialFactsSync.kind,
                    status: IngestStatus.running,
                    startedAt: now,
                  ),
                );
                await FinancialFactsSync(
                  session,
                  reader,
                  nextJob.id!,
                  dailyBudget: 0,
                  clock: () => now,
                  callInterval: Duration.zero,
                ).run();
                expect(
                  (await IngestJob.db.findById(session, nextJob.id!))!.updated,
                  0,
                );
                expect(
                  reader.requested.any((x) => x.startsWith('$receipt:')),
                  false,
                );
                final again = await FinancialFact.db.find(
                  session,
                  where: (t) => t.reportId.equals(stored.id!),
                );
                expect([
                  (await FinancialReport.db.findById(
                    session,
                    stored.id!,
                  ))!.toJson(),
                  (await Source.db.findById(session, main.id!))!.toJson(),
                  ...again.map((x) => x.toJson()),
                ], beforeTarget);
              }
            },
          );
        }
      }
    }
  });
}
