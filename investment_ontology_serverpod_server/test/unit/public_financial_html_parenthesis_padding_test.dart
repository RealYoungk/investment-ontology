import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const root =
      'test/fixtures/financial_html/annual-parenthesis-padding/20260331004637';
  final proof = jsonDecode(File('$root/proof.json').readAsStringSync()) as Map;
  Uri source(String label) => Uri.parse(
    (proof['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  final original = File('$root/ofs.html').readAsStringSync();
  List<Map<String, dynamic>> parse(String body) =>
      PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$root/cover.html').readAsStringSync(),
        statementHtml: body,
        coverSource: source('cover'),
        statementSource: source('ofs'),
        receipt: '20260331004637',
        corpCode: '01353848',
        companyName: '이노벡스',
        periodStart: DateTime.utc(2025),
        periodEnd: DateTime.utc(2025, 12, 31),
        consolidated: false,
      );
  test('actual source bytes match preserved official SHA256', () {
    for (final label in ['cover', 'ofs']) {
      final expected = (proof['sources'] as List).singleWhere(
        (s) => s['label'] == label,
      )['sha256'];
      expect(
        sha256.convert(File('$root/$label.html').readAsBytesSync()).toString(),
        expected,
      );
    }
  });
  test('actual Innovex 2025 conflicting printed term remains rejected', () {
    expect(
      () => parse(original),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'remaining rejection',
          'Annual primary statement title mismatch',
        ),
      ),
    );
  });
  test('supported annual whole-company source accepts parenthesis padding', () {
    const base = 'test/fixtures/financial_html/innovex-crfood/20250320001369';
    final knownProof =
        jsonDecode(File('$base/proof.json').readAsStringSync()) as Map;
    Uri knownSource(String label) => Uri.parse(
      (knownProof['sources'] as List).singleWhere(
        (s) => s['label'] == label,
      )['url'],
    );
    final body = File('$base/ofs.html')
        .readAsStringSync()
        .replaceAll('(2,650,611,791)', '( 2,650,611,791 )');
    final rows = PublicFinancialHtml.parseStandardAnnual(
      coverHtml: File('$base/cover.html').readAsStringSync(),
      statementHtml: body,
      coverSource: knownSource('cover'),
      statementSource: knownSource('ofs'),
      receipt: '20250320001369',
      corpCode: '01353848',
      companyName: '이노벡스',
      periodStart: DateTime.utc(2024),
      periodEnd: DateTime.utc(2024, 12, 31),
      consolidated: false,
    );
    expect(
      rows.firstWhere((r) => r['account_nm'] == '자본총계')['thstrm_amount'],
      '-2650611791',
    );
  });
  test('digit whitespace remains rejected', () {
    expect(
      () => parse(original.replaceAll('10,584,213,475 ', '10,584,213,4 75')),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'malformed digits',
          'Malformed annual current amount',
        ),
      ),
    );
  });
}
