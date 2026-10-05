import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class ThreeAuditClient extends SourceClient {
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
    if (consolidated) {
      final dir = 'test/fixtures/financial_html/three-audit-cfs-proof/$receipt';
      final proof = jsonDecode(File('$dir/proof.json').readAsStringSync());
      final cfs = jsonDecode(File('$dir/cfs-proof.json').readAsStringSync());
      final sources = proof['sources'] as List;
      final files = <String, List<int>>{
        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt': File(
          '$dir/shell.html',
        ).readAsBytesSync(),
        sources.singleWhere((x) => x['label'] == 'cover')['url']: File(
          '$dir/cover.html',
        ).readAsBytesSync(),
        cfs['url']: File('$dir/cfs.html').readAsBytesSync(),
      };
      return fastFinancialHtmlFetcher(
        MockClient((req) async {
          final raw = files[req.url.toString()];
          if (raw == null) throw const FormatException('Unbound CFS source');
          return http.Response.bytes(raw, 200, request: req);
        }),
      ).fetchAnnual(
        receipt,
        reportName: reportName,
        corpCode: corpCode,
        companyName: companyName,
        bsnsYear: bsnsYear,
        periodEnd: periodEnd,
        consolidated: true,
      );
    }
    final dir = 'assets/financial_source_cache/$receipt-ofs-audit';
    if (!File('$dir/manifest.json').existsSync()) {
      throw const FormatException('Unsupported source');
    }
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final p = <String, dynamic>{
      'corp': manifest['corpCode'],
      'year': manifest['year'],
      'basis': manifest['basis'] == 'consolidated' ? 'CFS' : 'OFS',
      for (final source in manifest['sources'])
        source['label'] == 'cfs' || source['label'] == 'ofs'
                ? 'statement'
                : source['label']:
            source,
    };
    final files = <String, List<int>>{
      p['shell']['url']: File('$dir/shell.html').readAsBytesSync(),
      p['cover']['url']: File('$dir/cover.html').readAsBytesSync(),
      p['auditShell']['url']: File('$dir/auditShell.html').readAsBytesSync(),
      p['statement']['url']: File('$dir/${consolidated ? 'cfs' : 'ofs'}.html')
          .readAsBytesSync(),
    };
    return fastFinancialHtmlFetcher(
      MockClient((r) async {
        final b = files[r.url.toString()];
        if (b == null) throw const FormatException('Unbound source');
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
  withServerpod('Same receipt attached audit source', (builder, endpoints) {
    for (final publicAttempt in [2, 3]) {
      for (final receipt in [
        '20250318000507',
        '20250321001749',
        '20250407004206',
      ]) {
        test(
          '$receipt public$publicAttempt exact actual audit normal queue preserves opposite basis/API0',
          () async {
            final session = builder.asAdmin.build(),
                now = DateTime.utc(2026, 10, 2);
            final dir = 'assets/financial_source_cache/$receipt-ofs-audit';
            final manifest = jsonDecode(
              File('$dir/manifest.json').readAsStringSync(),
            );
            final p = <String, dynamic>{
              'corp': manifest['corpCode'],
              'year': manifest['year'],
              'basis': manifest['basis'] == 'consolidated' ? 'CFS' : 'OFS',
              for (final source in manifest['sources'])
                source['label'] == 'cfs' || source['label'] == 'ofs'
                        ? 'statement'
                        : source['label']:
                    source,
            };
            final c = p['basis'] == 'CFS', year = p['year'] as int;
            final div = c ? FsDiv.consolidated : FsDiv.separate;
            final opposite = c ? FsDiv.separate : FsDiv.consolidated;
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
                name: {
                  '20250318000507': '(주)에피바이오텍',
                  '20250321001749': '(주)케이씨산업',
                  '20250407004206': '대주이엔티(주)',
                }[receipt]!,
                stockCode: '111111',
                market: Market.konex,
                fiscalMonth: 12,
              ),
            );
            Source? source;
            FinancialReport? prior;
            FinancialFact? fact;
            List<dynamic>? before;
            if (receipt == '20250407004206') {
              source = await Source.db.insertRow(
                session,
                Source(
                  kind: SourceKind.dartReport,
                  title: 'Preserved opposite basis',
                  url: p['cover']['url'],
                  reference: receipt,
                  retrievedAt: now,
                ),
              );
              prior = await FinancialReport.db.insertRow(
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
              fact = await FinancialFact.db.insertRow(
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
              before = [source.toJson(), prior.toJson(), fact.toJson()];
            }
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
                consolidatedStatus: receipt == '20250407004206'
                    ? FilingFetchStatus.stored
                    : FilingFetchStatus.noData,
                separateStatus: c
                    ? FilingFetchStatus.stored
                    : FilingFetchStatus.failed,
                lastError:
                    'api-noData-annual-public:attempt=$publicAttempt; Annual current statement title period mismatch',
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
            final reader = ThreeAuditClient();
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
                reader.requested
                    .where((r) => r.startsWith('$receipt:'))
                    .toList(),
                receipt == '20250407004206'
                    ? ['$receipt:OFS']
                    : ['$receipt:CFS', '$receipt:OFS'],
              );
            } else {
              expect(
                reader.requested.where((r) => r.startsWith('$receipt:')),
                isEmpty,
              );
            }
            expect(reader.calls, 0);
            final none = await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:$receipt:consolidated',
              ),
            );
            if (receipt != '20250407004206' && publicAttempt == 2) {
              expect(none, hasLength(1));
              final proof = jsonDecode(
                File(
                  'test/fixtures/financial_html/three-audit-cfs-proof/$receipt/cfs-proof.json',
                ).readAsStringSync(),
              );
              expect(none.single.url, proof['url']);
              final payload = jsonDecode(none.single.title);
              expect(payload['corpCode'], p['corp']);
              expect(payload['receipt'], receipt);
              expect(payload['periodStart'], '2024-01-01T00:00:00.000Z');
              expect(payload['periodEnd'], '2024-12-31T00:00:00.000Z');
              expect(
                payload['evidence'],
                receipt == '20250318000507'
                    ? '당사는 연결재무제표 작성대상 법인이 아니므로 해당사항이 없습니다.'
                    : '- 당사는 사업보고서 작성기준일 현재 해당사항 없습니다.',
              );
            } else {
              expect(none, isEmpty);
            }

            expect((await IngestJob.db.findById(session, job.id!))!.updated, 1);
            final stored = (await FinancialReport.db.find(
              session,
              where: (t) =>
                  t.companyId.equals(company.id!) & t.fsDiv.equals(div),
            )).single;
            final main = (await Source.db.findById(session, stored.sourceId))!;
            expect(main.reference, receipt);
            expect(main.url, p['statement']['url']);
            final facts = await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(stored.id!),
            );
            expect(facts.length, greaterThanOrEqualTo(7));
            expect(
              facts.every((x) => x.accountId == null && x.sourceId == main.id),
              true,
            );
            final audits = await Source.db.find(
              session,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:$receipt:${c ? 'consolidated' : 'separate'}',
              ),
            );
            expect(audits, hasLength(1));
            final payload = jsonDecode(audits.single.title);
            for (final row in payload['coreRowProvenance']) {
              final proof = row['html_provenance']['sameReceiptAuditSource'];
              expect(proof['actualStatementSource'], p['statement']['url']);
              expect(proof['mainCoverSource'], p['cover']['url']);
              expect(proof['receipt'], receipt);
              expect(proof['statementSha256'], p['statement']['sha256']);
            }
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
                {
                  '20250318000507': '746739428',
                  '20250321001749': '84322250768',
                  '20250407004206': '85566276888',
                }[receipt]!,
              ),
            );
            expect((await DartFiling.db.findById(session, f.id!))!.attempts, 3);
            expect(
              (await DartFiling.db.findById(
                session,
                f.id!,
              ))!.consolidatedStatus,
              receipt == '20250407004206'
                  ? FilingFetchStatus.stored
                  : FilingFetchStatus.noData,
            );
            expect(
              (await DartFiling.db.findById(session, f.id!))!.separateStatus,
              FilingFetchStatus.stored,
            );
            if (receipt != '20250407004206') {
              expect(
                await FinancialReport.db.find(
                  session,
                  where: (t) =>
                      t.companyId.equals(company.id!) &
                      t.fsDiv.equals(opposite),
                ),
                isEmpty,
              );
            }
            if (receipt == '20250407004206') {
              expect([
                (await Source.db.findById(session, source!.id!))!.toJson(),
                (await FinancialReport.db.findById(
                  session,
                  prior!.id!,
                ))!.toJson(),
                (await FinancialFact.db.findById(session, fact!.id!))!.toJson(),
              ], before);
            }
          },
        );
      }
    }
  });
}
