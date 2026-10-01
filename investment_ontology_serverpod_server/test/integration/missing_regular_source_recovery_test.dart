import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/missing_regular_source_recovery.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';

import 'disclosure_sync_test.dart' show FakeDisclosures;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Missing regular discovery', (builder, endpoints) {
    late Session session;
    late Company company;
    late IngestJob job;
    var gets = 0;
    bool offering = false, wrongCorp = false;
    Future<void> Function()? onCover;
    String fixture(String n) =>
        File('test/fixtures/missing_regular_source/$n.html').readAsStringSync();
    setUp(() async {
      session = builder.asAdmin.build();
      gets = 0;
      offering = false;
      wrongCorp = false;
      onCover = null;
      company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00960623',
          name: '덕산넵코어스(주)',
          fiscalMonth: 12,
          market: Market.kosdaq,
          stockCode: '266690',
        ),
      );
      job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: 'business_documents',
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
    });
    http.Client makeClient() => MockClient((r) async {
      gets++;
      String text;
      if (r.url.path == '/navi/searchNavi.do') {
        text = fixture('navi');
        if (offering) {
          text = text.replaceAll('반기보고서(사업연도:2026)', '증권신고서(지분증권)');
        }
      } else if (r.url.path == '/dsaf001/main.do') {
        text = fixture('shell');
        if (wrongCorp) text = text.replaceAll('00960623', '01586923');
      } else if (r.url.queryParameters['eleId'] == '1') {
        text = fixture('cover');
        if (onCover != null) {
          final cb = onCover;
          onCover = null;
          await cb!();
        }
      } else {
        text = fixture('body');
      }
      return http.Response.bytes(utf8.encode(text), 200, request: r);
    });
    Future<bool> recover() async {
      final client = makeClient();
      try {
        return await MissingRegularSourceRecovery.recover(
          session,
          job.id!,
          company,
          client,
          interval: Duration.zero,
        );
      } finally {
        client.close();
      }
    }

    test('exact periodic metadata registration is idempotent and not financial values/body completion', () async {
      expect(await recover(), true);
      expect(gets, 4);
      final f = (await DartFiling.db.findFirstRow(
        session,
        where: (t) => t.rceptNo.equals('20260813000889'),
      ))!;
      expect(f.corpCode, company.corpCode);
      expect(f.bsnsYear, 2026);
      expect(f.reportCode, FinancialReportCode.halfYear);
      expect(f.reportName, '반기보고서 (2026.06)');
      expect(f.consolidatedStatus, FilingFetchStatus.pending);
      final sources = await Source.db.find(
        session,
        where: (t) =>
            t.reference.equals('public-regular-source-metadata:20260813000889'),
      );
      expect(sources.length, 1);
      expect(sources.single.title, contains('재무 금액 미검증'));
      expect(
        sources.single.title,
        contains(
          '16854e467ae793b4b62f2bb9111407d131744a5e636d6dea941564e84c439989',
        ),
      );
      expect(await FinancialFact.db.find(session), isEmpty);
      expect(await BusinessDocument.db.find(session), isEmpty);
      expect(await recover(), false);
      expect(gets, 4);
      expect((await Source.db.find(session)).length, 1);
    });
    test('nonperiodic offering never creates filing/source', () async {
      offering = true;
      await expectLater(recover(), throwsFormatException);
      expect(await DartFiling.db.find(session), isEmpty);
      expect(await Source.db.find(session), isEmpty);
    });
    test(
      'wrong source corporate identity leaves all ledgers unchanged',
      () async {
        wrongCorp = true;
        await expectLater(recover(), throwsFormatException);
        expect(await DartFiling.db.find(session), isEmpty);
      },
    );
    test('cancel after cover proof blocks registration', () async {
      onCover = () async {
        await IngestJob.db.updateRow(
          session,
          job.copyWith(status: IngestStatus.cancelled),
        );
      };
      expect(await recover(), false);
      expect(await DartFiling.db.find(session), isEmpty);
      expect(await Source.db.find(session), isEmpty);
    });
    test('normal business-only budget zero discovers and stores exact body without 28 APIs', () async {
      final dart = FakeDisclosures().client();
      await DisclosureSync(
        session,
        dart,
        job.id!,
        businessOnly: true,
        dailyBudget: 0,
        callInterval: Duration.zero,
        missingRegularClientFactory: makeClient,
        publicDocuments: PublicBusinessDocument(client: makeClient()),
      ).run();
      final filing = (await DartFiling.db.find(session)).single;
      expect(filing.rceptNo, '20260813000889');
      final body = (await BusinessDocument.db.find(session)).single;
      expect(body.rceptNo, filing.rceptNo);
      expect(body.text.length, 18606);
      expect(await FinancialFact.db.find(session), isEmpty);
      final finalJob = (await IngestJob.db.findById(session, job.id!))!;
      expect(finalJob.updated, 1);
      expect(finalJob.apiCalls, 0);
      expect(finalJob.status, IngestStatus.succeeded);
      expect((await DartFilingSection.db.find(session)).length, 1);
    });
    test(
      'unidentified source is audited and cached without becoming data absence',
      () async {
        offering = true;
        final first = await MissingRegularSourceRecovery.recoverMissing(
          session,
          job.id!,
          clientFactory: makeClient,
          interval: Duration.zero,
        );
        expect(first.unidentified, 1);
        final calls = gets;
        final second = await MissingRegularSourceRecovery.recoverMissing(
          session,
          job.id!,
          clientFactory: makeClient,
          interval: Duration.zero,
        );
        expect(second.unidentified, 1);
        expect(gets, calls);
        expect(await DartFiling.db.find(session), isEmpty);
        expect(
          (await Source.db.find(session)).single.title,
          contains('unidentified'),
        );
      },
    );
    test(
      'technical identity failure is explicitly failed and has 15 minute cache',
      () async {
        wrongCorp = true;
        final first = await MissingRegularSourceRecovery.recoverMissing(
          session,
          job.id!,
          clientFactory: makeClient,
          interval: Duration.zero,
        );
        expect(first.failed, 1);
        final calls = gets;
        final second = await MissingRegularSourceRecovery.recoverMissing(
          session,
          job.id!,
          clientFactory: makeClient,
          interval: Duration.zero,
        );
        expect(second.failed, 1);
        expect(gets, calls);
        expect(await DartFiling.db.find(session), isEmpty);
      },
    );
    test('non-business job cannot use registration service', () async {
      await IngestJob.db.updateRow(
        session,
        job.copyWith(kind: 'financial_facts'),
      );
      await expectLater(recover(), throwsStateError);
      await expectLater(
        MissingRegularSourceRecovery.recoverMissing(
          session,
          job.id!,
          clientFactory: makeClient,
        ),
        throwsStateError,
      );
      expect(await Source.db.find(session), isEmpty);
      expect(gets, 0);
    });
  });
}
