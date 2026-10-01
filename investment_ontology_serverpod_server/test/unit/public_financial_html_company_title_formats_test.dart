import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const fixtureRoot = 'test/fixtures/financial_html/company-title-formats';
String fixture(String r, String n) =>
    File('$fixtureRoot/$r/$n.html').readAsStringSync();
Map proof(String r) =>
    jsonDecode(File('$fixtureRoot/$r/proof.json').readAsStringSync());
Uri uri(String r, String n) => Uri.parse(
  (proof(r)['sources'] as List).singleWhere((x) => x['label'] == n)['url'],
);
List<Map<String, dynamic>> parseActual(
  String r, {
  bool cfs = false,
  String? cover,
  String? body,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? fixture(r, 'cover'),
  statementHtml: body ?? fixture(r, cfs ? 'cfs' : 'ofs'),
  coverSource: uri(r, 'cover'),
  statementSource: uri(r, cfs ? 'cfs' : 'ofs'),
  receipt: r,
  corpCode: proof(r)['corpCode'],
  companyName: r == '20260316001455' ? '(주)유니포인트' : '지에이이노더스(주)',
  periodStart: DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
Future<PublicFinancialHtmlSource> fetchActual(
  String r, {
  bool cfs = false,
  String? cover,
  String? body,
  String? shell,
}) =>
    PublicFinancialHtmlFetcher(
      MockClient((req) async {
        final name = req.url.path == '/dsaf001/main.do'
            ? 'shell'
            : req.url.queryParameters['eleId'] ==
                  uri(r, 'cover').queryParameters['eleId']
            ? 'cover'
            : cfs
            ? 'cfs'
            : 'ofs';
        return http.Response.bytes(
          utf8.encode(
            name == 'shell'
                ? shell ?? fixture(r, name)
                : name == 'cover'
                ? cover ?? fixture(r, name)
                : body ?? fixture(r, name),
          ),
          200,
          request: req,
        );
      }),
    ).fetchAnnual(
      r,
      reportName: '사업보고서 (2025.12)',
      corpCode: proof(r)['corpCode'],
      companyName: r == '20260316001455' ? '(주)유니포인트' : '지에이이노더스(주)',
      bsnsYear: 2025,
      periodEnd: DateTime.utc(2025, 12, 31),
      consolidated: cfs,
    );
void main() {
  test('actual joint representatives preserve exact legal company and current source', () async {
    const r = '20260316001455';
    final x = await fetchActual(r);
    expect(x.sourceReceipt, r);
    expect(x.rows.length, greaterThanOrEqualTo(7));
    expect(
      x.rows.singleWhere(
        (x) =>
            (x['account_nm'] as String).replaceAll(RegExp(r'\s+'), '') == '매출액',
      )['thstrm_amount'],
      '58346049641',
    );
  });
  for (final cfs in [true, false]) {
    test(
      'actual dotted statement dates and exact year-term header $cfs',
      () async {
        const r = '20260319000105';
        final x = await fetchActual(r, cfs: cfs);
        expect(x.rows.length, greaterThanOrEqualTo(7));
        expect(x.rows.every((x) => x['account_id'] == null), true);
      },
    );
  }
  test(
    'foreign company remains rejected despite shared representative marker',
    () async {
      const r = '20260316001455';
      await expectLater(
        fetchActual(r, cover: fixture(r, 'cover').replaceAll('유니포인트', '다른회사')),
        throwsFormatException,
      );
    },
  );
  test('wrong source shell corporate identity rejected', () async {
    const r = '20260316001455';
    await expectLater(
      fetchActual(
        r,
        shell: fixture(r, 'shell').replaceAll('00445869', '00321204'),
      ),
      throwsFormatException,
    );
  });
  for (final replacement in ['2024년도 (제28기)', '2025년도 (제27기)']) {
    test('wrong year-term current header rejected $replacement', () {
      const r = '20260319000105';
      expect(
        () => parseActual(
          r,
          body: fixture(r, 'ofs')
              .replaceAll(
                '2025년도',
                replacement.startsWith('2024') ? '2024년도' : '2025년도',
              )
              .replaceAll(
                '제28기',
                replacement.contains('27기') ? '제27기' : '제28기',
              ),
        ),
        throwsFormatException,
      );
    });
  }
  test('wrong dotted actual end remains rejected', () {
    const r = '20260319000105';
    expect(
      () => parseActual(
        r,
        body: fixture(r, 'ofs').replaceAll('2025.12.31', '2025.12.30'),
      ),
      throwsFormatException,
    );
  });
  for (final bad in ['매출원가', '고객별매출', '부문매출', '주석매출']) {
    test('exact whole revenue excludes $bad', () {
      const r = '20260319000105';
      expect(
        () => parseActual(
          r,
          body: fixture(r, 'ofs').replaceAll('Ⅰ.매 &nbsp;출', 'Ⅰ.$bad'),
        ),
        throwsFormatException,
      );
    });
  }
  test('conflicting dated current title rejects', () {
    const r = '20260319000105';
    expect(
      () => parseActual(
        r,
        body: fixture(r, 'ofs').replaceFirst('2025.01.01', '2025.01.02'),
      ),
      throwsFormatException,
    );
  });
  test('year-only financial titles remain unsupported', () {
    const r = '20260319000677';
    expect(
      () => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: fixture(r, 'cover'),
        statementHtml: fixture(r, 'ofs'),
        coverSource: uri(r, 'cover'),
        statementSource: uri(r, 'ofs'),
        receipt: r,
        corpCode: '01116380',
        companyName: '씨앤에스링크',
        periodStart: DateTime.utc(2025),
        periodEnd: DateTime.utc(2025, 12, 31),
        consolidated: false,
      ),
      throwsFormatException,
    );
  });
}
