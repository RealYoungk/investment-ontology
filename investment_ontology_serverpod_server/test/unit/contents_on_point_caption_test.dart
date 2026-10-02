import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/contents_on_corroborated_flow_period.dart';

void main() {
  for (final entry in ContentsOnCorroboratedFlowPeriod.profiles.entries) {
    final p = entry.value, r = entry.key;
    final cover = File('assets/financial_source_cache/$r-ofs/cover.html')
        .readAsStringSync();
    final body = File('assets/financial_source_cache/$r-ofs/ofs.html')
        .readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? c,
      String? b,
      String? corp,
      bool cfs = false,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: c ?? cover,
      statementHtml: b ?? body,
      coverSource: Uri.parse(p.coverUri),
      statementSource: Uri.parse(p.bodyUri),
      receipt: r,
      corpCode: corp ?? '00991225',
      companyName: '(주)더콘텐츠온',
      periodStart: DateTime.utc(p.year, 1, 1),
      periodEnd: DateTime.utc(p.year, 12, 31),
      consolidated: cfs,
    );
    test(
      '$r actual point captions require independently dated CE and cash',
      () {
        final rows = parse();
        expect(rows.length, 8);
        final cells =
            jsonDecode(
                  File(
                    'assets/financial_source_cache/$r-ofs/current-cell-evidence.json',
                  ).readAsStringSync(),
                )['rows']
                as List;
        for (final cell in cells) {
          final actual = rows.singleWhere(
            (row) =>
                (row['account_nm'] as String).replaceAll(RegExp(r'\s+'), '') ==
                cell['printedLabel'],
          );
          expect(actual['thstrm_amount'], cell['amount']);
          expect(actual['account_id'], null);
        }

        final proof =
            (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
                as Map;
        expect(proof['flowCaptionPrintedStart'], false);
        expect(proof['periodStart'], '${p.year}-01-01');
      },
    );
    for (final token in [
      '${p.year}.01.01',
      '${p.year}.12.31',
      '단위',
    ]) {
      test('$r independent source conflict $token', () {
        final changed = body.replaceAll(token, 'CONFLICT');
        expect(changed, isNot(body));
        expect(() => parse(b: changed), throwsFormatException);
      });
    }
    final cells =
        jsonDecode(
              File(
                'assets/financial_source_cache/$r-ofs/current-cell-evidence.json',
              ).readAsStringSync(),
            )['rows']
            as List;
    for (final cell in cells) {
      test('$r direct current monetary conflict ${cell['printedLabel']}', () {
        final changed = body.replaceAll(
          cell['currentCell'] as String,
          '123,456,789',
        );
        expect(changed, isNot(body));
        expect(() => parse(b: changed), throwsFormatException);
      });
    }
    test('$r wrong owner/basis and missing current CE rejected', () {
      expect(() => parse(corp: '00000000'), throwsFormatException);
      expect(() => parse(cfs: true), throwsFormatException);
      expect(
        () =>
            parse(b: body.replaceAll('${p.year}.01.01', '${p.year - 1}.01.01')),
        throwsFormatException,
      );
      expect(
        () => parse(c: cover.replaceAll('01월', '02월')),
        throwsFormatException,
      );
    });
  }
}
