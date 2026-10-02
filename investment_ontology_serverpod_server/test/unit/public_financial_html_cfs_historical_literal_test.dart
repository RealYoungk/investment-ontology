import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const cases = [
  ('20240320000695', '01187458', '(주)에스알바이오텍', 2023, 12, '- 해당사항 없음.'),
  ('20230323001231', '01187458', '(주)에스알바이오텍', 2022, 12, '- 해당사항 없음.'),
  ('20220321000662', '01187458', '(주)에스알바이오텍', 2021, 12, '- 해당사항 없음.'),
];
String raw(String r, String n) =>
    File('test/fixtures/financial_html/cfs-historical-literal/$r/$n.html')
        .readAsStringSync();
Future<PublicFinancialHtmlSource> actual(
  int i, {
  String? body,
  String? corp,
  String? company,
}) {
  final c = cases[i];
  var views = 0;
  return PublicFinancialHtmlFetcher(
    MockClient((r) async {
      expect(r.url.host, 'dart.fss.or.kr');
      expect(r.url.queryParameters.containsKey('crtfc_key'), false);
      expect(r.url.queryParameters['rcpNo'], c.$1);
      final label = r.url.path == '/dsaf001/main.do'
          ? 'shell'
          : views == 0
          ? 'cover'
          : 'cfs';
      final proof = jsonDecode(
        File(
          'test/fixtures/financial_html/cfs-historical-literal/${c.$1}/proof.json',
        ).readAsStringSync(),
      );
      final expected = Uri.parse(
        (proof['sources'] as List).singleWhere(
          (s) => s['label'] == label,
        )['url'],
      );
      if (company == null) {
        expect(r.url.queryParameters, expected.queryParameters);
      }
      return http.Response.bytes(
        utf8.encode(
          r.url.path == '/dsaf001/main.do'
              ? raw(c.$1, 'shell')
              : views++ == 0
              ? raw(c.$1, 'cover')
              : body ?? raw(c.$1, 'cfs'),
        ),
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
        request: r,
      );
    }),
  ).fetchAnnual(
    c.$1,
    reportName: '사업보고서 (${c.$4}.${c.$5.toString().padLeft(2, '0')})',
    corpCode: corp ?? c.$2,
    companyName: company ?? c.$3,
    bsnsYear: c.$4,
    periodEnd: DateTime.utc(c.$4, c.$5 + 1, 0),
    consolidated: true,
  );
}

void main() {
  for (var i = 0; i < cases.length; i++) {
    final index = i;
    final c = cases[i];
    test('${c.$1} official source-bound literal', () async {
      await expectLater(
        actual(index),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((e) => e.sourceReceipt, 'receipt', c.$1)
              .having((e) => e.corpCode, 'corp', c.$2)
              .having((e) => e.evidence, 'literal', c.$6)
              .having(
                (e) => e.sourceDigest,
                'raw SHA',
                sha256
                    .convert(
                      utf8.encode('${raw(c.$1, 'cover')}\n${raw(c.$1, 'cfs')}'),
                    )
                    .toString(),
              ),
        ),
      );
    });
    for (final extra in [
      '<p>조건 충족 시 작성합니다.</p>',
      '<p>첨부를 참조하십시오.</p>',
      '<p>1000</p>',
      '<table><tr><td>1000</td></tr></table>',
      '<script></script>',
      '<style></style>',
    ]) {
      test('${c.$1} rejects extra $extra', () async {
        final b = raw(c.$1, 'cfs').replaceFirst(
          RegExp('</body>', caseSensitive: false),
          '$extra</body>',
        );
        await expectLater(
          actual(index, body: b),
          throwsA(
            predicate(
              (e) =>
                  e is FormatException &&
                  e is! PublicFinancialHtmlBasisNotApplicable,
            ),
          ),
        );
      });
    }
    test('${c.$1} rejects other heading', () async {
      await expectLater(
        actual(
          index,
          body: raw(c.$1, 'cfs').replaceAll('2. 연결재무제표', '3. 연결재무제표 주석'),
        ),
        throwsA(
          predicate(
            (e) =>
                e is FormatException &&
                e is! PublicFinancialHtmlBasisNotApplicable,
          ),
        ),
      );
    });
  }
  test('wrong corp rejects', () async {
    await expectLater(actual(0, corp: '01293388'), throwsFormatException);
  });
  test('wrong company rejects', () async {
    await expectLater(actual(0, company: '다른법인'), throwsFormatException);
  });
}
