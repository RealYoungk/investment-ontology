import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../unit/public_issuer_two_grammars_test.dart' as legal;

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class QueueClient extends SourceClient {
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
    if (consolidated ||
        !{
          '20250321001900',
          '20260323001652',
          '20260331003389',
          '20260330001331',
          '20260319001111',
        }.contains(receipt)) {
      throw const FormatException('Unverified queue source');
    }
    if ({'20260330001331', '20260319001111'}.contains(receipt)) {
      return fastFinancialHtmlFetcher(
        MockClient((request) async {
          final label = [
            'shell',
            'cover',
            'overview',
            'ofs',
          ].singleWhere((n) => legal.uri(receipt, n) == request.url);
          return http.Response.bytes(
            utf8.encode(legal.raw(receipt, label)),
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
        consolidated: false,
      );
    }
    final pim = receipt == '20250321001900';
    final dir =
        'test/fixtures/financial_html/${pim
            ? 'pim-term-year'
            : receipt == '20260331003389'
            ? 'daeju-current'
            : 'talos-current'}';
    final proof = jsonDecode(File('$dir/proof.json').readAsStringSync());
    Uri uri(String label) => Uri.parse(
      pim
          ? proof['nodes'][label == 'cover' ? '사업보고서' : '4.재무제표']
          : (proof['sources'] as List).singleWhere(
              (s) => s['label'] == label,
            )['url'],
    );
    final cover = File('$dir/cover.html').readAsStringSync();
    final body = File('$dir/ofs.html').readAsStringSync();
    final start = DateTime.utc(bsnsYear);
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: cover,
      statementHtml: body,
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      periodStart: start,
      periodEnd: periodEnd,
      rows: PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: body,
        coverSource: uri('cover'),
        statementSource: uri('ofs'),
        receipt: receipt,
        corpCode: corpCode,
        companyName: companyName,
        periodStart: start,
        periodEnd: periodEnd,
        consolidated: false,
      ),
    );
  }
}

void main() {
  withServerpod('Verified source queue dispatch', (builder, endpoints) {
    test('late five verified exact OFS sources beat ten generic newer failures', () async {
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
      for (final i in List.generate(15, (i) => i)) {
        final actual = i >= 10;
        final receipt = i == 14
            ? '20260319001111'
            : i == 13
            ? '20260330001331'
            : i == 12
            ? '20260331003389'
            : i == 10
            ? '20250321001900'
            : i == 11
            ? '20260323001652'
            : '20260930${i.toString().padLeft(6, '0')}';
        final corp = i == 14
            ? '01188730'
            : i == 13
            ? '01118643'
            : i == 12
            ? '00414540'
            : i == 10
            ? '00765897'
            : i == 11
            ? '01020269'
            : '8${i.toString().padLeft(7, '0')}';
        final year = i == 10 ? 2024 : 2025;
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: i == 14
                ? 'SK시그넷'
                : i == 13
                ? '솔루믹스'
                : i == 12
                ? '대주이엔티(주)'
                : i == 10
                ? '한국피아이엠'
                : i == 11
                ? '(주) 탈로스'
                : 'Generic $i',
            stockCode: i.toString().padLeft(6, '0'),
            market: Market.konex,
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id,
            corpCode: corp,
            rceptNo: receipt,
            reportName: '사업보고서 ($year.12)',
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: actual
                ? FilingFetchStatus.noData
                : FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            discoveredAt: now,
            lastError: 'api-noData-annual-public:attempt=1; previous failure',
          ),
        );
      }
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = QueueClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.take(10).toSet(), {
        '20260330001331:CFS',
        '20260330001331:OFS',
        '20260319001111:CFS',
        '20260319001111:OFS',
        '20260331003389:CFS',
        '20260331003389:OFS',
        '20250321001900:CFS',
        '20260323001652:CFS',
        '20250321001900:OFS',
        '20260323001652:OFS',
      });
      expect(
        reader.requested.length,
        20,
      ); // Five verified periods + five failed CFS/OFS periods.
      final reports = await FinancialReport.db.find(session);
      expect(reports.length, 5);
      for (final r in reports) {
        final source = (await Source.db.findById(session, r.sourceId))!;
        expect(source.reference, r.rceptNo);
        expect(source.title, contains('HTML 부분 핵심계정'));
        expect(source.title, contains('SHA256:'));
        expect(source.url, contains('rcpNo=${r.rceptNo}'));
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(r.id!),
        );
        expect(facts.length, greaterThanOrEqualTo(7));
        final company = (await Company.db.findById(session, r.companyId))!;
        final expected = await QueueClient().fetchAnnualHtml(
          r.rceptNo,
          reportName: r.reportName,
          corpCode: company.corpCode,
          companyName: company.name,
          bsnsYear: r.bsnsYear,
          periodEnd: DateTime.utc(r.bsnsYear, 12, 31),
          consolidated: false,
        );
        expect(facts.length, expected.rows.length);
        for (final row in expected.rows) {
          final fact = facts.singleWhere(
            (f) => f.accountName == row['account_nm'],
          );
          expect(fact.amount, BigInt.parse(row['thstrm_amount'] as String));
          expect(fact.currency, 'KRW');
        }

        expect(
          facts.every((f) => f.accountId == null && f.sourceId == source.id),
          true,
        );
        final sql = await session.db.unsafeQuery(
          'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${r.id}',
        );
        expect(sql.where((r) => r[0] != null).length, facts.length);
      }
      final summary = (await FinancialEndpoint().summary(
        session,
        '01020269',
        fsDiv: FsDiv.separate,
      ))!;
      expect(
        summary.periods.single.lines
            .singleWhere((l) => l.key == 'revenue')
            .amount,
        BigInt.from(14548416242),
      );
      expect(reader.calls, 0);
    });
    test('unsupported basis and wrong-corp receipts cannot fall through to legacy priority', () async {
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
      for (final i in List.generate(12, (i) => i)) {
        final actual = i >= 10;
        final receipt = i == 10
            ? '20250319000677'
            : i == 11
            ? '20260323001652'
            : '20260930${i.toString().padLeft(6, '0')}';
        final corp = i == 10
            ? '01187458'
            : i == 11
            ? '77777772'
            : '8${i.toString().padLeft(7, '0')}';
        final year = i == 10 ? 2024 : 2025;
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: i == 10
                ? '한국피아이엠'
                : i == 11
                ? '(주) 탈로스'
                : 'Generic $i',
            stockCode: i.toString().padLeft(6, '0'),
            market: Market.konex,
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id,
            corpCode: corp,
            rceptNo: receipt,
            reportName: '사업보고서 ($year.12)',
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: actual
                ? FilingFetchStatus.noData
                : FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            discoveredAt: now,
            lastError: 'api-noData-annual-public:attempt=1; previous failure',
          ),
        );
      }
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = QueueClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(
        reader.requested.any(
          (r) =>
              r.startsWith('20250319000677:') ||
              r.startsWith('20260323001652:'),
        ),
        false,
      );
      expect(await FinancialReport.db.count(session), 0);
      expect(
        reader.requested.length,
        12,
      ); // six generic failure circuit, no fixture priority.
      expect(reader.calls, 0);
    });
  });
}
