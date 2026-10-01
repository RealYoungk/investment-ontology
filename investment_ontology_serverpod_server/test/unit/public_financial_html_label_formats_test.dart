import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

List<Map<String, dynamic>> parseActual(String receipt, {String? cover}) {
  const root = 'test/fixtures/financial_html/label-formats';
  final fixtures =
      (jsonDecode(File('$root/evidence.json').readAsStringSync())
              as Map)['filings']
          as List;
  final f = fixtures.singleWhere((f) => f['rceptNo'] == receipt) as Map;
  final p = RegExp(r'(\d{4})\.(\d{2})').firstMatch(f['reportName'])!;
  final year = int.parse(p[1]!), month = int.parse(p[2]!);
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover ?? File('$root/$receipt/4.body').readAsStringSync(),
    statementHtml: File('$root/$receipt/5.body').readAsStringSync(),
    coverSource: Uri.parse(File('$root/$receipt/4.url.txt').readAsStringSync()),
    statementSource: Uri.parse(
      File('$root/$receipt/5.url.txt').readAsStringSync(),
    ),
    receipt: receipt,
    corpCode: f['corpCode'],
    companyName: f['name'],
    periodStart: DateTime.utc(year - 1, month + 1),
    periodEnd: DateTime.utc(year, month + 1, 0),
    consolidated: true,
  );
}

void main() {
  for (final (receipt, label, value) in [
    ('20250326000042', '수익(매출액)(주30)', '155880764900'),
    ('20230621000034', '영업수익', '4315281301'),
  ]) {
    test('exact primary printed revenue $receipt', () {
      final rows = parseActual(receipt);
      final r = rows.singleWhere(
        (r) =>
            (r['account_nm'] as String)
                .replaceAll(RegExp(r'\s+'), '')
                .replaceFirst(RegExp(r'^1\.\s*'), '') ==
            label,
      );
      expect(r['thstrm_amount'], value);
      expect(r['account_id'], isNull);
      expect(
        r['html_provenance'],
        containsPair('printedLabel', r['account_nm']),
      );
    });
  }
  test(
    'whole connected profit preserves sign and excludes owner components',
    () {
      final rows = parseActual('20230621000034');
      final r = rows.singleWhere(
        (r) => (r['account_nm'] as String).contains('연결당기순이익(손실)'),
      );
      expect(r['thstrm_amount'], '-3834733467');
      expect(r['account_id'], isNull);
    },
  );
  test('actual dot-format cover only permits exact expected period', () {
    const receipt = '20230622000218';
    expect(
      () => parseActual(receipt),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'past cover guard',
          'Annual current statement title period mismatch',
        ),
      ),
    );
    final cover = File(
      'test/fixtures/financial_html/label-formats/$receipt/4.body',
    ).readAsStringSync();
    expect(
      () => parseActual(
        receipt,
        cover: cover.replaceAll('2023.03.31', '2023.03.30'),
      ),
      throwsFormatException,
    );
    expect(
      () => parseActual(
        receipt,
        cover: cover.replaceAll('2023.03.31', '2023.02.31'),
      ),
      throwsFormatException,
    );
  });
}
