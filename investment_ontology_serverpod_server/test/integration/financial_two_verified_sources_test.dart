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

class TwoVerifiedClient extends SourceClient {
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
    final dir = 'assets/financial_source_cache/$receipt-ofs';
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final files = <String, List<int>>{
      for (final row in manifest['sources'])
        row['url']: File('$dir/${row['file']}').readAsBytesSync(),
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
  withServerpod('Two exact verified OFS sources', (builder, endpoints) {
    for (final receipt in ['20260316001455', '20260326000677']) {
      test(
        '$receipt exact actual audit normal queue preserves opposite basis/API0',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final manifest = jsonDecode(
            File('assets/financial_source_cache/$receipt-ofs/manifest.json')
                .readAsStringSync(),
          );
          final p = <String, dynamic>{
            'corp': manifest['corpCode'],
            'cover': manifest['sources'][1],
            'statement': manifest['sources'][2],
          };
          const year = 2025;
          const div = FsDiv.separate, opposite = FsDiv.consolidated;
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
              name: receipt == '20260316001455' ? '(주)유니포인트' : '주식회사 인터로이드',
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
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.failed,
              lastError: 'api-noData-annual-public:attempt=2; Annual current statement title period mismatch',
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
          final reader = TwoVerifiedClient();
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(reader.requested.first, '$receipt:OFS');
          expect(reader.calls, 0);
          final stored = (await FinancialReport.db.find(
            session,
            where: (t) => t.companyId.equals(company.id!) & t.fsDiv.equals(div),
          )).single;
          final main = (await Source.db.findById(session, stored.sourceId))!;
          expect(main.reference, receipt);
          expect(main.url, p['statement']['url']);
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(stored.id!),
          );
          expect(facts, hasLength(8));
          expect(stored.bsnsYear, 2025);
          expect(stored.reportCode, FinancialReportCode.annual);
          expect(stored.rceptNo, receipt);
          expect(stored.fsDiv, FsDiv.separate);
          expect((await IngestJob.db.findById(session, job.id!))!.updated, 1);
          final expected = receipt == '20260316001455'
              ? [
                  '30658218171',
                  '22187300441',
                  '8470917730',
                  '58346049641',
                  '477150486',
                  '456873526',
                  '-2086436454',
                  '-158917918',
                ]
              : [
                  '6812414726',
                  '8475275678',
                  '-1662860952',
                  '4178096900',
                  '-990580404',
                  '-5990157377',
                  '-746421684',
                  '-7561500',
                ];
          expect(
            facts.map((f) => f.amount.toString()),
            unorderedEquals(expected),
          );

          expect(
            facts.every((x) => x.accountId == null && x.sourceId == main.id),
            true,
          );
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:$receipt:separate',
            ),
          );
          expect(audits, hasLength(1));
          final payload = jsonDecode(audits.single.title);
          for (final row in payload['coreRowProvenance']) {
            expect(
              row['html_provenance']['source'],
              p['statement']['url'],
            );
            expect(row['html_provenance']['periodStart'], '2025-01-01');
            expect(row['html_provenance']['periodEnd'], '2025-12-31');
            expect(row['html_provenance']['basis'], 'OFS');
            expect(row['html_provenance']['unit'], '원');
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
              receipt == '20260316001455' ? '58346049641' : '4178096900',
            ),
          );
          expect((await DartFiling.db.findById(session, f.id!))!.attempts, 3);
          expect(
            (await DartFiling.db.findById(session, f.id!))!.lastError,
            contains('attempt=3'),
          );
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          expect(
            (await DartFiling.db.findById(session, f.id!))!.consolidatedStatus,
            FilingFetchStatus.stored,
          );
          expect(
            (await DartFiling.db.findById(session, f.id!))!.separateStatus,
            FilingFetchStatus.stored,
          );
          expect([
            (await Source.db.findById(session, source.id!))!.toJson(),
            (await FinancialReport.db.findById(session, prior.id!))!.toJson(),
            (await FinancialFact.db.findById(session, fact.id!))!.toJson(),
          ], before);
        },
      );
    }
  });
}
