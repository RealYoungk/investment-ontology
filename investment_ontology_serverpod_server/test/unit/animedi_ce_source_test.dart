import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/animedi_ce_source.dart';

void main() {
  for (final receipt in AnimediCeSource.profiles.keys) {
    final p = AnimediCeSource.profiles[receipt]!, year = int.parse(p['year']!);
    final dir = 'assets/financial_source_cache/$receipt-ofs';
    final cover = File('$dir/cover.html').readAsStringSync(),
        body = File('$dir/ofs.html').readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? source,
      String corp = '01507810',
      bool cfs = false,
      DateTime? end,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover,
      statementHtml: source ?? body,
      coverSource: Uri.parse(p['cover']!),
      statementSource: Uri.parse(p['statement']!),
      receipt: receipt,
      corpCode: corp,
      companyName: '애니메디솔루션 주식회사',
      periodStart: DateTime.utc(year),
      periodEnd: end ?? DateTime.utc(year, 12, 31),
      consolidated: cfs,
    );
    test('$receipt exact printed seven and original CE provenance', () {
      final rows = parse();
      final expected = year == 2023
          ? [
              '7473929363',
              '3939848819',
              '3534080544',
              '1123621115',
              '-3961736811',
              '-4419372266',
              '-3336089290',
            ]
          : [
              '9264697013',
              '3836415588',
              '5428281425',
              '655390090',
              '-6470740465',
              '-7014810066',
              '-5385272003',
            ];
      expect(rows.take(7).map((x) => x['thstrm_amount']).toList(), expected);
      expect(rows.every((x) => x['account_id'] == null), true);
      for (final r in rows) {
        final proof =
            (r['html_provenance'] as Map)['supportingPeriodEvidence'] as Map;
        expect(proof['literalSeparatorRowsExcluded'], 6);
        expect(proof['originalRawUnchanged'], true);
        expect(proof['sourceSHA'], p['statementSHA']);
      }
      expect(
        jsonDecode(
          File('$dir/manifest.json').readAsStringSync(),
        )['periodStart'],
        '$year-01-01',
      );
    });
    for (final change in <String, String>{
      'numeric': '총포괄손익:1',
      'subtotal': '자본에 직접 반영된 소유주와의 거래:1',
      'span': "colspan='8'",
      'unit': '단위: 천원',
      'profit': '당기순손실X',
    }.entries) {
      test('$receipt ${change.key} contradiction rejected', () {
        final altered = switch (change.key) {
          'numeric' => body.replaceAll('총포괄손익:', change.value),
          'subtotal' => body.replaceAll('자본에 직접 반영된 소유주와의 거래:', change.value),
          'span' => body.replaceAll("colspan='7'", change.value),
          'unit' => body.replaceAll('단위: 원', change.value),
          _ => body.replaceAll('당기순손실', change.value),
        };
        expect(altered, isNot(body));
        expect(() => parse(source: altered), throwsFormatException);
      });
    }
    test('$receipt wrongowner basis period rejected', () {
      expect(() => parse(corp: '00126380'), throwsFormatException);
      expect(() => parse(cfs: true), throwsFormatException);
      expect(
        () => parse(end: DateTime.utc(year - 1, 12, 31)),
        throwsFormatException,
      );
    });
  }
}
