import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const profits = {
    '20220330000929': '108701927',
    '20240321000503': '325767477',
    '20250320000656': '372558633',
  };
  for (final entry in profits.entries) {
    final root =
        'test/fixtures/financial_html/independent-equity-period/${entry.key}';
    final p = jsonDecode(File('$root/proof.json').readAsStringSync()) as Map;
    final year = p['year'] as int;
    final body = File('$root/ofs.html').readAsStringSync();
    List<Map<String, dynamic>> parse(
      String value, {
      bool consolidated = false,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: File('$root/cover.html').readAsStringSync(),
      statementHtml: value,
      coverSource: Uri.parse(p['coverUrl']),
      statementSource: Uri.parse(p['ofsUrl']),
      receipt: entry.key,
      corpCode: p['corp'],
      companyName: p['name'],
      periodStart: DateTime.utc(year),
      periodEnd: DateTime.utc(year, 12, 31),
      consolidated: consolidated,
    );
    test('actual dated independent whole equity proof ${entry.key}', () {
      final rows = parse(body);
      expect(rows.length, 7);
      final proof = rows.first['html_provenance']['supportingPeriodEvidence'];
      expect(proof['currentProfit'], entry.value);
      expect(proof['periodStart'], '$year-01-01');
      expect(proof['periodEnd'], '$year-12-31');
      expect(proof['mode'], 'separate-independent-printed-equity-period-v1');
    });
    for (final mutation in {
      'wrong opening': body.replaceAll('$year.1.1(당기초)', '$year.2.1(당기초)'),
      'wrong closing': body.replaceAll('$year.12.31(당기말)', '$year.12.30(당기말)'),
      'missing whole equity table': body.replaceAll('자본변동표', '기타변동표'),
      'foreign units': body
          .replaceAll('단위 : 원', '단위 : USD')
          .replaceAll('단위:원', '단위:USD'),
    }.entries) {
      test('${mutation.key} ${entry.key}', () {
        expect(
          mutation.value,
          isNot(body),
          reason: 'mutation must change actual source',
        );
        expect(() => parse(mutation.value), throwsFormatException);
      });
    }
    test(
      'independent separate proof cannot establish CFS ${entry.key}',
      () =>
          expect(() => parse(body, consolidated: true), throwsFormatException),
    );
  }
}
