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

class InnovexAuditClient extends SourceClient {
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
    return PublicFinancialHtmlFetcher(
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
    const receipt = '20260331004637';
    for (final publicAttempt in [3]) {
      test(
        '$receipt public$publicAttempt exact queue/cache preserves opposite basis/API0',
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
            'statement': (manifest['sources'] as List).singleWhere(
              (x) => x['label'] == 'ofs',
            ),
          };
          const year = 2025;
          const div = FsDiv.separate;
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
              name: '(주)이노벡스',
              stockCode: '111111',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
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
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              lastError:
                  'api-noData-annual-public:attempt=$publicAttempt; Annual primary core missing or balance mismatch',
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
          final reader = InnovexAuditClient();
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          if (publicAttempt == 2) {
            expect(reader.requested.first, '$receipt:OFS');
          } else {
            expect(reader.requested, isNot(contains('$receipt:OFS')));
          }
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
          // Only the numeric OFS report increments updated; CFS is verified absence.
          expect((await IngestJob.db.findById(session, job.id!))!.updated, 1);
          final expected = [
            "8360130649",
            "18944344124",
            "-10584213475",
            "6404028445",
            "-8534577157",
            "-8971893917",
            "-817842378",
            "-11316001",
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
          {
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
              '6404028445',
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
            FilingFetchStatus.noData,
          );
          expect(
            (await DartFiling.db.findById(session, f.id!))!.separateStatus,
            FilingFetchStatus.stored,
          );
          expect(
            (await DartFiling.db.findById(session, f.id!))!.consolidatedStatus,
            FilingFetchStatus.noData,
          );
          expect(
            await FinancialReport.db.find(
              session,
              where: (t) =>
                  t.companyId.equals(company.id!) &
                  t.fsDiv.equals(FsDiv.consolidated),
            ),
            isEmpty,
          );
        },
      );
    }
  });
}
