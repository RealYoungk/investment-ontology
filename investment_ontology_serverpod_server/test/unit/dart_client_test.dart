import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:test/test.dart';

void main() {
  group('DartClient', () {
    test('corpCode.xml zip을 파싱하고 빈 종목코드는 null로 둔다', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<result>
  <list><corp_code>00126380</corp_code><corp_name>삼성전자</corp_name><stock_code>005930</stock_code><modify_date>20260101</modify_date></list>
  <list><corp_code>00000001</corp_code><corp_name>비상장</corp_name><stock_code> </stock_code><modify_date>20250101</modify_date></list>
</result>''';
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('CORPCODE.xml', utf8.encode(xml)));
      final zip = ZipEncoder().encodeBytes(archive);
      final client = DartClient(
        'key',
        httpClient: MockClient((req) async {
          expect(req.url.queryParameters['crtfc_key'], 'key');
          return http.Response.bytes(zip, 200);
        }),
      );

      final codes = await client.fetchCorpCodes();

      expect(codes, hasLength(2));
      expect(codes.first.corpCode, '00126380');
      expect(codes.first.stockCode, '005930');
      expect(codes.last.stockCode, isNull);
    });

    test('corpCode.xml 오류 응답은 DartApiException', () async {
      final client = DartClient(
        'bad',
        httpClient: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              '<result><status>010</status><message>등록되지 않은 키입니다.</message></result>',
            ),
            200,
          ),
        ),
      );

      await expectLater(
        client.fetchCorpCodes(),
        throwsA(
          isA<DartApiException>()
              .having((e) => e.status, 'status', '010')
              .having((e) => e.isFatal, 'isFatal', isTrue),
        ),
      );
    });

    test('company.json status가 000이 아니면 예외', () async {
      final client = DartClient(
        'key',
        httpClient: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('{"status":"013","message":"조회된 데이타가 없습니다."}'),
            200,
          ),
        ),
      );

      await expectLater(
        client.fetchCompany('00000001'),
        throwsA(
          isA<DartApiException>()
              .having((e) => e.status, 'status', '013')
              .having((e) => e.isFatal, 'isFatal', isFalse),
        ),
      );
    });
  });

  group('KsicSeeder.classify', () {
    test('소분류 코드에서 중분류와 대분류를 구한다', () {
      expect(KsicSeeder.classify('264'), (division: '26', section: 'C'));
      expect(KsicSeeder.classify('64992'), (division: '64', section: 'K'));
      expect(KsicSeeder.classify('582'), (division: '58', section: 'J'));
    });

    test('코드가 없거나 이상하면 null', () {
      expect(KsicSeeder.classify(null), (division: null, section: null));
      expect(KsicSeeder.classify('X'), (division: null, section: null));
    });
  });
}
