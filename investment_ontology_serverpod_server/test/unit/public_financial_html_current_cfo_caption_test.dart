import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  for (final receipt in [
    '20230317000745',
    '20240320001114',
    '20250314001145',
  ]) {
    final root =
        'test/fixtures/financial_html/current-empty-cfo-captions/$receipt';
    final proof =
        jsonDecode(File('$root/proof.json').readAsStringSync()) as Map;
    final original = File('$root/ofs.html').readAsStringSync();
    final year = int.parse((proof['actualPeriod'] as String).split('.').first);
    List<Map<String, dynamic>> parse(String body) =>
        PublicFinancialHtml.parseStandardAnnual(
          coverHtml: File('$root/cover.html').readAsStringSync(),
          statementHtml: body,
          coverSource: Uri.parse(proof['coverUrl']),
          statementSource: Uri.parse(proof['ofsUrl']),
          receipt: receipt,
          corpCode: proof['corp'],
          companyName: proof['name'],
          periodStart: DateTime.utc(year),
          periodEnd: DateTime.utc(year, 12, 31),
          consolidated: false,
        );
    test('$receipt direct net CFO instead of blank caption', () {
      final rows = parse(original);
      expect(
        rows.map((r) => [r['account_nm'], r['thstrm_amount']]).toList(),
        proof['expectedRows'],
      );
      final cfo = rows.singleWhere((r) => r['account_nm'] == '영업활동으로부터의 순현금유출');
      expect(cfo['account_id'], isNull);
      expect(cfo['html_provenance']['source'], proof['ofsUrl']);
      expect(rows.any((r) => r['account_nm'] == '영업활동 현금흐름'), isFalse);
    });
    test('$receipt missing net total cannot substitute generated cash', () {
      final changed = original.replaceAll('영업활동으로부터의 순현금유출', '영업에서 창출된 현금흐름');
      expect(changed, isNot(original));
      expect(() => parse(changed), throwsFormatException);
    });
    test('$receipt unavailable total cannot become zero or prior', () {
      final value =
          (proof['expectedRows'] as List).singleWhere(
                (r) => r[0] == '영업활동으로부터의 순현금유출',
              )[1]
              as String;
      final digits = value.replaceAll('-', '');
      final formatted = digits.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
      final changed = original.replaceFirst('($formatted)', '-');
      expect(changed, isNot(original));
      expect(() => parse(changed), throwsFormatException);
    });
  }
}
