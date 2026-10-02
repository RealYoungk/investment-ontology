import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import '../unit/public_financial_html_rootloc_year_term_test.dart' as rootloc;
import '../unit/public_financial_html_bioten_current_source_test.dart'
    as bioten;
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

const cases = [
  (
    '20260323000661',
    '01262023',
    '(주)루트락',
    'OFS',
    'test/fixtures/financial_html/rootloc-year-term',
  ),
  (
    '20260323000763',
    '01119651',
    '(주)엘리비젼',
    'CFS',
    'test/fixtures/financial_html/elivision-cfs-none/20260323000763',
  ),
  (
    '20260323000876',
    '01352575',
    '바이오텐(주)',
    'OFS',
    'test/fixtures/financial_html/bioten-current-source',
  ),
];

class ThreeSourceClient extends SourceClient {
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
    final matching = cases
        .where((c) => c.$1 == receipt && (consolidated ? 'CFS' : 'OFS') == c.$4)
        .toList();
    if (matching.length != 1) {
      throw const FormatException('Unverified generic fixture');
    }
    final c = matching.single;
    final proof = jsonDecode(File('${c.$5}/proof.json').readAsStringSync());
    return PublicFinancialHtmlFetcher(
      MockClient((request) async {
        publicUris.add(request.url);
        final source = (proof['sources'] as List).singleWhere(
          (s) => Uri.parse(s['url']) == request.url,
        );
        return http.Response.bytes(
          File('${c.$5}/${source['label']}.html').readAsBytesSync(),
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
  withServerpod('Three exact current sources actual queue', (
    builder,
    endpoints,
  ) {
    test('verified sources precede generic ten, typed CFS none preserves existing public OFS snapshot', () async {
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
            lastError: 'api-noData-annual-public:attempt=1; prior failure',
            discoveredAt: now,
          ),
        );
      }
      final companies = <Company>[];
      final targets = <DartFiling>[];
      Source? oldSource;
      FinancialReport? oldReport;
      final oldFacts = <FinancialFact>[];
      for (final c in cases) {
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: c.$2,
            name: c.$3,
            stockCode: '${companies.length + 1}'.padLeft(6, '0'),
            fiscalMonth: 12,
            market: Market.konex,
          ),
        );
        companies.add(company);
        if (c.$4 == 'CFS') {
          // Public DTO only; private DB payload was not exported. Isolated IDs are regenerated.
          final snap = jsonDecode(
            File('${c.$5}/stored-ofs-public-dto.json').readAsStringSync(),
          );
          oldSource = await Source.db.insertRow(
            session,
            Source.fromJson(Map<String, dynamic>.from(snap['source']))
                .copyWith(id: null),
          );
          oldReport = await FinancialReport.db.insertRow(
            session,
            FinancialReport.fromJson(Map<String, dynamic>.from(snap['report']))
                .copyWith(
                  id: null,
                  companyId: company.id!,
                  sourceId: oldSource.id!,
                ),
          );
          for (final f in snap['facts']) {
            oldFacts.add(
              await FinancialFact.db.insertRow(
                session,
                FinancialFact.fromJson(Map<String, dynamic>.from(f)).copyWith(
                  id: null,
                  companyId: company.id!,
                  reportId: oldReport.id!,
                  sourceId: oldSource.id!,
                ),
              ),
            );
          }
        }
        targets.add(
          await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: c.$2,
              rceptNo: c.$1,
              reportName: '사업보고서 (2025.12)',
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: c.$4 == 'CFS'
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.noData,
              separateStatus: c.$4 == 'OFS'
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              attempts: 3,
              lastError: 'api-noData-annual-public:attempt=2; title mismatch',
              discoveredAt: now,
            ),
          ),
        );
      }
      final beforeSource = oldSource!.toJson(),
          beforeReport = oldReport!.toJson(),
          beforeFacts = [for (final f in oldFacts) f.toJson()];
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final reader = ThreeSourceClient();
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      final firstGeneric = reader.requested.indexWhere(
        (r) => r.startsWith('20260930'),
      );
      expect(firstGeneric, greaterThanOrEqualTo(5));
      final verifiedRequests = {for (final c in cases) '${c.$1}:${c.$4}'};
      expect(
        reader.requested
            .take(firstGeneric)
            .where(verifiedRequests.contains)
            .toSet(),
        verifiedRequests,
      );
      expect(reader.publicUris.length, 9);
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final ledger = (await DartFiling.db.findById(session, targets[i].id!))!;
        expect(ledger.attempts, c.$4 == 'CFS' ? 3 : 4); // Unverified opposite-basis failure increments the existing general counter; no reset.
        expect(
          ledger.lastError,
          contains('api-noData-annual-public:attempt=3;'),
        );
        expect(
          reader.requested.where((r) => r.startsWith('${c.$1}:')).toList(),
          c.$4 == 'CFS' ? ['${c.$1}:CFS'] : ['${c.$1}:CFS', '${c.$1}:OFS'],
        );
        final rawSha = sha256
            .convert(
              utf8.encode(
                '${File('${c.$5}/cover.html').readAsStringSync()}\n${File('${c.$5}/${c.$4.toLowerCase()}.html').readAsStringSync()}',
              ),
            )
            .toString();
        if (c.$4 == 'CFS') {
          expect(ledger.consolidatedStatus, FilingFetchStatus.noData);
          expect(ledger.separateStatus, FilingFetchStatus.stored);
          final audit = (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:${c.$1}:consolidated',
            ),
          ))!;
          final payload = jsonDecode(audit.title);
          expect(payload['corpCode'], c.$2);
          expect(payload['receipt'], c.$1);
          expect(payload['sha256'], rawSha);
          expect(payload['periodStart'], '2025-01-01T00:00:00.000Z');
          expect(payload['periodEnd'], '2025-12-31T00:00:00.000Z');
          expect(audit.url, contains('eleId=19'));
          expect(payload.toString(), contains('해당 사항 없음'));
          expect(
            await FinancialReport.db.find(
              session,
              where: (t) =>
                  t.companyId.equals(companies[i].id!) &
                  t.fsDiv.equals(FsDiv.consolidated),
            ),
            isEmpty,
          );
        } else {
          // API noData alone is not verified CFS absence; its unverified source failure stays visible.
          expect(ledger.consolidatedStatus, FilingFetchStatus.failed);
          expect(ledger.separateStatus, FilingFetchStatus.stored);
          final report = (await FinancialReport.db.find(
            session,
            where: (t) =>
                t.companyId.equals(companies[i].id!) &
                t.fsDiv.equals(FsDiv.separate),
          )).single;
          final expected = i == 0 ? rootloc.parse() : bioten.parse();
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.reportId.equals(report.id!),
          );
          expect(facts.length, expected.length);
          for (final row in expected) {
            final fact = facts.singleWhere(
              (f) => f.accountName == row['account_nm'],
            );
            expect(fact.amount, BigInt.parse(row['thstrm_amount']));
            expect(fact.accountId, null);
            expect(fact.currency, 'KRW');
          }
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(source.reference, c.$1);
          expect(source.title, contains('SHA256:$rawSha'));
          final audit = (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-api-noData-source:${c.$1}:separate',
            ),
          ))!;
          final auditPayload = jsonDecode(audit.title);
          expect(auditPayload['sourceReceipt'], c.$1);
          expect(auditPayload['coreRows'], expected.length);
          expect(auditPayload['format'], 'html');
          if (i == 0) {
            for (final row in auditPayload['coreRowProvenance']) {
              final proof = row['html_provenance']['supportingPeriodEvidence'];
              expect(proof['totalColumn'], 7);
              expect(proof['currentProfit'], '-2388887000');
              expect(proof['closingEquity'], '-3458950000');
            }
          }
          expect(
            source.url,
            (i == 0 ? rootloc.uri('ofs') : bioten.uri('ofs')).toString(),
          );
          final summary = (await FinancialEndpoint().summary(
            session,
            c.$2,
            fsDiv: FsDiv.separate,
          ))!;
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == 'netIncome')
                .amount,
            BigInt.parse(i == 0 ? '-2388887000' : '-831038793'),
          );
          expect(
            summary.periods.single.lines
                .singleWhere((l) => l.key == 'equity')
                .amount,
            BigInt.parse(i == 0 ? '-3458950000' : '2002580461'),
          );
          final sql = await session.db.unsafeQuery(
            'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
          );
          expect(sql.where((r) => r[0] != null).length, expected.length);
        }
      }
      expect(
        (await Source.db.findById(session, oldSource.id!))!.toJson(),
        beforeSource,
      );
      expect(
        (await FinancialReport.db.findById(session, oldReport.id!))!.toJson(),
        beforeReport,
      );
      for (var i = 0; i < oldFacts.length; i++) {
        expect(
          (await FinancialFact.db.findById(session, oldFacts[i].id!))!.toJson(),
          beforeFacts[i],
        );
      }
      expect(reader.calls, 0);
      expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
    });
  });
}
