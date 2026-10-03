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

class ProtiaClient extends SourceClient {
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
    final dir = 'assets/financial_source_cache/20230320000571-ofs';
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
      p['overview']['url']: File('$dir/overview.html').readAsBytesSync(),
      p['statement']['url']: File('$dir/${consolidated ? 'cfs' : 'ofs'}.html')
          .readAsBytesSync(),
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
  withServerpod('Protia printed current period public/cache', (
    builder,
    endpoints,
  ) {
    for (final publicAttempt in [2, 3]) {
      const receipt = '20230320000571';
      test(
        'Protia public $publicAttempt normal queue/replay preserves opposite basis/API0',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          final dir = 'assets/financial_source_cache/20230320000571-ofs';
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
              name: '주식회사 프로티아',
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
              consolidatedStatus: c
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              separateStatus: c
                  ? FilingFetchStatus.stored
                  : FilingFetchStatus.failed,
              lastError:
                  'api-noData-annual-public:attempt=$publicAttempt; Annual primary statement title mismatch',
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
          final reader = ProtiaClient();
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(
            reader.requested.where((r) => r.startsWith('$receipt:')),
            publicAttempt == 3 ? isEmpty : hasLength(1),
          );
          expect(
            reader.requested.where((r) => r.startsWith('20260930')),
            hasLength(12),
          );
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
            final proof = row['html_provenance']['supportingPeriodEvidence'];
            expect(proof['source'], p['statement']['url']);
            expect(proof['numericTermSynthesized'], false);
            expect(proof['sourceSha256'], p['statement']['sha256']);
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
            BigInt.parse('7644000304'),
          );
          expect((await DartFiling.db.findById(session, f.id!))!.attempts, 3);
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
