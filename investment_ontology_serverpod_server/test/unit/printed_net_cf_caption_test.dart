import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:test/test.dart';

void main() {
  const directory = 'assets/financial_source_cache/20220317000713-ofs';
  final manifest =
      jsonDecode(File('$directory/manifest.json').readAsStringSync()) as Map;
  final sources = manifest['sources'] as List;
  Uri source(String label) =>
      Uri.parse(sources.singleWhere((s) => s['label'] == label)['url']);
  final cover = File('$directory/cover.html').readAsStringSync();
  final body = File('$directory/ofs.html').readAsStringSync();
  List<Map<String, dynamic>> parse(String html) =>
      PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: html,
        coverSource: source('cover'),
        statementSource: source('ofs'),
        receipt: '20220317000713',
        corpCode: manifest['corpCode'],
        companyName: '하이트진로홀딩스(주)',
        periodStart: DateTime.utc(2021),
        periodEnd: DateTime.utc(2021, 12, 31),
        consolidated: false,
      );
  test('blank section caption uses only the printed current net CFO total', () {
    final rows = parse(body);
    expect(rows.length, 7);
    expect(
      rows.singleWhere((r) => r['account_nm'] == '영업수익:')['thstrm_amount'],
      '40214502759',
    );
    final cfo = rows.singleWhere((r) => r['sj_div'] == 'CF');
    expect(cfo['account_nm'], '영업활동으로 인한 순현금흐름액');
    expect(cfo['thstrm_amount'], '18142951111');
  });
  test('duplicate printed net total remains ambiguous', () {
    final row = RegExp(
      r'<TR\b[^>]*>(?:(?!</TR>).)*영업활동으로 인한 순현금흐름액(?:(?!</TR>).)*</TR>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(body)!;
    expect(
      () => parse(body.replaceRange(row.end, row.end, row[0]!)),
      throwsFormatException,
    );
  });
  test('a renamed component cannot substitute for whole net CFO', () {
    final changed = body.replaceAll('영업활동으로 인한 순현금흐름액', '영업활동으로 인한 현금흐름 일부');
    expect(changed, isNot(body));
    expect(() => parse(changed), throwsFormatException);
  });
  test('a revenue component cannot substitute for gross revenue', () {
    final changed = body.replaceAll('영업수익:', '배당금 영업수익:');
    expect(changed, isNot(body));
    expect(() => parse(changed), throwsFormatException);
  });
  test('malformed current net CFO amount remains rejected', () {
    final changed = body.replaceFirst('18,142,951,111', '18 142 951 111');
    expect(changed, isNot(body));
    expect(() => parse(changed), throwsFormatException);
  });
}
