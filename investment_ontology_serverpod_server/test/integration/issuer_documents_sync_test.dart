import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_schedule.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  final asset = jsonDecode(
    File('assets/issuer_documents/verified_fund_documents.json')
        .readAsStringSync(),
  ) as Map;
  final all = IssuerDocumentsCollector.manifest(jsonEncode(asset));
  final docs = all.where((d) {
    final m = d['metadata'] as Map;
    return (m['corpCode'] == '00435297' && m['periodEnd'] == '2024-12-31') ||
        (m['corpCode'] == '01880801' && m['periodEnd'] == '2024-12-31') ||
        (m['corpCode'] == '00600013' && m['periodEnd'] == '2026-06-30');
  }).toList();
  final paths = {
    '00435297': 'mkif-2024.pdf',
    '01880801': 'kbif-2024.pdf',
    '00600013': 'mapps-2026-half.pdf',
  };
  String manifest(List<Map<String, dynamic>> d) =>
      jsonEncode({...asset, 'documents': d});
  withServerpod('공식 투자회사 원문 독립 보존', (builder, endpoints) {
    test('first issuer source fails while others store; separate raw failure remains visible without altering body counts', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp('issuer-partial-db-');
      addTearDown(() => cache.delete(recursive: true));
      for (final code in paths.keys) {
        await Company.db.insertRow(
          session,
          Company(corpCode: code, name: code, market: Market.kospi),
        );
      }
      final collector = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((r) async {
          final d = docs.singleWhere(
            (d) => (d['metadata'] as Map)['officialUrl'] == r.url.toString(),
          );
          final code = (d['metadata'] as Map)['corpCode'] as String;
          if (code == '00435297') return http.Response('', 503, request: r);
          return http.Response.bytes(
            File('test/fixtures/issuer_documents/${paths[code]}')
                .readAsBytesSync(),
            200,
            request: r,
          );
        }),
      );
      addTearDown(collector.client.close);
      final result = await IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: manifest(docs),
        collector: collector,
        cancelled: () async => false,
      );
      expect(result.failedCompanies, 1);
      expect(result.storedCompanies, 2);
      expect(result.storedDocuments, 2);
      expect(await ResearchSnapshot.db.count(session), 2);
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: 'business_documents',
          status: IngestStatus.succeeded,
          startedAt: DateTime.now().toUtc(),
          processed: 7,
          updated: 6,
          failed: 0,
          apiCalls: 4,
          message: '사업본문 저장 6',
        ),
      );
      final budgetAt = DateTime.now().toUtc().add(const Duration(days: 1));
      await IngestSchedule.businessDocumentsResume(session, budgetAt);
      final budgetBefore = await sp.FutureCallEntry.db.find(
        session,
        where: (t) =>
            t.identifier.equals(IngestSchedule.businessDocumentsResumeId),
      );
      await IssuerDocumentsSync.recordResult(session, job.id!, result);
      final budgetAfter = await sp.FutureCallEntry.db.find(
        session,
        where: (t) =>
            t.identifier.equals(IngestSchedule.businessDocumentsResumeId),
      );
      expect(budgetAfter.single.id, budgetBefore.single.id);
      expect(budgetAfter.single.time, budgetBefore.single.time);
      final recorded = (await IngestJob.db.findById(session, job.id!))!;
      expect(recorded.status, IngestStatus.failed);
      expect(
        [
          recorded.processed,
          recorded.updated,
          recorded.failed,
          recorded.apiCalls,
        ],
        [7, 6, 0, 4],
      );
      expect(recorded.message, contains('사업본문 저장 6'));
      expect(
        recorded.message,
        contains('공식 별도 원문: 회사 보존 2 · 문서 보존 2 · 회사 실패 1'),
      );
      final setup = IssuerDocumentsResult()
        ..setupFailed = true
        ..reasons.add('비공개 영속 cache 경로 미설정');
      await IssuerDocumentsSync.recordResult(session, job.id!, setup);
      final setupRecorded = (await IngestJob.db.findById(session, job.id!))!;
      expect(setupRecorded.status, IngestStatus.failed);
      expect(setupRecorded.message, contains('회사 실패 0 · 준비 실패 1'));
      expect(setupRecorded.failed, 0);
      await IngestJob.db.updateRow(
        session,
        recorded.copyWith(status: IngestStatus.cancelled, message: '사용자 취소'),
      );
      await IssuerDocumentsSync.recordResult(session, job.id!, result);
      expect(
        (await IngestJob.db.findById(session, job.id!))!.message,
        '사용자 취소',
      );
    });

    test('four pinned Brils sources collect five separate current financial groups without fabricating regular reports', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp(
        'issuer-financial-five-db-',
      );
      addTearDown(() => cache.delete(recursive: true));
      final own = IssuerDocumentsCollector.manifest(
        File('assets/issuer_documents/verified_dart_documents.json')
            .readAsStringSync(),
      ).where((d) => (d['metadata'] as Map)['corpCode'] == '01801026').toList();
      expect(own.length, 4);
      await Company.db.insertRow(
        session,
        Company(corpCode: '01801026', name: '브릴스', market: Market.kosdaq),
      );
      var gets = 0;
      final collector = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((request) async {
          gets++;
          final url = request.url.toString();
          final doc = own.singleWhere(
            (d) =>
                (d['metadata'] as Map)['officialUrl'] == url ||
                (d['proof'] as Map)['shellUrl'] == url,
          );
          final metadata = doc['metadata'] as Map;
          final receipt = metadata['providerReceipt'] as String;
          final prefix = receipt == '20260403003880' ? 'brils2025' : receipt;
          final kind = metadata['officialUrl'] == url ? 'financial' : 'shell';
          return http.Response.bytes(
            File('test/fixtures/issuer_documents/dart/$prefix-$kind.html')
                .readAsBytesSync(),
            200,
            request: request,
          );
        }),
      );
      addTearDown(collector.client.close);
      final manifest = jsonEncode({'schemaVersion': 1, 'documents': own});
      Future<IssuerDocumentsResult> collect(bool cancelled) =>
          IssuerDocumentsSync.collectAndStore(
            session,
            manifestText: manifest,
            collector: collector,
            cancelled: () async => cancelled,
          );
      final result = await collect(false);
      expect(result.storedDocuments, 4);
      expect(result.financialPeriodGroups, 5);
      expect(result.hasFailure, isFalse);
      expect(gets, 8);
      final data = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '01801026',
          'issuerFinancials',
        ),
      ) as Map;
      final rows = data['rows'] as List;
      expect(rows.length, 5);
      expect(rows.expand((r) => r['accounts'] as List).length, 40);
      expect(
        rows
            .where((r) => r['periodEnd'] == '2026-06-30')
            .map((r) => r['basis'])
            .toSet(),
        {'CFS', 'OFS'},
      );
      expect(await ResearchSnapshot.db.count(session), 2);
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: manifest,
        ),
        isFalse,
      );
      final snapshots = (await ResearchSnapshot.db.find(session))
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await collect(false);
      await collect(true);
      expect(gets, 8);
      expect(
        (await ResearchSnapshot.db.find(session))
            .map((r) => jsonEncode(r.toJson()))
            .toList(),
        snapshots,
      );
      await expectLater(
        endpoints.research.importFeed(
          builder.asAdmin,
          '01801026',
          'issuerFinancials',
          jsonEncode(rows),
          'verified-primary-html-rule',
          'https://dart.fss.or.kr',
          'source-bound-partial-current-core;no-api-report-or-xbrl-assertion',
        ),
        throwsA(isA<IngestException>()),
      );
      expect(await ResearchSnapshot.db.count(session), 2);
      expect(await FinancialReport.db.count(session), 0);
      expect(await FinancialFact.db.count(session), 0);
      expect(await DartFiling.db.count(session), 0);
      expect(await BusinessDocument.db.count(session), 0);
      expect(await ApiCallUsage.db.count(session), 0);
    });

    test('pinned own audit chapter stores metadata, replays without GET and fails closed on partial fetch', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp('issuer-dart-db-');
      addTearDown(() => cache.delete(recursive: true));
      final allDart = IssuerDocumentsCollector.manifest(
        File('assets/issuer_documents/verified_dart_documents.json')
            .readAsStringSync(),
      );
      final doc = allDart.singleWhere(
        (d) =>
            (d['metadata'] as Map)['corpCode'] == '01801026' &&
            (d['metadata'] as Map)['periodEnd'] == '2025-12-31',
      );
      await Company.db.insertRow(
        session,
        Company(corpCode: '01801026', name: '브릴스', market: Market.kosdaq),
      );
      final before = [
        await FinancialReport.db.count(session),
        await FinancialFact.db.count(session),
        await DartFiling.db.count(session),
        await BusinessDocument.db.count(session),
        await ApiCallUsage.db.count(session),
      ];
      var gets = 0;
      var failBody = true;
      final collector = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((r) async {
          gets++;
          final shell = r.url.toString() == (doc['proof'] as Map)['shellUrl'];
          if (!shell && failBody) {
            return http.Response('partial failure', 503, request: r);
          }
          return http.Response.bytes(
            File(
              'test/fixtures/issuer_documents/dart/brils2025-${shell ? 'shell' : 'financial'}.html',
            ).readAsBytesSync(),
            200,
            request: r,
          );
        }),
      );
      addTearDown(collector.client.close);
      Future<void> store() => IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: jsonEncode({
          'schemaVersion': 1,
          'documents': [doc],
        }),
        collector: collector,
        cancelled: () async => false,
      );
      expect(await IssuerDocumentsSync.hasPending(session), isTrue);
      final failure = await IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: jsonEncode({
          'schemaVersion': 1,
          'documents': [doc],
        }),
        collector: collector,
        cancelled: () async => false,
      );
      expect(failure.failedCompanies, 1);
      expect(failure.storedDocuments, 0);
      expect(await ResearchSnapshot.db.count(session), 0);
      failBody = false;
      await store();
      final saved = await ResearchSnapshot.db.find(
        session,
        where: (t) => t.kind.equals('issuerDocuments'),
      );
      expect(saved.length, 1);
      final ownManifest = jsonEncode({
        'schemaVersion': 1,
        'documents': [doc],
      });
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: ownManifest,
        ),
        isFalse,
      );
      final primary = File(
        '${cache.path}/${(doc['metadata'] as Map)['sha256']}.html',
      );
      final originalBytes = await primary.readAsBytes();
      await primary.delete();
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: ownManifest,
        ),
        isTrue,
      );
      await primary.writeAsString('corrupt private cache');
      expect(
        await IssuerDocumentsSync.hasPending(
          session,
          cache: cache,
          manifestText: ownManifest,
        ),
        isTrue,
      );
      final corrupt = await IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: ownManifest,
        collector: collector,
        cancelled: () async => false,
      );
      expect(corrupt.failedCompanies, 1);
      expect(await ResearchSnapshot.db.count(session), 2);
      await primary.writeAsBytes(originalBytes);
      final sourceCount = await Source.db.count(session);
      final observations = gets;
      await store();
      expect(gets, observations);
      expect(await Source.db.count(session), sourceCount);
      expect(
        (await ResearchSnapshot.db.find(
          session,
          where: (t) => t.kind.equals('issuerDocuments'),
        )).single.id,
        saved.single.id,
      );
      expect(
        await IssuerDocumentsSync.hasPending(session),
        isTrue,
      ); // remaining three own Brils documents are still pending
      final data = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '01801026',
          'issuerDocuments',
        ),
      ) as Map;
      final numeric = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '01801026',
          'issuerFinancials',
        ),
      ) as Map;
      expect(numeric['state'], 'ready');
      expect(numeric['provider'], 'verified-primary-html-rule');
      final numericRow = (numeric['rows'] as List).single as Map;
      expect(numericRow['basis'], 'OFS');
      expect(numericRow['periodKind'], 'ownAnnual');
      expect(numericRow['periodEnd'], '2025-12-31');
      expect(numericRow['numericState'], 'partialCore');
      expect(numericRow['regularReportCode'], isNull);
      expect((numericRow['accounts'] as List).length, 8);
      expect((numeric['source'] as Map)['kind'], 'officialFile');
      final row = (data['rows'] as List).single as Map;
      expect(row['numericState'], 'notExtracted');
      expect(row['publicContent'], 'linkOnly');
      expect(row['financialValues'], isNull);
      expect([
        await FinancialReport.db.count(session),
        await FinancialFact.db.count(session),
        await DartFiling.db.count(session),
        await BusinessDocument.db.count(session),
        await ApiCallUsage.db.count(session),
      ], before);
    });

    test('actual3 PDF bytes → immutable raw snapshots; no financial/body/API mutation; admin boundaries', () async {
      final session = builder.build();
      addTearDown(session.close);
      final cache = await Directory.systemTemp.createTemp('issuer-db-cache-');
      addTearDown(() => cache.delete(recursive: true));
      for (final code in paths.keys) {
        await Company.db.insertRow(
          session,
          Company(corpCode: code, name: '공식 투자회사 $code', market: Market.kospi),
        );
      }
      final beforeReports = await FinancialReport.db.count(session),
          beforeBodies = await BusinessDocument.db.count(session),
          beforeJobs = await IngestJob.db.count(session),
          beforeCalls = await ApiCallUsage.db.count(session);
      var gets = 0;
      final client = MockClient((r) async {
        gets++;
        final d = docs.singleWhere(
          (d) => (d['metadata'] as Map)['officialUrl'] == r.url.toString(),
        );
        final pdf = File(
          'test/fixtures/issuer_documents/${paths[(d['metadata'] as Map)['corpCode']]}',
        ).readAsBytesSync();
        return http.Response.bytes(pdf, 200, request: r);
      });
      final collector = IssuerDocumentsCollector(
        cache: cache,
        client: client,
        delay: (_) async {},
      );
      Future<void> store() => IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: manifest(docs),
        collector: collector,
        cancelled: () async => false,
      );
      await store();
      expect(gets, 3);
      expect(await ResearchSnapshot.db.count(session), 3);
      final originals = await ResearchSnapshot.db.find(session);
      final originalJson = originals
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await store();
      expect(gets, 3);
      expect(await ResearchSnapshot.db.count(session), 3);
      for (final d in docs) {
        final m = d['metadata'] as Map, code = m['corpCode'] as String;
        final data = jsonDecode(
          await endpoints.research.data(
            builder.asAnonymous,
            code,
            'issuerDocuments',
          ),
        ) as Map;
        expect(data['state'], 'ready');
        expect(data['rows'], [m]);
        expect(data['source']['kind'], 'officialFile');
        final source = await Source.db.findById(
          session,
          (data['source']['id'] as num).toInt(),
        );
        expect(
          source!.retrievedAt,
          DateTime.parse((d['proof'] as Map)['downloadedAt'] as String),
        );
        final proof = jsonDecode(source.title) as Map;
        expect(proof['documents'], [d]);
        expect(proof['monetaryExtraction'], 'notExtracted');
      }
      expect(await FinancialReport.db.count(session), beforeReports);
      expect(await BusinessDocument.db.count(session), beforeBodies);
      expect(await IngestJob.db.count(session), beforeJobs);
      expect(await ApiCallUsage.db.count(session), beforeCalls);
      final row = docs.first['metadata'] as Map;
      Future<int> write(dynamic auth, String corp, List rows) =>
          endpoints.research.importFeed(
            auth,
            corp,
            'issuerDocuments',
            jsonEncode(rows),
            'officialIR',
            'https://www.mkif.com',
            IssuerDocumentsSync.reference,
          );
      await expectLater(
        write(builder.asAnonymous, row['corpCode'], [row]),
        throwsA(anything),
      );
      await expectLater(
        write(builder.asReader, row['corpCode'], [row]),
        throwsA(anything),
      );
      await expectLater(
        write(builder.asAdmin, '01880801', [row]),
        throwsA(anything),
      );
      await write(builder.asAdmin, row['corpCode'], [
        row,
      ]); // Same amounts-null source, new provider observation.
      await store();
      final finalRows = await ResearchSnapshot.db.find(session);
      for (final old in originals) {
        expect(
          jsonEncode(finalRows.singleWhere((r) => r.id == old.id).toJson()),
          originalJson[originals.indexOf(old)],
        );
      }
      // Unknown company, changed source bytes and incomplete company batch cannot replace latest.
      final oldLatest = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          row['corpCode'],
          'issuerDocuments',
        ),
      );
      final bad = jsonDecode(manifest(docs)) as Map;
      (bad['documents'][0]['metadata'] as Map)['corpCode'] = '00000000';
      await expectLater(
        IssuerDocumentsSync.collectAndStore(
          session,
          manifestText: jsonEncode(bad),
          collector: collector,
          cancelled: () async => false,
        ),
        throwsFormatException,
      );
      final wrongDir = await Directory.systemTemp.createTemp('issuer-wrong-');
      addTearDown(() => wrongDir.delete(recursive: true));
      final wrong = IssuerDocumentsCollector(
        cache: wrongDir,
        delay: (_) async {},
        client: MockClient(
          (r) async => http.Response('%PDF-wrong', 200, request: r),
        ),
      );
      expect(
        (await IssuerDocumentsSync.collectAndStore(
          session,
          manifestText: manifest([docs.first]),
          collector: wrong,
          cancelled: () async => false,
        )).failedCompanies,
        1,
      );
      final additional = all.firstWhere(
        (d) =>
            (d['metadata'] as Map)['corpCode'] == row['corpCode'] &&
            (d['metadata'] as Map)['periodEnd'] == '2025-12-31',
      );
      final unavailable = IssuerDocumentsCollector(
        cache: cache,
        delay: (_) async {},
        client: MockClient((r) async => http.Response('', 503, request: r)),
      );
      expect(
        (await IssuerDocumentsSync.collectAndStore(
          session,
          manifestText: manifest([docs.first, additional]),
          collector: unavailable,
          cancelled: () async => false,
        )).failedCompanies,
        1,
      );
      expect(
        jsonDecode(
          await endpoints.research.data(
            builder.asAnonymous,
            row['corpCode'],
            'issuerDocuments',
          ),
        ),
        oldLatest,
      );
      final count = await ResearchSnapshot.db.count(session);
      await IssuerDocumentsSync.collectAndStore(
        session,
        manifestText: manifest(docs),
        collector: collector,
        cancelled: () async => true,
      );
      expect(await ResearchSnapshot.db.count(session), count);
      expect(gets, 3);
      // The production worker entry point is inert in test mode: no external HTTP.
      await IssuerDocumentsSync.run(session, cancelled: () async => false);
      expect(await ResearchSnapshot.db.count(session), count);
    });
  });
}
