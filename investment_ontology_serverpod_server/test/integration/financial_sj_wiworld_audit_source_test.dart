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

class SjWiworldAuditClient extends SourceClient {
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
      p['statement']['url']: File('$dir/ofs.html').readAsBytesSync(),
    };
    final noneDir = 'test/fixtures/financial_html/sj-wiworld-cfs-none/$receipt';
    final none = jsonDecode(File('$noneDir/proof.json').readAsStringSync());
    files[none['url']] = File('$noneDir/cfs.html').readAsBytesSync();
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
  withServerpod('New audit immutable public cap3', (builder, endpoints) {
    for (final (receipt, publicAttempt) in [
      for (final r in ['20260326000605', '20240320000531'])
        for (final a in [2, 3]) (r, a),
    ]) {
      test(
        '$receipt public$publicAttempt exact audit preserves CFS noData/API0',
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
              name: receipt == '20260326000605' ? '주식회사 에스제이켐' : '위월드(주)',
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
              consolidatedStatus: FilingFetchStatus.noData,
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
          final reader = SjWiworldAuditClient();
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
            publicAttempt == 3 ? isEmpty : hasLength(2),
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
          expect(facts.length, inInclusiveRange(7, 8));
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
          final absenceSources = await Source.db.find(
            session,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:$receipt:consolidated',
            ),
          );
          expect(absenceSources, hasLength(publicAttempt == 2 ? 1 : 0));
          if (publicAttempt == 2) {
            final none = jsonDecode(
              File(
                'test/fixtures/financial_html/sj-wiworld-cfs-none/$receipt/proof.json',
              ).readAsStringSync(),
            );
            expect(absenceSources.single.url, none['url']);
            final absencePayload = jsonDecode(absenceSources.single.title);
            expect(absencePayload['receipt'], receipt);
            expect(absencePayload['corpCode'], company.corpCode);
            expect(absencePayload['evidence'], contains('해당사항 없습니다.'));
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
              receipt == '20260326000605' ? '10322963927' : '4621610123',
            ),
          );
          expect((await DartFiling.db.findById(session, f.id!))!.attempts, 3);
          expect(
            (await DartFiling.db.findById(session, f.id!))!.consolidatedStatus,
            FilingFetchStatus.noData,
          );
          expect(
            (await DartFiling.db.findById(session, f.id!))!.separateStatus,
            FilingFetchStatus.stored,
          );
          expect(
            await FinancialReport.db.find(
              session,
              where: (t) =>
                  t.companyId.equals(company.id!) & t.fsDiv.equals(opposite),
            ),
            isEmpty,
          );
        },
      );
    }
  });
}
