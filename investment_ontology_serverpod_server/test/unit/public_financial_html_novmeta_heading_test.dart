import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/novmeta-cfo-heading';
String raw(String name) => File('$root/$name.html').readAsStringSync();
Uri uri(String name) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync()) as List).singleWhere(
    (e) => e['label'] == name,
  )['uri'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String corp = '01065785',
  String receipt = '20260320000871',
  bool cfs = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw('cover'),
  statementHtml: body ?? raw('ofs'),
  coverSource: uri('cover'),
  statementSource: uri('ofs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '(주)노브메타파마',
  periodStart: DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
void main() {
  test('official blank caption and independent printed total preserve direct amounts', () {
    final rows = parse();
    final cf = rows.singleWhere((r) => r['account_nm'] == '영업활동으로부터의 순현금유출');
    expect(cf['thstrm_amount'], '-3358353147');
    expect(cf['account_id'], isNull);
    expect(rows.any((r) => r['account_nm'] == '영업활동 현금흐름'), isFalse);
    expect(rows.length, greaterThanOrEqualTo(7));
    expect(
      rows.map((r) => r['thstrm_amount']).toSet(),
      containsAll({
        '4362722562',
        '770110124',
        '3592612438',
        '34838000',
        '-5367108582',
        '-10447517973',
        '-3358353147',
      }),
    );
    expect(rows.every((r) => r['account_id'] == null), isTrue);
    expect(cf['html_provenance']['currentColumn'], 1);
    expect(cf['html_provenance']['unit'], '원');

    expect(
      rows.singleWhere(
        (r) => r['account_nm'].toString().replaceAll(' ', '') == '자산총계',
      )['thstrm_amount'],
      '4362722562',
    );
  });
  test('caption current value is not accepted as an empty heading', () {
    final changed = raw('ofs').replaceFirst(
      "<TD width='148' height='23' align='RIGHT' valign='TOP'><BR/></TD>",
      "<TD width='148' height='23' align='RIGHT' valign='TOP'>0</TD>",
    );
    expect(changed, isNot(raw('ofs')));
    expect(() => parse(body: changed), throwsFormatException);
  });
  for (final value in ['-', '', '1 2']) {
    test('mandatory direct total rejects unavailable or ambiguous $value', () {
      final changed = raw('ofs').replaceFirst('(3,358,353,147)', value);
      expect(() => parse(body: changed), throwsFormatException);
    });
  }
  test(
    'missing independent whole total rejects',
    () => expect(
      () => parse(
        body: raw('ofs').replaceAll('영업활동으로부터의 순현금유출', '영업에서 창출된 현금흐름'),
      ),
      throwsFormatException,
    ),
  );
  test(
    'wrong source company rejects',
    () => expect(() => parse(corp: '01065786'), throwsFormatException),
  );
  test(
    'wrong receipt rejects',
    () => expect(() => parse(receipt: '20260320000872'), throwsFormatException),
  );
  test(
    'wrong basis rejects',
    () => expect(() => parse(cfs: true), throwsFormatException),
  );
  test(
    'wrong unit rejects',
    () => expect(
      () => parse(body: raw('ofs').replaceAll('(단위: 원)', '(단위: USD)')),
      throwsFormatException,
    ),
  );
  test(
    'wrong actual flow period rejects',
    () => expect(
      () => parse(
        body: raw('ofs')
            .replaceAll('2025년 01월 01일', '2024년 01월 01일')
            .replaceAll('2025년 1월 1일', '2024년 1월 1일'),
      ),
      throwsFormatException,
    ),
  );
  test('caption prior value cannot be used or ignored', () {
    final changed = raw('ofs').replaceFirst(
      "<TD width='147' height='23' align='RIGHT' valign='TOP'><BR/></TD>",
      "<TD width='147' height='23' align='RIGHT' valign='TOP'>1</TD>",
    );
    expect(changed, isNot(raw('ofs')));
    expect(() => parse(body: changed), throwsFormatException);
  });
  test(
    'wrong whole label cannot fall back to operating-generated cash',
    () => expect(
      () => parse(
        body: raw('ofs').replaceAll('영업활동으로부터의 순현금유출', '영업에서 창출된 현금흐름'),
      ),
      throwsFormatException,
    ),
  );
}
