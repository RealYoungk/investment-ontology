import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/kiwoom-cfs-term';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String? cover,
  String corp = '00296290',
  Uri? source,
  DateTime? start,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: body ?? raw('cfs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('cfs'),
  receipt: '20230320001037',
  corpCode: corp,
  companyName: '키움증권(주)',
  periodStart: start ?? DateTime.utc(2022),
  periodEnd: DateTime.utc(2022, 12, 31),
  consolidated: true,
);
void main() {
  test('actual repeated term full annual titles retain whole CFS seven and CE total', () {
    final rows = parse();
    expect(rows.length, 8);
    final expected = {
      '자산총계': '48037301112929',
      '부채총계': '43444207177999',
      '자본총계': '4593093934930',
      '영업수익': '8942353665382',
      '영업이익': '656424566711',
      '당기순이익': '508170326221',
      '영업활동으로인한현금흐름(주석41)': '-2011805579287',
    };
    for (final e in expected.entries) {
      final row = rows.singleWhere(
        (r) =>
            (r['account_nm'] as String).replaceAll(RegExp(r'\s+'), '') == e.key,
      );
      expect(row['thstrm_amount'], e.value);
      expect(row['account_id'], null);
      expect(row['currency'], 'KRW');
      final proof = row['html_provenance']['supportingPeriodEvidence'];
      expect(proof['totalColumn'], 8);
      expect(proof['currentProfit'], '508170326221');
      expect(proof['closingEquity'], '4593093934930');
    }
  });
  final body = raw('cfs');
  for (final m in [
    (
      'current full period conflict',
      body.replaceAll('2022년 1월 1일부터', '2022년 2월 1일부터'),
    ),
    ('current term conflict', body.replaceAll('제24기 (당)기', '제25기 (당)기')),
    ('unsupported units', body.replaceAll('(단위: 원)', '(단위: USD)')),
    (
      'CIS whole profit cannot use parent amount',
      body.replaceFirst('508,170,326,221', '507,326,120,051'),
    ),
    (
      'CIS whole profit cannot use NCI amount',
      body.replaceFirst('508,170,326,221', '844,206,170'),
    ),
    (
      'CE whole total cannot use parent amount',
      body.replaceAll('4,593,093,934,930', '4,556,027,966,942'),
    ),
    (
      'CE full dates conflict',
      body.replaceAll('2022년 12월 31일(당기말)', '2021년 12월 31일(당기말)'),
    ),
    ('whole profit row missing', body.replaceAll('당 기 순 이 익', '지배주주 순이익')),
  ]) {
    test(m.$1, () => expect(() => parse(body: m.$2), throwsFormatException));
  }
  test(
    'foreign corporation cannot invoke scoped grammar',
    () => expect(() => parse(corp: '00000001'), throwsFormatException),
  );
  test(
    'wrong source dcm cannot invoke scoped grammar',
    () => expect(
      () => parse(
        source: uri('cfs')
            .replace(query: uri('cfs').query.replaceAll('9077489', '9999999')),
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong source receipt rejected',
    () => expect(
      () => parse(
        source: uri('cfs').replace(
          query: uri('cfs').query
              .replaceAll('20230320001037', '20230320001038'),
        ),
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong declared start rejected',
    () => expect(
      () => parse(start: DateTime.utc(2022, 2, 1)),
      throwsFormatException,
    ),
  );

  test(
    'wrong source offset cannot activate grammar',
    () => expect(
      () => parse(
        source: uri('cfs')
            .replace(query: uri('cfs').query.replaceAll('905295', '905296')),
      ),
      throwsFormatException,
    ),
  );
  test(
    'CE NCI replaces whole profit is rejected',
    () => expect(
      () => parse(
        body:
            raw('cfs').substring(0, raw('cfs').indexOf('연 결 자 본 변 동 표')) +
            raw('cfs')
                .substring(raw('cfs').indexOf('연 결 자 본 변 동 표'))
                .replaceAll('508,170,326,221', '844,206,170'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'CE last header must name whole total',
    () => expect(
      () => parse(body: raw('cfs').replaceAll('총 계</TH>', '비지배지분</TH>')),
      throwsFormatException,
    ),
  );
}
