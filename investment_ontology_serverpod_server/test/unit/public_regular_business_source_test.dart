import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_regular_business_source.dart';

void main() {
  String fixture(String n) =>
      File('test/fixtures/missing_regular_source/$n.html').readAsStringSync();
  Future<dynamic> fetch({
    String? navi,
    String? shell,
    String? cover,
    String? body,
    String corp = '00960623',
  }) {
    final client = MockClient((r) async {
      final text = r.url.path == '/navi/searchNavi.do'
          ? navi ?? fixture('navi')
          : r.url.path == '/dsaf001/main.do'
          ? shell ?? fixture('shell')
          : r.url.queryParameters['eleId'] == '1'
          ? cover ?? fixture('cover')
          : body ?? fixture('body');
      return http.Response.bytes(utf8.encode(text), 200, request: r);
    });
    return PublicRegularBusinessSource.fetch(
      client,
      corpCode: corp,
      companyName: '덕산넵코어스(주)',
      fiscalMonth: 12,
      interval: Duration.zero,
    ).whenComplete(client.close);
  }

  test(
    'actual navigation discovers exact half-year, cover and business body',
    () async {
      final p = await fetch();
      expect(p.metadata.receipt, '20260813000889');
      expect(p.reportName, '반기보고서 (2026.06)');
      expect(p.metadata.periodStart, DateTime.utc(2026, 1, 1));
      expect(p.metadata.periodEnd, DateTime.utc(2026, 6, 30));
      expect(p.body.text.length, 18606);
      expect(
        p.body.bodySha256,
        '16854e467ae793b4b62f2bb9111407d131744a5e636d6dea941564e84c439989',
      );
    },
  );
  test('prospectus is not a periodic filing', () async {
    await expectLater(
      fetch(
        navi: fixture('navi').replaceAll('반기보고서(사업연도:2026)', '증권신고서(지분증권)'),
      ),
      throwsFormatException,
    );
  });
  test('foreign navigation corporate identity rejected', () async {
    await expectLater(fetch(corp: '01586923'), throwsFormatException);
  });
  test('foreign original corporate identity rejected', () async {
    await expectLater(
      fetch(shell: fixture('shell').replaceAll('00960623', '01586923')),
      throwsFormatException,
    );
  });
  test('wrong metadata period and navigation year rejected', () async {
    await expectLater(
      fetch(cover: fixture('cover').replaceAll('2026년', '2025년')),
      throwsFormatException,
    );
  });
  test(
    'missing business section never registers metadata-only success',
    () async {
      await expectLater(
        fetch(body: '<html><body>원문 없음</body></html>'),
        throwsFormatException,
      );
    },
  );
}
