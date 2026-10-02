import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/public_financial_html_novmeta_heading_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class NovmetaQueueClient extends SourceClient {
  final requested = <String>[];
  final publicUris = <Uri>[];
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
    if (receipt != '20260320000871') {
      throw const FormatException('Unverified generic fixture');
    }
    return PublicFinancialHtmlFetcher(
      MockClient((request) async {
        publicUris.add(request.url);
        final label = [
          'shell',
          'cover',
          consolidated ? 'cfs' : 'ofs',
        ].singleWhere((n) => actual.uri(n) == request.url);
        return http.Response.bytes(
          utf8.encode(actual.raw(label)),
          200,
          request: request,
        );
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
  withServerpod('Exact Novmeta CFS priority with existing OFS', (
    builder,
    endpoints,
  ) {
    for (final numeric in [true, false]) {
      test(
        'numeric=$numeric target follows ten generic seeds but fetches verified basis first and preserves other basis',
        () async {
          final session = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 2);
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          for (var i = 0; i < 10; i++) {
            final c = await Company.db.insertRow(
              session,
              Company(
                corpCode: '8${i.toString().padLeft(7, '0')}',
                name: 'Generic$i',
                stockCode: '8${i.toString().padLeft(5, '0')}',
                fiscalMonth: 12,
                market: Market.konex,
              ),
            );
            await DartFiling.db.insertRow(
              session,
              DartFiling(
                companyId: c.id,
                corpCode: c.corpCode,
                rceptNo: '20260930${i.toString().padLeft(6, '0')}',
                reportName: '사업보고서 (2025.12)',
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                consolidatedStatus: numeric
                    ? FilingFetchStatus.stored
                    : FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.failed,
                lastError:
                    'api-noData-annual-public:attempt=1; previous failure',
                discoveredAt: now,
              ),
            );
          }
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: '01065785',
              name: '(주)노브메타파마',
              stockCode: '309930',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          // Explicit synthetic OFS sentinel: no production database DTO export.
          final oldSource = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'Synthetic opposite-basis preservation sentinel',
              reference: '20260320000871',
              url:
                  'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260320000871',
              retrievedAt: now,
            ),
          );
          final oldReport = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              rceptNo: '20260320000871',
              fsDiv: numeric ? FsDiv.consolidated : FsDiv.separate,
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (2025.12)',
              factCount: 1,
              sourceId: oldSource.id!,
              fetchedAt: now,
            ),
          );
          final oldFacts = <FinancialFact>[
            await FinancialFact.db.insertRow(
              session,
              FinancialFact(
                reportId: oldReport.id!,
                companyId: company.id!,
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                fsDiv: numeric ? FsDiv.consolidated : FsDiv.separate,
                statement: FinancialStatementKind.balanceSheet,
                accountId: 'ifrs-full_Assets',
                accountName: '자산총계',
                amount: BigInt.from(123),
                priorAmount: BigInt.from(100),
                sourceId: oldSource.id!,
              ),
            ),
          ];
          final sourceBefore = oldSource.toJson();
          final reportBefore = oldReport.toJson();
          final factsBefore = [for (final f in oldFacts) f.toJson()];
          final target = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: company.corpCode,
              rceptNo: '20260320000871',
              reportName: '사업보고서 (2025.12)',
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: numeric
                  ? FilingFetchStatus.stored
                  : FilingFetchStatus.failed,
              separateStatus: numeric
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=2; Annual current statement title period mismatch',
              discoveredAt: now,
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
          final reader = NovmetaQueueClient();
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(
            reader.requested.first,
            '20260320000871:${numeric ? 'OFS' : 'CFS'}',
          );
          final done = (await IngestJob.db.findById(session, job.id!))!;
          expect(
            done.updated,
            numeric ? 1 : 0,
            reason: 'Only the new numeric OFS source counts as stored',
          );
          expect(
            reader.requested.map((r) => r.split(':').first).toSet().length,
            lessThanOrEqualTo(10),
            reason: 'The public queue cap is per period; job processed also includes normal reconciliation',
          );
          expect(
            reader.requested
                .where((r) => r.startsWith('20260320000871:'))
                .toList(),
            ['20260320000871:${numeric ? 'OFS' : 'CFS'}'],
          );
          expect(reader.publicUris.toSet(), {
            actual.uri('shell'),
            actual.uri('cover'),
            actual.uri(numeric ? 'ofs' : 'cfs'),
          });
          final ledger = (await DartFiling.db.findById(session, target.id!))!;
          expect(
            ledger.consolidatedStatus,
            numeric ? FilingFetchStatus.stored : FilingFetchStatus.noData,
          );
          expect(ledger.separateStatus, FilingFetchStatus.stored);
          expect(ledger.attempts, 3);
          expect(
            ledger.lastError,
            contains('api-noData-annual-public:attempt=3;'),
          );
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
          if (!numeric) {
            final absent = (await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:20260320000871:consolidated',
              ),
            ))!;
            final evidence = jsonDecode(absent.title);
            expect(evidence['corpCode'], '01065785');
            expect(evidence['receipt'], '20260320000871');
            expect(
              await FinancialReport.db.count(
                session,
                where: (t) =>
                    t.companyId.equals(company.id!) &
                    t.fsDiv.equals(FsDiv.consolidated),
              ),
              0,
            );
            expect(reader.calls, 0);
            expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
            return;
          }
          final report = (await FinancialReport.db.find(
            session,
            where: (t) =>
                t.companyId.equals(company.id!) &
                t.fsDiv.equals(FsDiv.separate),
          )).single;
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(report.id!),
          );
          final expected = actual.parse();
          expect(facts.length, expected.length);
          for (final row in expected) {
            final f = facts.singleWhere(
              (f) => f.accountName == row['account_nm'],
            );
            expect(f.amount, BigInt.parse(row['thstrm_amount'] as String));
            expect(f.accountId, null);
            expect(f.currency, 'KRW');
          }
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(source.reference, '20260320000871');
          expect(source.url, actual.uri('ofs').toString());
          expect(source.title, contains('SHA256:'));
          final audit = (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:20260320000871:separate',
            ),
          ))!;
          final payload = jsonDecode(audit.title);
          expect(payload['corpCode'], '01065785');
          expect(payload['sourceReceipt'], '20260320000871');
          expect(payload['coreRows'], expected.length);
          expect(payload['format'], 'html');
          final summary = (await FinancialEndpoint().summary(
            session,
            company.corpCode,
            fsDiv: FsDiv.separate,
          ))!;
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == 'operatingCashFlow')
                .amount,
            BigInt.from(-3358353147),
          );
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == 'equity')
                .amount,
            BigInt.from(3592612438),
          );
          final sql = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
          );
          expect(sql.where((r) => r[0] != null).length, expected.length);
          expect(reader.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
        },
      );
    }
  });
}
