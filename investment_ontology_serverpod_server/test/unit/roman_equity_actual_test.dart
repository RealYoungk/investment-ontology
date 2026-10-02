import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/annual_equity_period.dart';

void main() {
  const dir = 'test/fixtures/financial_html/roman-equity';
  final es = jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
  for (final e in es) {
    test('${e['receipt']} actual Roman/dotted closing equity source', () {
      final r = e['receipt'];
      List<Map<String, dynamic>> parse() =>
          PublicFinancialHtml.parseStandardAnnual(
            coverHtml: File('$dir/$r/cover.html').readAsStringSync(),
            statementHtml: File('$dir/$r/ofs.html').readAsStringSync(),
            coverSource: Uri.parse(e['coverUrl']),
            statementSource: Uri.parse(e['ofsUrl']),
            receipt: r,
            corpCode: e['corp'],
            companyName: e['name'],
            periodStart: DateTime.utc(e['year']),
            periodEnd: DateTime.utc(e['year'], 12, 31),
            consolidated: false,
          );
      if (e['corp'] == '00139214') {
        expect(
          parse,
          throwsA(
            isA<FormatException>().having(
              (x) => x.message,
              'reason',
              'Annual primary core missing or balance mismatch',
            ),
          ),
        );
      } else {
        final rows = parse();
        expect(rows.length, inInclusiveRange(7, 8));
        final proof = rows.first['html_provenance']['supportingPeriodEvidence'];
        expect(proof['periodEnd'], '${e['year']}-12-31');
      }
    });
    for (final mutation in [
      'wrong-current-closing',
      'whole-total-missing',
      'wrong-currency',
      'unrecognized-numbering',
    ]) {
      test('${e['receipt']} CE independent evidence rejects $mutation', () {
        final original = File('$dir/${e['receipt']}/ofs.html')
            .readAsStringSync();
        var body = original;
        switch (mutation) {
          case 'wrong-current-closing':
            body = body.replaceAll(
              RegExp(
                "${e['year']}(?:년|\\.)(?:\\s|&nbsp;)*12(?:월|\\.)(?:\\s|&nbsp;)*31",
              ),
              '${e['year']}.12.30',
            );
          case 'whole-total-missing':
            body = body.replaceAll(RegExp(r'총(?:\s|&nbsp;)*계'), '임의값');
          case 'wrong-currency':
            body = body.replaceAllMapped(
              RegExp(r'(단위\s*[:：]\s*)원'),
              (m) => '${m[1]}USD',
            );
          case 'unrecognized-numbering':
            if (e['corp'] != '00139214') return;
            body = body
                .replaceAll('2. 당기순이익', '임의. 당기순이익')
                .replaceAll('2.당기순이익', '임의.당기순이익');
        }
        expect(body == original, isFalse);
        expect(
          AnnualEquityPeriod.verify(
            scope: body,
            term: '0',
            start: DateTime.utc(e['year']),
            end: DateTime.utc(e['year'], 12, 31),
            consolidated: false,
          ),
          isNull,
        );
      });
    }
  }
}
