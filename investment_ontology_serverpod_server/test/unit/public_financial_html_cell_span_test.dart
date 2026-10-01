import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const cases = [
  ('20250321001022', '01023822', '메디젠휴먼케어', 2024),
  ('20240322000131', '00867034', '듀켐바이오', 2023),
];
String raw(String receipt, String name) =>
    File('test/fixtures/financial_html/cell-span/$receipt/$name.html')
        .readAsStringSync();
List<Map<String, dynamic>> actual(int i, {String? body}) {
  final c = cases[i];
  final proof = jsonDecode(
    File('test/fixtures/financial_html/cell-span/${c.$1}/proof.json')
        .readAsStringSync(),
  ) as Map;
  Uri uri(String name) => Uri.parse(
    (proof['sources'] as List).cast<Map>().singleWhere(
          (s) => s['label'] == name,
        )['url']
        as String,
  );
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: raw(c.$1, 'cover'),
    statementHtml: body ?? raw(c.$1, 'ofs'),
    coverSource: uri('cover'),
    statementSource: uri('ofs'),
    receipt: c.$1,
    corpCode: c.$2,
    companyName: c.$3,
    periodStart: DateTime.utc(c.$4, 1, 1),
    periodEnd: DateTime.utc(c.$4, 12, 31),
    consolidated: false,
  );
}

PublicFinancialHtmlSource source(int i) {
  final c = cases[i];
  final proof = jsonDecode(
    File('test/fixtures/financial_html/cell-span/${c.$1}/proof.json')
        .readAsStringSync(),
  ) as Map;
  Uri uri(String n) => Uri.parse(
    (proof['sources'] as List).cast<Map>().singleWhere(
          (x) => x['label'] == n,
        )['url']
        as String,
  );
  return PublicFinancialHtmlSource(
    sourceReceipt: c.$1,
    correctionReceipt: null,
    correctionSource: null,
    coverHtml: raw(c.$1, 'cover'),
    coverSource: uri('cover'),
    statementHtml: raw(c.$1, 'ofs'),
    statementSource: uri('ofs'),
    periodStart: DateTime.utc(c.$4, 1, 1),
    periodEnd: DateTime.utc(c.$4, 12, 31),
    rows: actual(i),
  );
}

void main() {
  for (var i = 0; i < cases.length; i++) {
    final index = i;
    test('actual CE source ${cases[i].$1}', () {
      final rows = actual(index);
      expect(rows.length, greaterThanOrEqualTo(7));
      expect(rows.every((r) => r['account_id'] == null), true);
    });
    test('wrong current dates still reject ${cases[i].$1}', () {
      final b = raw(
        cases[index].$1,
        'ofs',
      ).replaceAll('${cases[index].$4}년', '${cases[index].$4 - 1}년');
      expect(() => actual(index, body: b), throwsFormatException);
    });
    test('core table excessive span still rejects ${cases[i].$1}', () {
      final b = raw(cases[index].$1, 'ofs').replaceAll(
        RegExp(r'<TD\b', caseSensitive: false),
        "<TD colspan='20'",
      );
      expect(() => actual(index, body: b), throwsFormatException);
    });
  }
}
