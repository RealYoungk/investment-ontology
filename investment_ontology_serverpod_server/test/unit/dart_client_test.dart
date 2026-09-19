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
      expect(codes.first.modifyDate, DateTime.utc(2026, 1, 1));
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

  group('DartClient 재무', () {
    DartClient client(String body, {void Function(http.Request)? onRequest}) =>
        DartClient(
          'key',
          httpClient: MockClient((req) async {
            onRequest?.call(req);
            return http.Response.bytes(utf8.encode(body), 200);
          }),
        );

    test('fnlttSinglAcntAll 원문 행을 돌려준다', () async {
      late Uri url;
      final rows =
          await client(
            '{"status":"000","message":"정상","list":[{"rcept_no":"20260310002820",'
            '"sj_div":"BS","account_id":"ifrs-full_Assets","thstrm_amount":"566942110000000"}]}',
            onRequest: (req) => url = req.url,
          ).fetchFinancialStatements(
            corpCode: '00126380',
            bsnsYear: 2025,
            reportCode: '11011',
            fsDiv: 'CFS',
          );

      expect(rows, hasLength(1));
      expect(rows!.single['account_id'], 'ifrs-full_Assets');
      expect(url.queryParameters, containsPair('bsns_year', '2025'));
      expect(url.queryParameters, containsPair('fs_div', 'CFS'));
    });

    test('013(데이터 없음)은 null', () async {
      final rows =
          await client(
            '{"status":"013","message":"조회된 데이타가 없습니다."}',
          ).fetchFinancialStatements(
            corpCode: '00000001',
            bsnsYear: 2025,
            reportCode: '11011',
            fsDiv: 'CFS',
          );
      expect(rows, isNull);
    });

    test('빈 본문은 계속 호출할 수 있는 오류', () async {
      await expectLater(
        client('').fetchFinancialStatements(
          corpCode: '00126380',
          bsnsYear: 2025,
          reportCode: '11011',
          fsDiv: 'CFS',
        ),
        throwsA(
          isA<DartApiException>()
              .having((e) => e.status, 'status', 'empty')
              .having((e) => e.isFatal, 'isFatal', isFalse),
        ),
      );
    });

    test('Source용 주소에는 인증키가 없다', () {
      final url = DartClient.financialApiUrl('00126380', 2025, '11011', 'CFS');
      expect(url.queryParameters.containsKey('crtfc_key'), isFalse);
      expect(url.queryParameters['corp_code'], '00126380');
    });

    test('list.json 페이지를 읽는다', () async {
      late Uri url;
      final page =
          await client(
            '{"status":"000","message":"정상","page_no":1,"page_count":100,'
            '"total_count":1,"total_page":1,"list":[{"corp_code":"00120030",'
            '"corp_name":"GS건설","stock_code":"006360","corp_cls":"Y",'
            '"report_nm":"[기재정정]사업보고서 (2023.12)","rcept_no":"20260630000500",'
            '"flr_nm":"GS건설","rcept_dt":"20260630","rm":""}]}',
            onRequest: (req) => url = req.url,
          ).fetchFilings(
            from: DateTime.utc(2026, 6, 1),
            to: DateTime.utc(2026, 8, 31),
          );

      expect(url.queryParameters, containsPair('bgn_de', '20260601'));
      expect(url.queryParameters, containsPair('last_reprt_at', 'Y'));
      expect(page.totalPages, 1);
      final f = page.items.single;
      expect(f.rceptNo, '20260630000500');
      expect(f.rceptDate, DateTime.utc(2026, 6, 30));
      expect(f.stockCode, '006360');
    });

    test('list.json 013은 빈 페이지', () async {
      final page =
          await client(
            '{"status":"013","message":"조회된 데이타가 없습니다."}',
          ).fetchFilings(
            from: DateTime.utc(2026, 1, 1),
            to: DateTime.utc(2026, 1, 2),
          );
      expect(page.items, isEmpty);
      expect(page.totalPages, 0);
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
