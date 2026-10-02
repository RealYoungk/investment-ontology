import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const root = 'test/fixtures/financial_html/equity-opening-proof';
  for (final c in [
    (
      '20220316000748',
      '00382199',
      '(주)신한금융지주회사',
      [
        '36815893000000',
        '10410517000000',
        '26405376000000',
        '1424182000000',
        '1413956000000',
        '2013696000000',
      ],
    ),
    (
      '20220322000818',
      '00980122',
      '(주)JB금융지주',
      [
        '2800542000000',
        '716712000000',
        '2083830000000',
        '128408000000',
        '129001000000',
        '196719000000',
      ],
    ),
    (
      '20220325001281',
      '00688996',
      '(주)KB금융지주',
      [
        '28871379000000',
        '6358405000000',
        '22512974000000',
        '1435420000000',
        '1438866000000',
        '1346081000000',
      ],
    ),
  ]) {
    final raw = File('$root/${c.$1}/ofs.html').readAsStringSync();
    final cover = File('$root/${c.$1}/cover.html').readAsStringSync();
    final proof =
        jsonDecode(File('$root/${c.$1}/proof.json').readAsStringSync()) as Map;
    Uri uri(String key) => Uri.parse(
      (proof['sources'] as List).singleWhere((x) => x['label'] == key)['url'],
    );
    List<Map<String, dynamic>> parse(String html) =>
        PublicFinancialHtml.parseStandardAnnual(
          allowSourceVerifiedPartialCore: true,
          coverHtml: cover,
          statementHtml: html,
          coverSource: uri('cover'),
          statementSource: uri('ofs'),
          receipt: c.$1,
          corpCode: c.$2,
          companyName: c.$3,
          periodStart: DateTime.utc(2021),
          periodEnd: DateTime.utc(2021, 12, 31),
          consolidated: false,
        );
    test('${c.$1} prior closing opening needs explicit current CE period', () {
      final rows = parse(raw);
      expect(rows.map((x) => x['thstrm_amount']).toList(), c.$4);
      final ce =
          rows.first['html_provenance']['partialCoreProof']['wholeCE'] as Map;
      expect(ce['currentStartLabel'], contains('2021'));
      expect(ce['currentEndLabel'], contains('2021'));
      expect(ce.containsKey('openingBalanceDate'), isFalse);
      expect(rows.every((x) => x['account_id'] == null), isTrue);
    });
    test('${c.$1} CE current closing contradiction rejected', () {
      final matches = RegExp(r'2021(?:년\s*12월\s*31일|\.12\.31)\s*\(당기말\)')
          .allMatches(raw)
          .toList();
      expect(matches, isNotEmpty);
      final last = matches.last;
      final bad = raw.replaceRange(last.start, last.end, '2020.12.31 (당기말)');
      expect(() => parse(bad), throwsFormatException);
    });
  }
  for (final c in [
    ('20220322001090', '01023822', '(주)메디젠휴먼케어'),
    ('20220321001551', '01344363', '(주)다원넥스뷰'),
  ]) {
    test('${c.$1} actual FY2021 CE closing contradiction remains rejected', () {
      final proof = jsonDecode(
        File('$root/${c.$1}/proof.json').readAsStringSync(),
      ) as Map;
      Uri uri(String k) => Uri.parse(
        (proof['sources'] as List).singleWhere((x) => x['label'] == k)['url'],
      );
      expect(
        () => PublicFinancialHtml.parseStandardAnnual(
          allowSourceVerifiedPartialCore: true,
          coverHtml: File('$root/${c.$1}/cover.html').readAsStringSync(),
          statementHtml: File('$root/${c.$1}/ofs.html').readAsStringSync(),
          coverSource: uri('cover'),
          statementSource: uri('ofs'),
          receipt: c.$1,
          corpCode: c.$2,
          companyName: c.$3,
          periodStart: DateTime.utc(2021),
          periodEnd: DateTime.utc(2021, 12, 31),
          consolidated: false,
        ),
        throwsFormatException,
      );
    });
  }
}
