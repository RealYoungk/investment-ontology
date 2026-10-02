import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/public_issuer_a1_first_declaration_test.dart' as fixtures;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class A1DirectIssuerSourceClient extends SourceClient {
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
    if (consolidated || receipt != '20260316001360') {
      throw const FormatException('Unverified basis/source');
    }
    final dir = fixtures.directory;
    final proof = jsonDecode(File('$dir/proof.json').readAsStringSync());
    Uri uri(String label) => Uri.parse(
      (proof['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final cover = File('$dir/cover.html').readAsStringSync();
    final body = File('$dir/ofs.html').readAsStringSync();
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: cover,
      statementHtml: body,
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      periodStart: DateTime.utc(bsnsYear),
      periodEnd: periodEnd,
      issuerProof: fixtures.proof(),
      rows: PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: body,
        coverSource: uri('cover'),
        statementSource: uri('ofs'),
        receipt: receipt,
        corpCode: corpCode,
        companyName: companyName,
        periodStart: DateTime.utc(bsnsYear),
        periodEnd: periodEnd,
        consolidated: false,
        issuerProof: fixtures.proof(),
      ),
    );
  }
}

void main() {
  withServerpod('A1 first direct naming OFS queue', (builder, endpoints) {
    test('exact A1 OFS precedes generic ten without resetting attempts and preserves current issuer', () async {
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
      Map<String, dynamic>? sentinel;
      int? sentinelId;
      for (var i = 0; i < 11; i++) {
        final actual = i >= 10;
        final receipt = actual
            ? '20260316001360'
            : '20260930${i.toString().padLeft(6, '0')}';
        final corp = actual
            ? fixtures.meta()['corpCode'] as String
            : '8${i.toString().padLeft(7, '0')}';
        final year = actual ? fixtures.meta()['bsnsYear'] as int : 2025;
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: actual
                ? fixtures.meta()['companyName'] as String
                : 'Generic $i',
            stockCode: i.toString().padLeft(6, '0'),
            market: Market.konex,
            fiscalMonth: 12,
          ),
        );
        if (actual) {
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: 'existing CFS sentinel',
              url: fixtures.uri('ofs').toString(),
              reference: receipt,
              retrievedAt: now,
            ),
          );
          final report = await FinancialReport.db.insertRow(
            session,
            FinancialReport(
              companyId: company.id!,
              fsDiv: FsDiv.consolidated,
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
              reportId: report.id!,
              fsDiv: FsDiv.consolidated,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              statement: FinancialStatementKind.balanceSheet,
              accountId: 'ifrs-full_Assets',
              accountName: 'existing CFS',
              amount: BigInt.from(123),
              sourceId: source.id!,
            ),
          );
          sentinel = fact.toJson();
          sentinelId = fact.id;
        }
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id,
            corpCode: corp,
            rceptNo: receipt,
            reportName: actual ? '[첨부추가]사업보고서 ($year.12)' : '사업보고서 ($year.12)',
            bsnsYear: year,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: actual
                ? FilingFetchStatus.stored
                : FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            discoveredAt: now,
            attempts: 3,
            lastError: 'api-noData-annual-public:attempt=2; previous failure',
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
      final reader = A1DirectIssuerSourceClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.requested.first, '20260316001360:OFS');
      final reports = await FinancialReport.db.find(
        session,
        where: (t) => t.fsDiv.equals(FsDiv.separate),
      );
      expect(reports, hasLength(1));
      for (final report in reports) {
        expect(report.fsDiv, FsDiv.separate);
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.kind, SourceKind.dartReport);
        expect(source.reference, report.rceptNo);
        expect(source.url, contains('rcpNo=${report.rceptNo}'));
        final reviewed = jsonDecode(
          File('${fixtures.directory}/reviewed-core.json').readAsStringSync(),
        ) as List;
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        );
        expect(facts.length, reviewed.length);
        for (final row in reviewed) {
          final fact = facts.singleWhere(
            (f) => f.amount == BigInt.parse(row['thstrm_amount']),
          );
          expect(fact.amount, BigInt.parse(row['thstrm_amount']));
          expect(
            fact.accountName.replaceAll(RegExp(r'\s+'), ''),
            (row['account_nm'] as String).replaceAll(RegExp(r'\s+'), ''),
          );
          expect(fact.accountId, isNull);
          expect(fact.sourceId, source.id);
        }
        final audits = await Source.db.find(
          session,
          where: (t) => t.reference.equals(
            'financial-api-noData-source:${report.rceptNo}:separate',
          ),
        );
        expect(audits, hasLength(1));
        final payload = jsonDecode(audits.single.title);
        final provenance = payload['coreRowProvenance'] as List;
        for (final row in provenance) {
          final identity = row['html_provenance']['historicalCompanyIdentity'];
          expect(identity['receipt'], report.rceptNo);
          expect(
            identity['corpCode'],
            fixtures.meta()['corpCode'],
          );
          expect(
            identity['legalNameEvidenceSource'],
            fixtures.uri('overview').toString(),
          );
        }
        final company = (await Company.db.findById(session, report.companyId))!;
        final summary = (await FinancialEndpoint().summary(
          session,
          company.corpCode,
          fsDiv: FsDiv.separate,
        ))!;
        final revenue = reviewed[3]['thstrm_amount'];
        expect(
          summary.periods.single.lines
              .singleWhere((l) => l.key == 'revenue')
              .amount,
          BigInt.parse(revenue),
        );
        final mapped = await session.db.unsafeQuery(
          'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
        );
        expect(mapped.where((r) => r[0] != null).length, facts.length);
      }
      final target = (await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.equals('20260316001360'),
      )).single;
      expect(target.attempts, 3);
      expect(target.consolidatedStatus, FilingFetchStatus.stored);
      expect(target.separateStatus, FilingFetchStatus.stored);
      expect(
        (await Company.db.findById(session, target.companyId!))!.name,
        '주식회사 에이원큐브텍',
      );
      expect(
        (await FinancialFact.db.findById(session, sentinelId!))!.toJson(),
        sentinel,
      );
      expect(reader.calls, 0);
    });
  });
}
