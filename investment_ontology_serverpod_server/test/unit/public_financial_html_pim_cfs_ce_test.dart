import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/pim-cfs-whole-ce';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String? cover,
  String receipt = '20250321001900',
  String corp = '00765897',
  Uri? source,
  bool cfs = true,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: body ?? raw('cfs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('cfs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '한국피아이엠',
  periodStart: DateTime.utc(2024),
  periodEnd: DateTime.utc(2024, 12, 31),
  consolidated: cfs,
);
String ceOnly(String from, String to) {
  final s = raw('cfs');
  final at = s.indexOf('연결자본변동표');
  final end = s.indexOf('연결현금흐름표', at);
  expect(at, greaterThan(0));
  expect(end, greaterThan(at));
  return s.substring(0, at) +
      s.substring(at, end).replaceAll(from, to) +
      s.substring(end);
}

void main() {
  test('actual full annual CFS seven direct values and distinct outer whole CE source proof', () {
    final proof = jsonDecode(File('$root/proof.json').readAsStringSync());
    for (final label in ['cover', 'cfs']) {
      expect(
        sha256.convert(File('$root/$label.html').readAsBytesSync()).toString(),
        (proof['sources'] as List).singleWhere(
          (s) => s['label'] == label,
        )['sha256'],
      );
    }
    final rows = parse();
    expect(rows.take(7).map((r) => r['thstrm_amount']).toList(), [
      '76459309100',
      '32807209849',
      '43652099251',
      '37447247186',
      '3606809251',
      '2777596031',
      '3548256433',
    ]);
    for (final row in rows) {
      expect(row['account_id'], isNull);
      expect(row['currency'], 'KRW');
      final p = row['html_provenance'] as Map;
      final e = p['supportingPeriodEvidence'] as Map;
      expect(p['source'], uri('cfs').toString());
      expect(p['basis'], 'CFS');
      expect(p['printedLabel'], row['account_nm']);
      expect(p['currentColumn'], 1);
      expect(p['unit'], '원');
      expect(e['mode'], 'exact-pim-cfs-span-whole-equity-corroboration');
      expect(e['wholeTotalColumn'], 8);
      expect(e['parentSubtotalColumn'], 6);
      expect(e['nonControllingColumn'], 7);
      expect(e['periodStart'], '2024-01-01');
      expect(e['periodEnd'], '2024-12-31');
      expect(e['currentTerm'], '24');
      expect(e['currentProfit'], '2777596031');
      expect(e['closingEquity'], '43652099251');
      expect(e['source'], uri('cfs').toString());
    }
  });
  for (final pair in [
    ('term', '제24기', '제23기'),
    ('unit', '단위 : 원', '단위 : 천원'),
    ('parent header', '지배기업 소유주 지분', '전체 자본'),
    ('NCI header', '비지배지분', '부모지분'),
    ('parent span', "colspan='6'", "colspan='5'"),
    ('current start', '2024.01.01(당기초)', '2023.01.01(당기초)'),
    ('current end', '2024.12.31(당기말)', '2023.12.31(당기말)'),
    ('whole equity contradiction', '43,652,099,251', '43,652,099,252'),
    ('whole profit contradiction', '2,777,596,031', '2,777,596,032'),
  ]) {
    test(
      'CE contradiction rejects ${pair.$1}',
      () => expect(
        () => parse(body: ceOnly(pair.$2, pair.$3)),
        throwsFormatException,
      ),
    );
  }
  for (final value in ['2,777,596,031', '43,652,099,251']) {
    test('outer whole missing cannot reuse equal parent subtotal $value', () {
      final body = raw('cfs');
      final start = body.indexOf('연결자본변동표');
      final end = body.indexOf('연결현금흐름표', start);
      final ce = body.substring(start, end);
      final last = ce.lastIndexOf(value);
      expect(last, greaterThan(0));
      final changed =
          '${ce.substring(0, last)}-${ce.substring(last + value.length)}';
      expect(
        () => parse(
          body: '${body.substring(0, start)}$changed${body.substring(end)}',
        ),
        throwsFormatException,
      );
    });
  }
  test('primary current term-year column cannot refer to prior year', () {
    expect(
      () => parse(body: raw('cfs').replaceAll('2024년', '2023년')),
      throwsFormatException,
    );
  });
  test('foreign corp/receipt/URI/basis/cover rejected', () {
    expect(() => parse(corp: '00000001'), throwsFormatException);
    expect(() => parse(receipt: '20250321001901'), throwsFormatException);
    expect(() => parse(cfs: false), throwsFormatException);
    expect(
      () => parse(
        source: uri(
          'cfs',
        ).replace(query: uri('cfs').query.replaceFirst('10450768', '10450769')),
      ),
      throwsFormatException,
    );
    expect(
      () => parse(cover: raw('cover').replaceAll('한국피아이엠', '다른회사')),
      throwsFormatException,
    );
  });
  test('duplicate current dates or CE table remain ambiguous', () {
    expect(
      () => parse(body: ceOnly('2023.01.01(전기초)', '2024.01.01(당기초)')),
      throwsFormatException,
    );
    final s = raw('cfs');
    final tables = RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(s).toList();
    final ce = tables[9].group(0)!;
    expect(
      () => parse(body: s.replaceFirst(ce, '$ce$ce')),
      throwsFormatException,
    );
  });
}
