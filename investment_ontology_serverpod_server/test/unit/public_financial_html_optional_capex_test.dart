import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const optionalRoot = 'test/fixtures/financial_html/optional-capex';
String fixture(String r, String n) =>
    File('$optionalRoot/$r/$n.html').readAsStringSync();
Map proof(String r) =>
    jsonDecode(File('$optionalRoot/$r/proof.json').readAsStringSync());
Uri uri(String r, String n) => Uri.parse(
  (proof(r)['sources'] as List).singleWhere((x) => x['label'] == n)['url'],
);
List<Map<String, dynamic>> parseActual(
  String r, {
  String? body,
  bool cfs = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: fixture(r, 'cover'),
  statementHtml: body ?? fixture(r, cfs ? 'cfs' : 'ofs'),
  coverSource: uri(r, 'cover'),
  statementSource: uri(r, cfs ? 'cfs' : 'ofs'),
  receipt: r,
  corpCode: proof(r)['corpCode'],
  companyName: r == '20260318000962' ? '(주)안지오랩' : '퓨쳐메디신 주식회사',
  periodStart: DateTime.utc(r == '20260318000962' ? 2025 : 2022),
  periodEnd: DateTime.utc(r == '20260318000962' ? 2025 : 2022, 12, 31),
  consolidated: cfs,
);
Future<PublicFinancialHtmlSource> fetchAngio() =>
    PublicFinancialHtmlFetcher(
      MockClient((req) async {
        const r = '20260318000962';
        final name = req.url.path == '/dsaf001/main.do'
            ? 'shell'
            : req.url.queryParameters['eleId'] ==
                  uri(r, 'cover').queryParameters['eleId']
            ? 'cover'
            : 'ofs';
        return http.Response.bytes(
          utf8.encode(fixture(r, name)),
          200,
          request: req,
        );
      }),
    ).fetchAnnual(
      '20260318000962',
      reportName: '사업보고서 (2025.12)',
      corpCode: '01115044',
      companyName: '(주)안지오랩',
      bsnsYear: 2025,
      periodEnd: DateTime.utc(2025, 12, 31),
      consolidated: false,
    );
String changeCapex(String html, String Function(String) transform) {
  final row = RegExp(
    r'<TR\b[^>]*>.*?</TR>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html).singleWhere((m) => m[0]!.contains('유형자산의 취득'));
  return html.replaceRange(row.start, row.end, transform(row[0]!));
}

void main() {
  test('actual optional dash keeps seven mandatory core amounts and missing raw provenance', () {
    final rows = parseActual('20260318000962');
    expect(rows.length, 7);
    expect(
      rows.any((r) => (r['account_nm'] as String).contains('유형자산')),
      false,
    );
    final missing =
        (rows.first['html_provenance'] as Map)['unavailableOptionalAccounts']
            as List;
    expect(missing.single['printedCurrentCells'], ['-', '']);
    expect(missing.single['accountKey'], 'capex');
  });
  for (final cfs in [true, false]) {
    test('actual mandatory revenue dash remains rejected $cfs', () {
      expect(
        () => parseActual('20230323001133', cfs: cfs),
        throwsFormatException,
      );
    });
  }
  test('invalid nonblank optional amount still fails', () {
    final body = changeCapex(
      fixture('20260318000962', 'ofs'),
      (row) => row.replaceFirst('>-<', '>N/A<'),
    );
    expect(
      () => parseActual('20260318000962', body: body),
      throwsFormatException,
    );
  });
  test('two numeric current optional cells remain ambiguous', () {
    final body = changeCapex(
      fixture('20260318000962', 'ofs'),
      (row) =>
          row.replaceFirst('>-<', '>10<').replaceFirst('<BR/></TD>', '20</TD>'),
    );
    expect(
      () => parseActual('20260318000962', body: body),
      throwsFormatException,
    );
  });
}
