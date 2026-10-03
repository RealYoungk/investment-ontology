import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const dir = 'test/fixtures/financial_html/common-year-term';
  final proof = jsonDecode(File('$dir/proof.json').readAsStringSync()) as Map;
  final original = File('$dir/ofs.html').readAsStringSync();
  Uri uri(String label) => Uri.parse(
    (proof['sources'] as List).singleWhere((e) => e['label'] == label)['url'],
  );
  List<Map<String, dynamic>> parse({
    String? html,
    String name = '주식회사 루켄테크놀러지스',
    bool cfs = false,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: File('$dir/cover.html').readAsStringSync(),
    statementHtml: html ?? original,
    coverSource: uri('cover'),
    statementSource: uri('ofs'),
    receipt: '20250321001653',
    corpCode: '00886792',
    companyName: name,
    periodStart: DateTime.utc(2024),
    periodEnd: DateTime.utc(2024, 12, 31),
    consolidated: cfs,
  );
  test('actual source hashes remain exact', () {
    for (final e in proof['sources']) {
      expect(
        sha256
            .convert(File('$dir/${e['label']}.html').readAsBytesSync())
            .toString(),
        e['sha256'],
      );
    }
  });
  test('actual whole seven values and independent CE totals', () {
    final rows = parse();
    final expected = [
      '46061578422',
      '31944885315',
      '14116693107',
      '20980394946',
      '-3323843419',
      '-3287506222',
      '4300195369',
    ];
    expect(rows.take(7).map((r) => r['thstrm_amount']).toList(), expected);
    expect(rows.every((r) => r['account_id'] == null), isTrue);
    for (final row in rows) {
      final p = row['html_provenance'] as Map;
      expect(p['basis'], 'OFS');
      expect(p['source'], uri('ofs').toString());
      expect(p['periodStart'], '2024-01-01');
      expect(p['periodEnd'], '2024-12-31');
      expect(p['supportingWholeEquityEvidence']['wholeProfit'], '-3287506222');
      expect(
        p['supportingWholeEquityEvidence']['closingEquity'],
        '14116693107',
      );
    }
  });
  for (final (label, before, after) in [
    ('wrong current year', '2024년', '2023년'),
    ('wrong current term', '18(당)', '17(당)'),
    ('prior rather than current', '18(당)', '18(전)'),
    ('CE-only closing contradiction', '14,116,693,107', '14,116,693,108'),
    ('CE-only profit contradiction', '(3,287,506,222)', '(3,287,506,223)'),
    ('missing CE closing date', '2024.12.31(당기말)', '2023.12.31(당기말)'),
  ]) {
    test(label, () {
      var mutated = original;
      if (label.startsWith('CE-only')) {
        final ce = RegExp(
          r'<TABLE\b[^>]*>.*?</TABLE>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(mutated).elementAt(5);
        final at = ce.start + ce.group(0)!.lastIndexOf(before);
        expect(at, greaterThan(ce.start));
        mutated = mutated.replaceRange(at, at + before.length, after);
      } else {
        expect(mutated, contains(before));
        mutated = mutated.replaceAll(before, after);
      }
      expect(() => parse(html: mutated), throwsFormatException);
    });
  }
  test('CE component columns cannot replace independently printed total', () {
    final mutated = original.replaceAll('총 &nbsp;계', '비지배지분');
    expect(mutated, isNot(original));
    expect(() => parse(html: mutated), throwsFormatException);
  });
  test('CE duplicate whole current profit cannot be selected arbitrarily', () {
    final ce = RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(original).elementAt(5);
    final body = ce.group(0)!;
    final rows = RegExp(
      r'<TR\b[^>]*>.*?</TR>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(body);
    final profit = rows
        .lastWhere((r) => r.group(0)!.contains('(3,287,506,222)'))
        .group(0)!;
    final mutatedCe = body.replaceFirst(profit, '$profit$profit');
    expect(
      () => parse(html: original.replaceRange(ce.start, ce.end, mutatedCe)),
      throwsFormatException,
    );
  });
  test('CE independent currency unit must be printed as won', () {
    final ce = RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(original).elementAt(5);
    final before = original.substring(0, ce.start);
    final at = before.lastIndexOf('단위 : 원');
    expect(at, greaterThan(0));
    expect(
      () => parse(
        html: original.replaceRange(at, at + '단위 : 원'.length, '단위 : 천원'),
      ),
      throwsFormatException,
    );
  });
  test(
    'company owner mismatch rejected',
    () => expect(() => parse(name: '다른회사'), throwsFormatException),
  );
  test(
    'OFS cannot be reused as CFS',
    () => expect(() => parse(cfs: true), throwsFormatException),
  );
}
