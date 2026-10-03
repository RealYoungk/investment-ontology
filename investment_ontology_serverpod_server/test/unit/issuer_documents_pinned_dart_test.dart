import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_feed.dart';

void main() {
  final text = File('assets/issuer_documents/verified_dart_documents.json')
      .readAsStringSync();
  Map<String, dynamic> row() =>
      Map<String, dynamic>.from((jsonDecode(text)['documents'] as List).first);
  test(
    'normal48 actualtype partialsource and no numerical promotion',
    () async {
      final docs = IssuerDocumentsCollector.manifest(
        await IssuerDocumentsSync.combinedManifestText(),
      );
      expect(docs, hasLength(48));
      final dart = docs
          .where((d) => d['metadata']['provider'] == 'DART')
          .toList();
      expect(dart, hasLength(32));
      expect(dart.map((d) => d['metadata']['corpCode']).toSet(), hasLength(9));
      expect(
        dart.where((d) => d['metadata']['documentType'] == 'auditReport'),
        hasLength(23),
      );
      for (final d in dart) {
        final m = d['metadata'] as Map;
        expect(m['financialValues'], isNull);
        expect(m['numericState'], 'notExtracted');
        expect(m['publicContent'], 'linkOnly');
        expect(d['proof']['collectorScope'], contains('not whole original'));
        expect(m['corpCode'], isNot(anyOf('02038566', '02042949')));
        IssuerDocumentsFeed.validate([m]);
      }
    },
  );
  for (final key in [
    'corpCode',
    'provider',
    'providerReceipt',
    'periodStart',
    'periodEnd',
    'documentType',
    'sha256',
    'issuerQuote',
    'periodQuote',
    'officialUrl',
  ]) {
    test('pin metadata rejects $key', () {
      final d = row(), m = d['metadata'] as Map;
      m[key] = '${m[key]}changed';
      expect(
        () => IssuerDocumentsCollector.manifest(
          jsonEncode({
            'schemaVersion': 1,
            'documents': [d],
          }),
        ),
        throwsFormatException,
      );
      expect(() => IssuerDocumentsFeed.validate([m]), throwsFormatException);
    });
  }
  test('proof shell node and whole-scope mutation rejects', () {
    for (final key in [
      'shellUrl',
      'shellSha256',
      'shellCorpCode',
      'readScope',
      'collectorScope',
    ]) {
      final d = row();
      d['proof'][key] = 'changed';
      expect(
        () => IssuerDocumentsCollector.manifest(
          jsonEncode({
            'schemaVersion': 1,
            'documents': [d],
          }),
        ),
        throwsFormatException,
      );
    }
    final d = row();
    d['proof']['node']['eleId'] = '99';
    expect(
      () => IssuerDocumentsCollector.manifest(
        jsonEncode({
          'schemaVersion': 1,
          'documents': [d],
        }),
      ),
      throwsFormatException,
    );
  });
  test('actual shell and chapter privatelycached; replay GET0', () async {
    final d = IssuerDocumentsCollector.manifest(
      text,
    ).singleWhere((d) => d['metadata']['providerReceipt'] == '20260403003880');
    final dir = await Directory.systemTemp.createTemp('pinned-issuer-unit-');
    addTearDown(() => dir.delete(recursive: true));
    var gets = 0;
    final c = IssuerDocumentsCollector(
      cache: dir,
      delay: (_) async {},
      client: MockClient((r) async {
        gets++;
        final n = r.url.toString() == d['proof']['shellUrl']
            ? 'brils2025-shell.html'
            : 'brils2025-financial.html';
        return http.Response.bytes(
          File('test/fixtures/issuer_documents/dart/$n').readAsBytesSync(),
          200,
          request: r,
        );
      }),
    );
    expect(await c.ensure(d, cancelled: () async => false), isTrue);
    expect(gets, 2);
    expect(await c.ensure(d, cancelled: () async => false), isTrue);
    expect(gets, 2);
    expect(dir.listSync(), hasLength(2));
    expect(dir.listSync().every((e) => e.path.endsWith('.html')), isTrue);
  });
  test('corrupt shell blocks primary; cancelbefore GET0', () async {
    final d = IssuerDocumentsCollector.manifest(
      text,
    ).singleWhere((d) => d['metadata']['providerReceipt'] == '20260403003880');
    final dir = await Directory.systemTemp.createTemp('pinned-issuer-bad-');
    addTearDown(() => dir.delete(recursive: true));
    var gets = 0;
    final c = IssuerDocumentsCollector(
      cache: dir,
      delay: (_) async {},
      client: MockClient((r) async {
        gets++;
        return http.Response('<html>other issuer</html>', 200, request: r);
      }),
    );
    expect(await c.ensure(d, cancelled: () async => true), isFalse);
    expect(gets, 0);
    await expectLater(
      c.ensure(d, cancelled: () async => false),
      throwsFormatException,
    );
    expect(gets, 1);
    expect(dir.listSync(), isEmpty);
  });
}
