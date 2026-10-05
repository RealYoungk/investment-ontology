import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const cases = [
  (
    '20230320000571',
    '01267958',
    '주식회사 프로티아',
    2022,
    12,
    '당사는 연결대상 종속회사가 존재하지 않으므로, 한국채택국제회계기준의 주된 재무제표인 연결기준의 재무정보를 기재하지 않습니다.',
  ),
  (
    '20230317000589',
    '01113499',
    '(주)아이티센피엔에스',
    2022,
    12,
    '당사는 사업보고서 제출기준일 현재 해당사항 없습니다.',
  ),
];
String raw(String r, String n) =>
    File('assets/financial_source_cache/$r-cfs/$n.html').readAsStringSync();
Future<PublicFinancialHtmlSource> actual(
  int i, {
  String? body,
  String? corp,
  String? cover,
}) {
  final c = cases[i], dir = 'assets/financial_source_cache/${cases[i].$1}-cfs';
  final m = jsonDecode(File('$dir/manifest.json').readAsStringSync());
  final bytes = <String, List<int>>{
    for (final s in m['sources'])
      s['url']: utf8.encode(
        s['label'] == 'cfs'
            ? body ?? raw(c.$1, 'cfs')
            : s['label'] == 'cover'
            ? cover ?? raw(c.$1, 'cover')
            : File('$dir/${s['file']}').readAsStringSync(),
      ),
  };
  return fastFinancialHtmlFetcher(
    MockClient((r) async {
      expect(r.url.queryParameters.containsKey('crtfc_key'), false);
      final b = bytes[r.url.toString()];
      if (b == null) throw const FormatException('Unknown official source');
      return http.Response.bytes(b, 200, request: r);
    }),
  ).fetchAnnual(
    c.$1,
    reportName: '사업보고서 (2022.12)',
    corpCode: corp ?? c.$2,
    companyName: c.$3,
    bsnsYear: 2022,
    periodEnd: DateTime.utc(2022, 12, 31),
    consolidated: true,
  );
}

void main() {
  for (var i = 0; i < cases.length; i++) {
    final n = i, c = cases[i];
    test(
      '${c.$1} exact typed nonpreparer preserves real source and literal',
      () async {
        try {
          await actual(n);
          fail('Must not synthesize numbers');
        } on PublicFinancialHtmlBasisNotApplicable catch (e) {
          expect(e.evidence, c.$6);
          expect(e.sourceReceipt, c.$1);
          expect(e.corpCode, c.$2);
          expect(e.periodStart, DateTime.utc(2022));
          expect(e.periodEnd, DateTime.utc(2022, 12, 31));
          expect(e.issuerIdentityEvidence, isNotNull);
        }
      },
    );
    for (final addition in [
      '<TABLE><TR><TD>1</TD></TR></TABLE>',
      '<P>추가 조건부 문장입니다.</P>',
      '<SCRIPT>x</SCRIPT>',
      '<STYLE>x</STYLE>',
    ]) {
      test('${c.$1} not typed none with extra body $addition', () async {
        try {
          await actual(
            n,
            body: raw(c.$1, 'cfs').replaceFirst('</BODY>', '$addition</BODY>'),
          );
          fail('Reject');
        } catch (e) {
          expect(e, isA<FormatException>());
          expect(e, isNot(isA<PublicFinancialHtmlBasisNotApplicable>()));
        }
      });
    }
    test('${c.$1} wrong own company cannot claim none', () async {
      expect(() => actual(n, corp: '99999999'), throwsFormatException);
    });
  }
}
