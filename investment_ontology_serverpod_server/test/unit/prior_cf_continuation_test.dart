import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const dir = 'test/fixtures/financial_html/prior-cf-continuation';
  final entries =
      jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
  for (final e in entries) {
    final r = e['receipt'] as String;
    final body = File('$dir/$r/ofs.html').readAsStringSync();
    List<Map<String, dynamic>> parse(String s) =>
        PublicFinancialHtml.parseStandardAnnual(
          coverHtml: File('$dir/$r/cover.html').readAsStringSync(),
          statementHtml: s,
          coverSource: Uri.parse(e['coverUrl']),
          statementSource: Uri.parse(e['ofsUrl']),
          receipt: r,
          corpCode: e['corp'],
          companyName: e['name'],
          periodStart: DateTime.utc(e['year']),
          periodEnd: DateTime.utc(e['year'], 12, 31),
          consolidated: false,
        );
    test('$r actual current seven excludes before-prior standalone CF', () {
      final rows = parse(body);
      expect(rows.length, inInclusiveRange(7, 8));
      expect(
        rows.every(
          (x) => x['html_provenance']['periodEnd'] == '${e['year']}-12-31',
        ),
        isTrue,
      );
      final cfo = rows.singleWhere(
        (x) => x['sj_div'] == 'CF' && x['account_nm'].contains('영업활동'),
      );
      expect(
        cfo['thstrm_amount'],
        r == '20220317000866' ? '43756648555' : '160229120608',
      );
    });
    test(
      '$r prior-only header without its exact full duration is rejected',
      () {
        final year = e['year'] as int;
        final changed = body.replaceAll('${year - 2}년', '${year - 3}년');
        expect(changed == body, isFalse);
        expect(() => parse(changed), throwsFormatException);
      },
    );
    test('$r wrong prior term is rejected', () {
      final prior = r == '20220317000866' ? '66' : '67';
      final changed = body.replaceAll(
        RegExp('제\\s*$prior\\(전전\\)\\s*기'),
        '제1(전전)기',
      );
      expect(changed == body, isFalse);
      expect(() => parse(changed), throwsFormatException);
    });
    test('$r ambiguous duplicate current term is rejected', () {
      final before = r == '20220317000866' ? '66' : '67';
      final current = r == '20220317000866' ? '68' : '69';
      final changed = body.replaceAll(
        RegExp('제\\s*$before\\(전전\\)\\s*기'),
        '제$current(당)기',
      );
      expect(changed == body, isFalse);
      expect(() => parse(changed), throwsFormatException);
    });
  }
}
