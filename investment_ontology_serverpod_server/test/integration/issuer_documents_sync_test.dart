import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
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
      await expectLater(
        IssuerDocumentsSync.collectAndStore(
          session,
          manifestText: manifest([docs.first]),
          collector: wrong,
          cancelled: () async => false,
        ),
        throwsFormatException,
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
      await expectLater(
        IssuerDocumentsSync.collectAndStore(
          session,
          manifestText: manifest([docs.first, additional]),
          collector: unavailable,
          cancelled: () async => false,
        ),
        throwsFormatException,
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
