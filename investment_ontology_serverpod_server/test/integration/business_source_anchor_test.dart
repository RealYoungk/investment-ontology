import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/business_collection_scope.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_collection_scope.dart';

import 'auth_test_sessions.dart';
import 'disclosure_sync_test.dart' show FakeDisclosures;
import 'test_tools/serverpod_test_tools.dart';

class MissingBody extends PublicBusinessDocument {
  @override
  Future<PublicBusinessBody> fetch(String receipt) async =>
      throw const PublicBusinessNodeMissing();
}

void main() {
  withServerpod('Business source metadata registration', (builder, endpoints) {
    late Session session;
    late Company company;
    late DartFiling target;
    late BusinessDocument body;
    late DisclosureReport report;
    late Source source;
    var gets = 0;
    bool malformed = false, wrongSourceCorp = false, badPeriod = false;
    int? activeJob;
    Future<void> Function()? mutate;
    String raw(String f) =>
        File('test/fixtures/business_source_anchor/$f.html').readAsStringSync();
    setUp(() async {
      session = builder.asAdmin.build();
      gets = 0;
      malformed = false;
      wrongSourceCorp = false;
      badPeriod = false;
      mutate = null;
      company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00929228',
          name: '(주)엔에스컴퍼니',
          market: Market.kosdaq,
          stockCode: '000001',
        ),
      );
      target = await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: company.id,
          corpCode: company.corpCode,
          rceptNo: '20260324000715',
          reportName: '[첨부정정]사업보고서 (2025.12)',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.noData,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      source = await Source.db.insertRow(
        session,
        Source(
          title: '기존 원문',
          kind: SourceKind.dartReport,
          reference: '20260323000900',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.businessContent,
          rceptNo: '20260323000900',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      body = await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          companyId: company.id!,
          reportId: report.id!,
          bsnsYear: 2025,
          rceptNo: report.rceptNo,
          title: '사업의 내용',
          text: '회사의 실제 원본문',
          charCount: 11,
        ),
      );
    });
    Future<int> scope() async =>
        (await session.db.unsafeQuery(
              'WITH ${FinancialCollectionScope.cte} SELECT count(*) n FROM financial_scope',
            )).single.toColumnMap()['n']
            as int;
    Future<IngestJob> run() async {
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: DisclosureSync.businessKind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      activeJob = j.id;
      await DisclosureSync(
        session,
        FakeDisclosures().client(),
        j.id!,
        businessOnly: true,
        dailyBudget: 0,
        callInterval: Duration.zero,
        publicDocuments: MissingBody(),
        businessAnchorClientFactory: () => MockClient((r) async {
          gets++;
          String text;
          if (r.url.path == '/report/viewer.do') {
            text = raw('cover');
            if (malformed) text = text.replaceAll('(주)엔에스컴퍼니', '이상규');
            if (badPeriod) text = text.replaceAll('12월 31일', '11월 30일');
            if (mutate != null) {
              final fn = mutate;
              mutate = null;
              await fn!();
            }
          } else {
            text = r.url.queryParameters['rcpNo'] == target.rceptNo
                ? raw('target')
                : raw('source');
            if (wrongSourceCorp &&
                r.url.queryParameters['rcpNo'] != target.rceptNo) {
              text = text.replaceAll('00929228', '00978075');
            }
          }
          return http.Response.bytes(utf8.encode(text), 200, request: r);
        }),
      ).run();
      return (await IngestJob.db.findById(session, j.id!))!;
    }

    test('valid anchor preserves body/provenance; target stored and no duplicate retry', () async {
      final before = await scope();
      await run();
      expect(gets, 3);
      final original = await DartFiling.db.findFirstRow(
        session,
        where: (t) => t.rceptNo.equals(report.rceptNo),
      );
      expect(original!.companyId, company.id);
      expect(original.bsnsYear, 2025);
      expect(original.reportCode, FinancialReportCode.annual);
      final audit = await Source.db.find(
        session,
        where: (t) => t.reference.equals(
          'business-source-period-anchor:20260323000900:20260324000715',
        ),
      );
      expect(audit.length, 1);
      expect(
        (await BusinessDocument.db.findById(session, body.id!))!.text,
        body.text,
      );
      expect(
        (await DisclosureReport.db.findById(session, report.id!))!.sourceId,
        source.id,
      );
      expect(await scope(), before);
      final rows = await session.db.unsafeQuery(
        'WITH ${BusinessCollectionScope.cte} SELECT body_stored FROM business_scope WHERE id=@id',
        parameters: QueryParameters.named({'id': target.id!}),
      );
      expect(rows.single.toColumnMap()['body_stored'], true);
      final ledger = await DartFilingSection.db.findFirstRow(
        session,
        where: (t) =>
            t.filingId.equals(target.id!) &
            t.section.equals(DartSection.businessContent),
      );
      expect(ledger!.status, FilingFetchStatus.stored);
      await run();
      expect(gets, 3);
      expect(
        (await Source.db.find(
          session,
          where: (t) => t.reference.equals(audit.single.reference),
        )).length,
        1,
      );
    });
    test(
      'malformed cover company keeps exact corporate registration with warning',
      () async {
        malformed = true;
        await run();
        expect(
          await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(report.rceptNo),
          ),
          isNotNull,
        );
        final audit = await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'business-source-period-anchor:20260323000900:20260324000715',
          ),
        );
        expect(audit!.title, contains('표지회사명 불일치'));
        expect(audit.title, contains('이상규'));
        expect(
          (await BusinessDocument.db.findById(session, body.id!))!.text,
          body.text,
        );
      },
    );
    test(
      'wrong original corporate shell fails explicitly without registration',
      () async {
        wrongSourceCorp = true;
        await run();
        expect(
          await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(report.rceptNo),
          ),
          isNull,
        );
        final ledger = await DartFilingSection.db.findFirstRow(
          session,
          where: (t) => t.filingId.equals(target.id!),
        );
        expect(ledger!.status, FilingFetchStatus.failed);
        expect(ledger.lastError, contains('businessSourceMetadata'));
      },
    );
    test(
      'cancelled while obtaining proof does not register original',
      () async {
        mutate = () async {
          final job = (await IngestJob.db.findById(session, activeJob!))!;
          await IngestJob.db.updateRow(
            session,
            job.copyWith(status: IngestStatus.cancelled),
          );
        };
        await run();
        expect(
          await DartFiling.db.findFirstRow(
            session,
            where: (t) => t.rceptNo.equals(report.rceptNo),
          ),
          isNull,
        );
      },
    );
    test(
      'wrong actual cover period records explicit metadata failure',
      () async {
        badPeriod = true;
        await run();
        final ledger = await DartFilingSection.db.findFirstRow(
          session,
          where: (t) => t.filingId.equals(target.id!),
        );
        expect(ledger!.status, FilingFetchStatus.failed);
        expect(ledger.lastError, contains('businessSourceMetadata'));
      },
    );
    test(
      'global original receipt company conflict preserves existing source',
      () async {
        final other = await Company.db.insertRow(
          session,
          Company(
            corpCode: '00978075',
            name: '다른회사',
            market: Market.konex,
            stockCode: '000002',
          ),
        );
        final old = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: other.id,
            corpCode: other.corpCode,
            rceptNo: report.rceptNo,
            reportName: '사업보고서 (2025.12)',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.noData,
            discoveredAt: DateTime.now().toUtc(),
          ),
        );
        await run();
        expect(
          (await DartFiling.db.findById(session, old.id!))!.companyId,
          other.id,
        );
        expect(
          await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'business-source-period-anchor:20260323000900:20260324000715',
            ),
          ),
          isNull,
        );
        final ledger = await DartFilingSection.db.findFirstRow(
          session,
          where: (t) => t.filingId.equals(target.id!),
        );
        expect(ledger!.status, FilingFetchStatus.failed);
        expect(
          ledger.lastError,
          contains('Conflicting original source receipt identity'),
        );
      },
    );
    test('changed target canonical year rejects registration', () async {
      mutate = () async {
        await DartFiling.db.updateRow(session, target.copyWith(bsnsYear: 2024));
      };
      await run();
      expect(
        await DartFiling.db.findFirstRow(
          session,
          where: (t) => t.rceptNo.equals(report.rceptNo),
        ),
        isNull,
      );
    });
  });
}
