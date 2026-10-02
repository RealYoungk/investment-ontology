import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/cronex-ce-period';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String? cover,
  String receipt = '20260709000504',
  String corp = '01034730',
  bool cfs = false,
  DateTime? start,
  Uri? source,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: body ?? raw('ofs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('ofs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '크로넥스',
  periodStart: start ?? DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
void main() {
  test('actual undated OFS current14 with CE dates profit equity proof', () {
    final rows = parse();
    final values = {for (final r in rows) r['account_nm']: r['thstrm_amount']};
    for (final amount in [
      '14237907303',
      '12371090488',
      '1866816815',
      '5534042425',
      '641909126',
      '-2569130760',
      '461278058',
    ]) {
      expect(values.values, contains(amount));
    }
    expect(
      rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
      isTrue,
    );
    for (final r in rows) {
      final p = r['html_provenance'] as Map;
      final e = p['supportingPeriodEvidence'] as Map;
      expect(
        e['mode'],
        'exact-cronex-undated-title-equity-period-corroboration',
      );
      expect(e['periodStart'], '2025-01-01');
      expect(e['periodEnd'], '2025-12-31');
      expect(e['currentProfit'], '-2569130760');
      expect(e['closingEquity'], '1866816815');
      expect(p['currentColumn'], 1);
      expect(p['currentColumnSpan'], 2);
      expect(e['source'], uri('ofs').toString());
    }
  });
  for (final amount in ['1,866,816,815', '2,569,130,760']) {
    test('CE-only contradiction $amount preserves primary statements', () {
      final body = raw('ofs');
      final at = body.indexOf('자본변동표');
      final cf = body.indexOf('현금흐름표', at);
      expect(at, greaterThan(0));
      expect(cf, greaterThan(at));
      final changed =
          body.substring(0, at) +
          body.substring(at, cf).replaceAll(amount, '1,234,567,890') +
          body.substring(cf);
      expect(() => parse(body: changed), throwsFormatException);
    });
  }
  for (final pair in [
    ('wrong CE start', '2025년 01월 01일(당기초)', '2025년 02월 01일(당기초)'),
    ('wrong CE end', '2025년 12월 31일(당기말)', '2025년 11월 30일(당기말)'),
    ('wrong term', '제 14(당)', '제 13(당)'),
    ('CE contradiction', '1,866,816,815', '1,866,816,816'),
    ('current ambiguity', '제 13(전)', '제 14(당)'),
    ('unit', '단위 : 원', '단위 : 천원'),
  ]) {
    test(
      pair.$1,
      () => expect(
        () => parse(body: raw('ofs').replaceAll(pair.$2, pair.$3)),
        throwsFormatException,
      ),
    );
  }
  test(
    'wrong company cover rejected',
    () => expect(
      () => parse(cover: raw('cover').replaceAll('크로넥스', '다른회사')),
      throwsFormatException,
    ),
  );
  test('wrong requested period/basis/corp remains rejected', () {
    expect(() => parse(start: DateTime.utc(2025, 7, 1)), throwsFormatException);
    expect(() => parse(cfs: true), throwsFormatException);
    expect(() => parse(corp: '00000001'), throwsFormatException);
  });
  test(
    'same shape foreign receipt not enabled',
    () => expect(() => parse(receipt: '20260709000505'), throwsFormatException),
  );
  test(
    'wrong dcm does not unlock source profile',
    () => expect(
      () => parse(
        source: uri(
          'ofs',
        ).replace(query: uri('ofs').query.replaceFirst('11470809', '11470810')),
      ),
      throwsFormatException,
    ),
  );
}
