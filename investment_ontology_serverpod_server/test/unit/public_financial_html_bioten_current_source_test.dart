import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/bioten-current-source';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String corp = '01352575',
  String receipt = '20260323000876',
  Uri? source,
  String? cover,
  bool cfs = false,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover'),
  statementHtml: body ?? raw('ofs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('ofs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '바이오텐(주)',
  periodStart: DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
void main() {
  test('actual Bioten OFS direct whole seven already parses with current annual CE guard', () {
    final rows = parse();
    expect(rows.length, 7);
    final expected = {
      '자산총계': '7186857157',
      '부채총계': '5184276696',
      '자본총계': '2002580461',
      '매출액': '3749057088',
      '영업이익(손실)': '-904728361',
      '당기순이익': '-831038793',
      '영업활동으로인한현금흐름': '-969511178',
    };
    for (final e in expected.entries) {
      final row = rows.singleWhere(
        (r) =>
            (r['account_nm'] as String)
                .replaceAll(RegExp(r'\s+'), '')
                .replaceFirst(RegExp(r'^[ⅠⅤⅩ.]+'), '') ==
            e.key,
      );
      expect(row['thstrm_amount'], e.value);
      expect(row['account_id'], null);
      expect(row['html_provenance']['source'], uri('ofs').toString());
    }
  });
}
