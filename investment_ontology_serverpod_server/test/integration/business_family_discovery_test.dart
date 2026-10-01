import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';

import '../unit/public_business_family_discovery_test.dart'
    show familyFixture, familyClient;
import 'auth_test_sessions.dart';
import 'disclosure_sync_test.dart' show FakeDisclosures;
import 'test_tools/serverpod_test_tools.dart';

class FamilyBody extends PublicBusinessDocument {
  FamilyBody(String key, this.target)
    : super(
        client: MockClient(
          (r) async => http.Response.bytes(
            utf8.encode(
              familyFixture(
                key,
                r.url.path == '/dsaf001/main.do' ? 'shell' : 'business',
              ),
            ),
            200,
            request: r,
          ),
        ),
      );
  final String target;
  final calls = <String>[];
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    calls.add(receipt);
    if (receipt == target) throw const PublicBusinessNodeMissing();
    return super.fetch(receipt);
  }
}

void main() {
  withServerpod('Official business family discovery', (builder, endpoints) {
    for (final e in [
      ('kbank', '20230331004542', '20230331004538', '01203312', '㈜케이뱅크'),
      ('tilon', '20230323001121', '20230323000812', '00976615', '주식회사 틸론'),
    ]) {
      test('no ledger/no body exact family source stored ${e.$1}', () async {
        final session = builder.asAdmin.build();
        final fake = FakeDisclosures();
        final reader = FamilyBody(e.$1, e.$2);
        try {
          final now = DateTime.utc(2026, 10, 2);
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: e.$4,
              name: e.$5,
              stockCode: '999999',
              market: Market.kosdaq,
            ),
          );
          final target = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: c.id,
              corpCode: c.corpCode,
              rceptNo: e.$2,
              bsnsYear: 2022,
              reportCode: FinancialReportCode.annual,
              reportName: '[첨부정정]사업보고서 (2022.12)',
              discoveredAt: now,
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
            ),
          );
          await DartFilingSection.db.insertRow(
            session,
            DartFilingSection(
              filingId: target.id!,
              companyId: c.id!,
              bsnsYear: 2022,
              section: DartSection.businessContent,
              tier: 2,
              yearRank: 0,
              status: FilingFetchStatus.pending,
              lastError: '사업본문 API 대기: 첨부정정의 공식 이전접수 탐색에 호출 예산 필요',
            ),
          );
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: DisclosureSync.businessKind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          await DisclosureSync(
            session,
            fake.client(),
            job.id!,
            businessOnly: true,
            dailyBudget: 0,
            publicFallbackEnabled: true,
            publicDocuments: reader,
            businessAnchorClientFactory: () => familyClient(e.$1, e.$2),
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(fake.calls, isEmpty);
          expect(reader.calls, [e.$2, e.$3]);
          final filing = (await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(e.$3),
          ))!;
          expect(filing.corpCode, c.corpCode);
          expect(filing.companyId, c.id);
          expect(filing.reportName, '사업보고서 (2022.12)');
          final doc = (await BusinessDocument.db.find(session)).single;
          expect(doc.rceptNo, e.$3);
          expect(doc.charCount, greaterThan(10000));
          final report = (await DisclosureReport.db.findById(
            session,
            doc.reportId,
          ))!;
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(source.url, contains('rcpNo=${e.$3}'));
          final audit = (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'business-source-period-anchor:${e.$3}:${e.$2}',
            ),
          ))!;
          final proof = jsonDecode(audit.title) as Map;
          expect(proof['discovery'], 'official-family-latest-same-kind');
          expect(proof['periodEnd'], '2022-12-31T00:00:00.000Z');
          expect((await IngestJob.db.findById(session, job.id!))!.updated, 1);
        } finally {
          await session.close();
        }
      });
    }
    test('cancel after discovery shell prevents further GET and metadata/body writes', () async {
      final session = builder.asAdmin.build();
      final fake = FakeDisclosures();
      const targetReceipt = '20230331004542';
      final reader = FamilyBody('kbank', targetReceipt);
      var gets = 0;
      try {
        final now = DateTime.utc(2026, 10, 2);
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: '01203312',
            name: '㈜케이뱅크',
            stockCode: '999998',
            market: Market.kosdaq,
          ),
        );
        final f = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: c.id,
            corpCode: c.corpCode,
            rceptNo: targetReceipt,
            bsnsYear: 2022,
            reportCode: FinancialReportCode.annual,
            reportName: '[첨부정정]사업보고서 (2022.12)',
            discoveredAt: now,
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.stored,
          ),
        );
        await DartFilingSection.db.insertRow(
          session,
          DartFilingSection(
            filingId: f.id!,
            companyId: c.id!,
            bsnsYear: 2022,
            section: DartSection.businessContent,
            tier: 2,
            yearRank: 0,
            status: FilingFetchStatus.pending,
            lastError: '사업본문 API 대기: 첨부정정의 공식 이전접수 탐색에 호출 예산 필요',
          ),
        );
        final j = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: DisclosureSync.businessKind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await DisclosureSync(
          session,
          fake.client(),
          j.id!,
          businessOnly: true,
          dailyBudget: 0,
          publicFallbackEnabled: true,
          publicDocuments: reader,
          businessAnchorClientFactory: () => MockClient((request) async {
            gets++;
            await IngestJobs.cancel(session, j.id!);
            return http.Response.bytes(
              utf8.encode(familyFixture('kbank', 'target-shell')),
              200,
              request: request,
            );
          }),
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
        expect(gets, 1);
        expect(reader.calls, isEmpty);
        expect(await BusinessDocument.db.count(session), 0);
        expect(await Source.db.count(session), 0);
        expect(await DartFiling.db.count(session), 1);
        expect(
          (await IngestJob.db.findById(session, j.id!))!.status,
          IngestStatus.cancelled,
        );
        final item = (await DartFilingSection.db.findFirstRow(
          session,
          where: (t) =>
              t.filingId.equals(f.id!) &
              t.section.equals(DartSection.businessContent),
        ))!;
        expect(item.attempts, 0);
        expect(item.status, FilingFetchStatus.pending);
      } finally {
        await session.close();
      }
    });
  });
}
