import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

const root = 'test/fixtures/financial_html/ofu-angle-note';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['nodes'] as Map)[n],
);
List<Map<String, dynamic>> parse({
  String? statement,
  DateTime? start,
  DateTime? end,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw('cover'),
  statementHtml: statement ?? raw('ofs'),
  coverSource: uri('사업보고서'),
  statementSource: uri('4.재무제표'),
  receipt: '20220316000721',
  corpCode: '00337296',
  companyName: '원포유',
  periodStart: start ?? DateTime.utc(2021),
  periodEnd: end ?? DateTime.utc(2021, 12, 31),
  consolidated: false,
);
void main() {
  test('actual OFS seven printed current rows preserved', () {
    final rows = parse();
    expect(rows.length, 7);
    expect(
      rows.map((r) => r['thstrm_amount']),
      unorderedEquals([
        '17467583611',
        '8635596196',
        '8831987415',
        '8957570370',
        '2573692697',
        '2236521775',
        '3746384242',
      ]),
    );
    expect(
      rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
      isTrue,
    );
    for (final name in ['매출액<주석14>', '당기순이익<주석13>', '영업활동으로인한현금흐름<주석15>']) {
      expect(
        rows.any(
          (r) =>
              r['account_nm'] == name &&
              (r['html_provenance'] as Map)['printedLabel'] == name,
        ),
        isTrue,
      );
    }
    expect(raw('ofs'), contains('2021년12월31일(당기말)'));
    expect(raw('ofs'), contains('8,831,987,415'));
  });
  for (final note in [
    '&lt;주석x&gt;',
    '&lt;주석14',
    '&lt;주석14,15&gt;',
    '&lt;주14&gt;',
    '&lt;주석14&gt;구성요소',
    '&lt;주석14&gt;(주석1)',
    '&lt;주석14&gt;&lt;주석15&gt;',
  ]) {
    test(
      'reject malformed or nonfinite $note',
      () => expect(
        () => parse(statement: raw('ofs').replaceAll('&lt;주석14&gt;', note)),
        throwsFormatException,
      ),
    );
  }
  test(
    'middle note cannot become whole revenue',
    () => expect(
      () => parse(
        statement: raw('ofs').replaceAll('매출액&lt;주석14&gt;', '매출&lt;주석14&gt;액'),
      ),
      throwsFormatException,
    ),
  );
  test('wrong source annual period', () {
    expect(() => parse(start: DateTime.utc(2021, 7, 1)), throwsFormatException);
    expect(() => parse(end: DateTime.utc(2020, 12, 31)), throwsFormatException);
  });
  test(
    'balance contradiction rejects',
    () => expect(
      () => parse(
        statement: raw('ofs').replaceAll('17,467,583,611', '17,467,583,612'),
      ),
      throwsFormatException,
    ),
  );
  test('notes section or relabeled CFS cannot supply OFS core', () {
    for (final heading in ['5. 재무제표 주석', '2. 연결재무제표']) {
      expect(
        () => parse(statement: raw('ofs').replaceFirst('4. 재무제표', heading)),
        throwsFormatException,
      );
    }
  });
  test('quarter title cannot masquerade as annual duration', () {
    expect(
      () => parse(
        statement: raw('ofs').replaceAll(
          '2021년 01월 01일부터 2021년 12월 31일까지',
          '2021년 10월 01일부터 2021년 12월 31일까지',
        ),
      ),
      throwsFormatException,
    );
  });
  test('Dart normalization finite exact suffix only', () {
    expect(FinancialAccounts.normalizedName('매출액<주석14>'), '매출액');
    for (final name in ['매출<주석14>액', '매출액<주석x>', '매출액<주석14', '매출액<주석14,15>']) {
      expect(FinancialAccounts.normalizedName(name), isNot('매출액'));
    }
  });
}
