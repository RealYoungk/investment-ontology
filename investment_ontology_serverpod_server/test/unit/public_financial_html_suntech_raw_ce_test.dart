import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  String raw(String f) =>
      File('test/fixtures/financial_html/suntech-raw-ce/$f').readAsStringSync();
  List<Map<String, dynamic>> parse(
    bool cfs, {
    String? body,
    String corp = '00963000',
    String receipt = '20260317000808',
    String? url,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: raw('cover.html'),
    statementHtml: body ?? raw(cfs ? 'CFS.html' : 'OFS.html'),
    coverSource: Uri.parse(
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=1&offset=965&length=4492&dtd=dart4.xsd',
    ),
    statementSource: Uri.parse(
      url ??
          (cfs
              ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=19&offset=329146&length=114169&dtd=dart4.xsd'
              : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133658&eleId=21&offset=518605&length=97424&dtd=dart4.xsd'),
    ),
    receipt: receipt,
    corpCode: corp,
    companyName: '썬테크',
    periodStart: DateTime.utc(2025, 1, 1),
    periodEnd: DateTime.utc(2025, 12, 31),
    consolidated: cfs,
  );
  for (final cfs in [false, true]) {
    test('actual $cfs primary7 CE raw unknown only', () {
      final rows = parse(cfs);
      expect(rows.length, greaterThanOrEqualTo(7));
      expect(
        rows.map((r) => r['thstrm_amount']),
        containsAll(
          cfs
              ? [
                  '22931367836',
                  '19448274886',
                  '3483092950',
                  '21533148193',
                  '-1894112357',
                  '-2164078292',
                  '-321548450',
                ]
              : [
                  '14131185071',
                  '10897617782',
                  '3233567289',
                  '16401666683',
                  '28804006',
                  '-1757381648',
                  '695607919',
                ],
        ),
      );
      for (final r in rows) {
        final p = r['html_provenance'] as Map;
        expect(r['currency'], 'KRW');
        expect(p['unit'], '원');
        final ce = p['supportingPeriodEvidence'] as Map;
        expect(ce['unit'], isNull);
        expect(ce['currencyAssigned'], false);
        expect(ce['multiplierAssigned'], false);
        expect(ce['financialValuesStoredFromCE'], false);
      }
      expect(rows.every((r) => r['sj_div'] != 'CE'), isTrue);
    });
    for (final change in [
      'unit',
      'zero',
      'CEamount',
      'prior',
      'date',
      'duplicate',
      'corp',
      'receipt',
      'source',
    ]) {
      test('$cfs rejects $change', () {
        var b = raw(cfs ? 'CFS.html' : 'OFS.html');
        if (change == 'unit') {
          b = b.replaceAll('단위 : 원', '단위 : 천원');
        }
        if (change == 'zero') {
          b = b.replaceAll(cfs ? '2,164,078,292' : '1,757,381,648', '0');
        }
        if (change == 'CEamount') {
          b = b.replaceAll(cfs ? '3,483,092,950' : '3,233,567,289', '1');
        }
        if (change == 'prior') {
          b = b.replaceAll('제30기', '제29기');
        }
        if (change == 'date') {
          b = b.replaceAll('2025.12.31', '2024.12.31');
        }
        if (change == 'duplicate') {
          b = '$b$b';
        }
        expect(
          () => parse(
            cfs,
            body: b,
            corp: change == 'corp' ? '00963001' : '00963000',
            receipt: change == 'receipt' ? '20260318000344' : '20260317000808',
            url: change == 'source'
                ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260317000808&dcmNo=11133659'
                : null,
          ),
          throwsFormatException,
        );
      });
    }
  }
}
