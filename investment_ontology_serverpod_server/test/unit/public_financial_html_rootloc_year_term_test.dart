import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/rootloc-year-term';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String corp = '01262023',
  String receipt = '20260323000661',
  Uri? source,
  String? cover,
  bool cfs = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: body ?? raw('ofs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('ofs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '(주)루트락',
  periodStart: DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
void main() {
  test(
    'actual rightmost year-term thousand-won whole rows require independent CE',
    () {
      final rows = parse();
      expect(rows.length, 8);
      final expected = {
        '자산총계': '15174505000',
        '부채총계': '18633455000',
        '자본총계': '-3458950000',
        '매출액': '9681865000',
        '영업손실': '-1708835000',
        '당기순손실': '-2388887000',
        '영업활동으로인한현금흐름': '-238679000',
      };
      for (final e in expected.entries) {
        final row = rows.singleWhere(
          (r) =>
              (r['account_nm'] as String)
                  .replaceAll(RegExp(r'\s+'), '')
                  .replaceFirst(RegExp(r'^[ⅠⅤⅩ.]+'), '') ==
              e.key,
        );
        expect(row['thstrm_amount'], e.value);
        expect(row['account_id'], null);
        final p = row['html_provenance'];
        expect(p['unit'], '천원');
        expect(p['currentColumn'], 3);
        expect(p['source'], uri('ofs').toString());
        expect(p['supportingPeriodEvidence']['currentProfit'], '-2388887000');
      }
    },
  );
  final body = raw('ofs');
  for (final m in [
    ('wrong CE start', body.replaceAll('2025.1.1(기초)', '2025.2.1(기초)')),
    ('wrong CE end', body.replaceAll('2025.12.31(기말)', '2025.11.30(기말)')),
    ('wrong term', body.replaceAll('제12기', '제13기')),
    ('wrong unit', body.replaceAll('천원', '백만원')),
    ('CE profit conflict', body.replaceAll('(2,388,887)', '(2,388,888)')),
    ('CE equity conflict', body.replaceAll('(3,458,950)', '(3,458,951)')),
    ('whole header altered', body.replaceAll('>총계<', '>비지배지분<')),
  ]) {
    test(m.$1, () => expect(() => parse(body: m.$2), throwsFormatException));
  }
  test(
    'wrong corporation',
    () => expect(() => parse(corp: '00126380'), throwsFormatException),
  );
  test(
    'wrong basis',
    () => expect(() => parse(cfs: true), throwsFormatException),
  );
  test(
    'wrong receipt',
    () => expect(() => parse(receipt: '20260323000662'), throwsFormatException),
  );
  test(
    'wrong document',
    () => expect(
      () => parse(
        source: uri(
          'ofs',
        ).replace(query: uri('ofs').query.replaceFirst('11163088', '11163089')),
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong cover period',
    () => expect(
      () => parse(
        cover: raw('cover').replaceAll('2025년 01월 01일', '2025년 02월 01일'),
      ),
      throwsFormatException,
    ),
  );
}
