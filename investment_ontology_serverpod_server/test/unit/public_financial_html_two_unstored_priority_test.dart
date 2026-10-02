import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  for (final receipt in ['20230321001265', '20220819000262']) {
    test('actual OFS seven whole core amounts and source proof $receipt', () {
      final dir = 'test/fixtures/financial_html/two-unstored-priority/$receipt';
      final reviewed =
          jsonDecode(File('$dir/reviewed-core.json').readAsStringSync()) as Map;
      final proof =
          jsonDecode(File('$dir/proof.json').readAsStringSync()) as Map;
      final sources = proof['sources'] as List;
      String url(String label) =>
          sources.singleWhere((s) => s['label'] == label)['url'];
      for (final label in ['cover', 'ofs']) {
        expect(
          sha256.convert(File('$dir/$label.html').readAsBytesSync()).toString(),
          sources.singleWhere((s) => s['label'] == label)['sha256'],
        );
      }
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$dir/cover.html').readAsStringSync(),
        statementHtml: File('$dir/ofs.html').readAsStringSync(),
        coverSource: Uri.parse(url('cover')),
        statementSource: Uri.parse(url('ofs')),
        receipt: receipt,
        corpCode: reviewed['corpCode'],
        companyName: reviewed['companyName'],
        periodStart: DateTime.parse(reviewed['start']),
        periodEnd: DateTime.parse(reviewed['end']),
        consolidated: false,
      );
      expect(rows, hasLength((reviewed['rows'] as List).length));
      expect(rows.length, greaterThanOrEqualTo(7));
      for (final expected in reviewed['rows'] as List) {
        final row = rows.singleWhere(
          (r) => r['account_nm'] == expected['label'],
        );
        expect(row['thstrm_amount'], expected['amount']);
        expect(row['sj_div'], expected['statement']);
        expect(row['account_id'], isNull);
        expect(row['currency'], 'KRW');
        final provenance = row['html_provenance'] as Map;
        expect(provenance['source'], url('ofs'));
        expect(provenance['basis'], 'OFS');
        expect(
          provenance['periodStart'],
          (reviewed['start'] as String).substring(0, 10),
        );
        expect(
          provenance['periodEnd'],
          (reviewed['end'] as String).substring(0, 10),
        );
        expect(provenance['printedLabel'], expected['label']);
        expect(provenance['printedCurrentCells'], isNotEmpty);
      }
      final bs = rows.where((r) => r['sj_div'] == 'BS').toList();
      expect(
        BigInt.parse(bs[0]['thstrm_amount']),
        BigInt.parse(bs[1]['thstrm_amount']) +
            BigInt.parse(bs[2]['thstrm_amount']),
      );
    });
  }
}
