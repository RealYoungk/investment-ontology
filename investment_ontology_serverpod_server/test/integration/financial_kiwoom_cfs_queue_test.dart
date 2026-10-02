import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/public_financial_html_kiwoom_cfs_term_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class KiwoomQueueClient extends SourceClient {
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
    if (receipt != '20230320001037' || !consolidated) {
      throw const FormatException('Unverified generic fixture');
    }
    return PublicFinancialHtmlFetcher(
      MockClient((request) async {
        publicUris.add(request.url);
        final label = [
          'shell',
          'cover',
          'cfs',
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
      consolidated: true,
    );
  }
}

void main() {
  withServerpod('Exact Kiwoom CFS priority with existing OFS', (
    builder,
    endpoints,
  ) {
    test('target follows ten generic seeds but fetches CFS first and preserves OFS', () async {
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
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            lastError: 'api-noData-annual-public:attempt=1; previous failure',
            discoveredAt: now,
          ),
        );
      }
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00296290',
          name: '키움증권(주)',
          stockCode: '039490',
          fiscalMonth: 12,
          market: Market.kospi,
        ),
      );
      final snap = jsonDecode(
        File('${actual.root}/stored-ofs-snapshot.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      // Production report115358/Source233799 values are retained; isolated IDs are generated.
      final oldSource = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: snap['source_title'],
          reference: snap['source_reference'],
          url: snap['source_url'],
          retrievedAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      final oldReport = await FinancialReport.db.insertRow(
        session,
        FinancialReport.fromJson(
          snap,
        ).copyWith(id: null, companyId: company.id!, sourceId: oldSource.id!),
      );
      final oldFacts = <FinancialFact>[];
      for (final v in snap['facts']) {
        oldFacts.add(
          await FinancialFact.db.insertRow(
            session,
            FinancialFact.fromJson(Map<String, dynamic>.from(v)).copyWith(
              id: null,
              reportId: oldReport.id!,
              companyId: company.id!,
              sourceId: oldSource.id!,
            ),
          ),
        );
      }
      final sourceBefore = oldSource.toJson();
      final reportBefore = oldReport.toJson();
      final factsBefore = [for (final f in oldFacts) f.toJson()];
      final target = await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: company.id,
          corpCode: company.corpCode,
          rceptNo: '20230320001037',
          reportName: '사업보고서 (2022.12)',
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.stored,
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
      final reader = KiwoomQueueClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.first, '20230320001037:CFS');
      expect(
        reader.requested.where((r) => r.startsWith('20230320001037:')).toList(),
        ['20230320001037:CFS'],
      );
      expect(reader.publicUris.toSet(), {
        actual.uri('shell'),
        actual.uri('cover'),
        actual.uri('cfs'),
      });
      final ledger = (await DartFiling.db.findById(session, target.id!))!;
      expect(ledger.consolidatedStatus, FilingFetchStatus.stored);
      expect(ledger.separateStatus, FilingFetchStatus.stored);
      expect(ledger.attempts, 3);
      expect(ledger.lastError, contains('api-noData-annual-public:attempt=3;'));
      expect(
        (await Source.db.findById(session, oldSource.id!))!.toJson(),
        sourceBefore,
      );
      expect(
        (await FinancialReport.db.findById(session, oldReport.id!))!.toJson(),
        reportBefore,
      );
      for (var i = 0; i < oldFacts.length; i++) {
        expect(
          (await FinancialFact.db.findById(session, oldFacts[i].id!))!.toJson(),
          factsBefore[i],
        );
      }
      final report = (await FinancialReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.fsDiv.equals(FsDiv.consolidated),
      )).single;
      final facts = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(report.id!),
      );
      final expected = actual.parse();
      expect(facts.length, expected.length);
      for (final row in expected) {
        final f = facts.singleWhere((f) => f.accountName == row['account_nm']);
        expect(f.amount, BigInt.parse(row['thstrm_amount'] as String));
        expect(f.accountId, null);
        expect(f.currency, 'KRW');
      }
      final source = (await Source.db.findById(session, report.sourceId))!;
      expect(source.reference, '20230320001037');
      expect(source.url, actual.uri('cfs').toString());
      expect(source.title, contains('SHA256:'));
      final audit = (await Source.db.findFirstRow(
        session,
        where: (t) => t.reference.equals(
          'financial-api-noData-source:20230320001037:consolidated',
        ),
      ))!;
      final payload = jsonDecode(audit.title);
      expect(payload['corpCode'], '00296290');
      expect(payload['sourceReceipt'], '20230320001037');
      expect(payload['coreRows'], expected.length);
      expect(payload['format'], 'html');
      for (final row in payload['coreRowProvenance']) {
        final p = row['html_provenance']['supportingPeriodEvidence'];
        expect(p['totalColumn'], 8);
        expect(p['currentProfit'], '508170326221');
        expect(p['closingEquity'], '4593093934930');
      }

      final summary = (await FinancialEndpoint().summary(
        session,
        company.corpCode,
        fsDiv: FsDiv.consolidated,
      ))!;
      expect(
        summary.periods.single.lines
            .singleWhere((l) => l.key == 'netIncome')
            .amount,
        BigInt.from(508170326221),
      );
      expect(
        summary.periods.single.lines
            .singleWhere((l) => l.key == 'equity')
            .amount,
        BigInt.from(4593093934930),
      );
      final sql = await session.db.unsafeQuery(
        'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
      );
      expect(sql.where((r) => r[0] != null).length, expected.length);
      expect(reader.calls, 0);
      expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
    });
  });
}
