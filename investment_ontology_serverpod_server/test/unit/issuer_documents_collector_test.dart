import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';

void main() {
  final source = File('assets/issuer_documents/verified_fund_documents.json')
      .readAsStringSync();
  test('actual 12 annual plus 3 latest (MKIF own half-year results) and 1 exact retrospective source retain amounts null and independent provider IDs', () {
    final rows = IssuerDocumentsCollector.manifest(source)
        .map((d) => d['metadata'] as Map)
        .toList();
    expect(rows, hasLength(16));
    expect(
      rows.where((r) => '${r['periodEnd']}'.startsWith('2026')),
      hasLength(3),
    );
    expect(rows.where((r) => r['corpCode'] == '01880801'), hasLength(4));
    for (final r in rows) {
      expect(r['financialValues'], isNull);
      expect(r['numericState'], 'notExtracted');
      expect(r['publicContent'], 'linkOnly');
    }
    expect(
      rows.singleWhere(
        (r) => r['corpCode'] == '00600013' && r['periodEnd'] == '2026-06-30',
      )['periodStart'],
      '2026-01-01',
    );
    final kb = rows.singleWhere(
      (r) => r['corpCode'] == '01880801' && r['periodEnd'] == '2026-06-30',
    );
    expect(kb['documentType'], 'operatingReport');
    expect(kb['periodStart'], '2026-01-01');
    expect(kb['providerReceipt'], isNull);
    expect(kb['providerDocumentId'], isNull);
    expect(
      kb['officialUrl'],
      'https://kbif.co.kr/upload/2026/7/20260731043629001933.pdf',
    );
  });
  test('future acquisition evidence and financial promotion reject', () {
    final raw = jsonDecode(source) as Map;
    ((raw['documents'] as List).first['proof'] as Map)['downloadedAt'] =
        '2099-01-01T00:00:00Z';
    expect(
      () => IssuerDocumentsCollector.manifest(jsonEncode(raw)),
      throwsFormatException,
    );
    expect(
      () => IssuerDocumentsCollector.manifest(
        source.replaceFirst(
          '"financialValues": null',
          '"financialValues": {"revenue":1}',
        ),
      ),
      throwsFormatException,
    );
  });
  group('private cache', () {
    late Directory dir;
    late Map<String, dynamic> doc;
    final pdf = utf8.encode('%PDF-1.7\nopaque original bytes');
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('issuer-doc-unit-');
      doc = Map<String, dynamic>.from(
        IssuerDocumentsCollector.manifest(source).first,
      );
      doc['metadata'] = Map<String, dynamic>.from(doc['metadata'] as Map)
        ..['sha256'] = sha256.convert(pdf).toString();
    });
    tearDown(() async => dir.delete(recursive: true));
    test('exact cache reused without GET', () async {
      var gets = 0;
      final c = IssuerDocumentsCollector(
        cache: dir,
        delay: (_) async {},
        client: MockClient((r) async {
          gets++;
          return http.Response.bytes(pdf, 200, request: r);
        }),
      );
      expect(await c.ensure(doc, cancelled: () async => false), isTrue);
      expect(await c.ensure(doc, cancelled: () async => false), isTrue);
      expect(gets, 1);
      expect(
        await File('${dir.path}/${(doc['metadata'] as Map)['sha256']}.pdf')
            .readAsBytes(),
        pdf,
      );
    });
    test('cancel before GET and after response does not cache', () async {
      var gets = 0, cancel = false;
      final c = IssuerDocumentsCollector(
        cache: dir,
        delay: (_) async {},
        client: MockClient((r) async {
          gets++;
          cancel = true;
          return http.Response.bytes(pdf, 200, request: r);
        }),
      );
      expect(await c.ensure(doc, cancelled: () async => true), isFalse);
      expect(gets, 0);
      expect(await c.ensure(doc, cancelled: () async => cancel), isFalse);
      expect(gets, 1);
      expect(dir.listSync(), isEmpty);
    });
    test('SHA mismatch and redirect reject', () async {
      for (final code in [200, 302]) {
        final c = IssuerDocumentsCollector(
          cache: dir,
          delay: (_) async {},
          client: MockClient(
            (r) async => http.Response('%PDF-wrong', code, request: r),
          ),
        );
        await expectLater(
          c.ensure(doc, cancelled: () async => false),
          throwsFormatException,
        );
      }
      expect(dir.listSync(), isEmpty);
    });
    test('corrupt existing cache never overwritten or fetched', () async {
      final p = File('${dir.path}/${(doc['metadata'] as Map)['sha256']}.pdf');
      await p.writeAsString('%PDF-corrupt');
      var gets = 0;
      final c = IssuerDocumentsCollector(
        cache: dir,
        delay: (_) async {},
        client: MockClient((r) async {
          gets++;
          return http.Response.bytes(pdf, 200, request: r);
        }),
      );
      await expectLater(
        c.ensure(doc, cancelled: () async => false),
        throwsFormatException,
      );
      expect(gets, 0);
      expect(await p.readAsString(), '%PDF-corrupt');
    });
  });
}
