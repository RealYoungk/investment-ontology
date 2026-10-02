import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/financial_gaia_pandora_labels_test.dart' as actual;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class LabelSourceClient extends SourceClient {
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
    final basis = consolidated ? 'cfs' : 'ofs';
    requested.add('$receipt:$basis');
    if (receipt != '20250331002057' &&
        !(receipt == '20250321001451' && consolidated)) {
      throw const FormatException('Unverified fixture source');
    }
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: actual.raw(receipt, 'cover'),
      statementHtml: actual.raw(receipt, basis),
      coverSource: actual.uri(receipt, 'cover'),
      statementSource: actual.uri(receipt, basis),
      periodStart: DateTime.utc(2024),
      periodEnd: DateTime.utc(2024, 12, 31),
      rows: actual.parse(receipt, basis),
    );
  }
}

void main() {
  withServerpod('Gaia Pandora verified printed labels queue', (
    builder,
    endpoints,
  ) {
    test('late exact source bases precede generic ten and preserve existing Pandora OFS snapshot', () async {
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
      FinancialReport? preservedReport;
      Source? preservedSource;
      List<FinancialFact>? preservedFacts;
      for (var i = 0; i < 12; i++) {
        final gaia = i == 10;
        final pandora = i == 11;
        final corp = gaia
            ? '01229240'
            : pandora
            ? '00541862'
            : '8${i.toString().padLeft(7, '0')}';
        final receipt = gaia
            ? '20250331002057'
            : pandora
            ? '20250321001451'
            : '20260930${i.toString().padLeft(6, '0')}';
        final year = i >= 10 ? 2024 : 2025;
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: gaia
                ? '(주)가이아코퍼레이션'
                : pandora
                ? '(주)판도라티비'
                : 'Generic $i',
            stockCode: i.toString().padLeft(6, '0'),
            market: Market.konex,
            fiscalMonth: 12,
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id,
            corpCode: corp,
            rceptNo: receipt,
            reportName: '사업보고서 ($year.12)',
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: pandora
                ? FilingFetchStatus.stored
                : FilingFetchStatus.failed,
            attempts: 1,
            discoveredAt: now,
            lastError: 'api-noData-annual-public:attempt=1; previous failure',
          ),
        );
        if (pandora) {
          final snap = jsonDecode(
            File('${actual.base}/$receipt/stored-ofs-snapshot.json')
                .readAsStringSync(),
          ) as Map;
          preservedSource = await Source.db.insertRow(
            session,
            Source.fromJson(Map<String, dynamic>.from(snap['source'])),
          );
          final r = Map<String, dynamic>.from(snap['report']);
          r['companyId'] = company.id;
          r['sourceId'] = preservedSource.id;
          preservedReport = await FinancialReport.db.insertRow(
            session,
            FinancialReport.fromJson(r),
          );
          preservedFacts = [];
          for (final f in snap['facts'] as List) {
            final row = Map<String, dynamic>.from(f);
            row['companyId'] = company.id;
            row['reportId'] = preservedReport.id;
            row['sourceId'] = preservedSource.id;
            preservedFacts.add(
              await FinancialFact.db.insertRow(
                session,
                FinancialFact.fromJson(row),
              ),
            );
          }
        }
      }
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = LabelSourceClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.take(3).toSet(), {
        '20250331002057:cfs',
        '20250331002057:ofs',
        '20250321001451:cfs',
      });
      expect(reader.requested, isNot(contains('20250321001451:ofs')));
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(4));
      for (final r in reports.where((r) => r.id != preservedReport!.id)) {
        final source = (await Source.db.findById(session, r.sourceId))!;
        final basis = r.fsDiv == FsDiv.consolidated ? 'cfs' : 'ofs';
        expect(source.kind, SourceKind.dartReport);
        expect(source.reference, r.rceptNo);
        expect(source.url, actual.uri(r.rceptNo, basis).toString());
        final rows = actual.parse(r.rceptNo, basis);
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(r.id!),
        );
        expect(facts.length, rows.length);
        for (final row in rows) {
          final f = facts.singleWhere(
            (f) => f.accountName == row['account_nm'],
          );
          expect(f.amount, BigInt.parse(row['thstrm_amount']));
          expect(f.accountId, isNull);
          expect(f.sourceId, r.sourceId);
        }
        final company = (await Company.db.findById(session, r.companyId))!;
        final summary = (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: r.fsDiv,
        ))!;
        for (final pair in [
          ('revenue', rows[3]['thstrm_amount']),
          ('netIncome', rows[5]['thstrm_amount']),
          ('operatingCashFlow', rows[6]['thstrm_amount']),
        ]) {
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == pair.$1)
                .amount,
            BigInt.parse(pair.$2),
          );
        }
        final mapped = await session.db.unsafeQuery(
          'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${r.id}',
        );
        expect(mapped.where((r) => r[0] != null).length, facts.length);
      }
      expect(
        (await FinancialReport.db.findById(
          session,
          preservedReport!.id!,
        ))!.toJson(),
        preservedReport.toJson(),
      );
      expect(
        (await Source.db.findById(session, preservedSource!.id!))!.toJson(),
        preservedSource.toJson(),
      );
      for (final f in preservedFacts!) {
        expect(
          (await FinancialFact.db.findById(session, f.id!))!.toJson(),
          f.toJson(),
        );
      }
      expect(reader.calls, 0);
    });
  });
}
