import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/pim-term-year';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Map<String, dynamic> get evidence =>
    jsonDecode(File('$root/proof.json').readAsStringSync());
Uri uri(String kind) => Uri.parse(evidence['nodes'][kind]);
List<Map<String, dynamic>> parse({
  String? statement,
  String? cover,
  DateTime? start,
  DateTime? end,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: statement ?? raw('ofs'),
  coverSource: uri('사업보고서'),
  statementSource: uri('4.재무제표'),
  receipt: '20250321001900',
  corpCode: '00765897',
  companyName: '한국피아이엠',
  periodStart: start ?? DateTime.utc(2024, 1, 1),
  periodEnd: end ?? DateTime.utc(2024, 12, 31),
  consolidated: false,
);
void main() {
  test(
    'actual term(year) binds one current group and independent whole CE',
    () {
      final rows = parse();
      expect(rows.length, 8);
      expect(
        rows.map((r) => r['thstrm_amount']),
        unorderedEquals([
          '56313074150',
          '19870747312',
          '36442326838',
          '31616831382',
          '4379931738',
          '3987214271',
          '2466477975',
          '-861064926',
        ]),
      );
      expect(
        rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
        isTrue,
      );
      for (final row in rows) {
        final p = row['html_provenance'] as Map;
        expect(p['currentHeader'], contains('2024년'));
        expect(p['supportingPeriodEvidence']['currentProfit'], '3987214271');
        expect(p['supportingPeriodEvidence']['closingEquity'], '36442326838');
      }
    },
  );
  for (final pair in [
    ('wrong year', raw('ofs').replaceAll('(2024년)', '(2023년)')),
    ('wrong term', raw('ofs').replaceAll('제24기</P>', '제23기</P>')),
    ('year only', raw('ofs').replaceAll('제24기</P>', '</P>')),
    ('notes', raw('ofs').replaceAll('(2024년)', '(2024년)(주석)')),
    ('quarter', raw('ofs').replaceAll('(2024년)', '(2024년1분기)')),
    (
      'two current groups',
      raw('ofs')
          .replaceAll('제23기</P>', '제24기</P>')
          .replaceAll('(2023년)', '(2024년)'),
    ),
    (
      'wrong balance',
      raw('ofs').replaceAll('56,313,074,150', '56,313,074,151'),
    ),
  ]) {
    test(
      pair.$1,
      () => expect(() => parse(statement: pair.$2), throwsFormatException),
    );
  }
  test('half and mismatched source period remain rejected', () {
    expect(() => parse(start: DateTime.utc(2024, 7, 1)), throwsFormatException);
    expect(() => parse(end: DateTime.utc(2023, 12, 31)), throwsFormatException);
  });
  test('CE whole total mismatch remains rejected', () {
    final body = raw('ofs');
    final ce = body.indexOf('자본변동표');
    final after = body
        .substring(ce)
        .replaceAll('3,987,214,271', '3,987,214,270');
    expect(
      () => parse(statement: body.substring(0, ce) + after),
      throwsFormatException,
    );
  });
}
