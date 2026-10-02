import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/imgt-explicit-revenue-null';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync()) as List).singleWhere(
    (r) => r['label'] == n,
  )['uri'],
);
List<Map<String, dynamic>> parse(
  bool cfs, {
  String? body,
  String corp = '01579020',
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw('cover'),
  statementHtml: body ?? raw(cfs ? 'cfs' : 'ofs'),
  coverSource: uri('cover'),
  statementSource: uri(cfs ? 'cfs' : 'ofs'),
  receipt: '20260330001850',
  corpCode: corp,
  companyName: '(주)아이엠지티',
  periodStart: DateTime.utc(2025),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: cfs,
);
void main() {
  for (final cfs in [false, true]) {
    test('explicit dash cannot be replaced with zero or prior $cfs', () {
      final body = raw(cfs ? 'cfs' : 'ofs');
      final changed = body.replaceFirstMapped(
        RegExp(
          r"(I\. 영업수익</TD>.*?<TD[^>]*>.*?</TD>.*?<TD[^>]*>)-",
          dotAll: true,
        ),
        (m) => '${m[1]}0',
      );
      expect(changed, isNot(body));
      expect(() => parse(cfs, body: changed), throwsFormatException);
    });
    test('actual $cfs six direct values and explicit dash remain distinct', () {
      final rows = parse(cfs);
      final missing = rows.singleWhere(
        (r) => r['account_nm'].toString().contains('영업수익'),
      );
      expect(missing['thstrm_amount'], isNull);
      expect(missing['html_provenance']['printedCurrentCells'], ['-']);
      expect(
        rows.where((r) => r['thstrm_amount'] != null).length,
        greaterThanOrEqualTo(6),
      );
      expect(
        rows.map((r) => r['thstrm_amount']).toSet(),
        containsAll({
          '15120306946',
          '75309334905',
          '-60189027959',
          '-5621738512',
          '-39965654941',
          '-4829577714',
        }),
      );
    });
    for (final mutation in [
      ['제16(당)기', '제17(당)기'],
      ['2025년 12월 31일', '2024년 12월 31일'],
      ['(단위 : 원)', '(단위 : USD)'],
      [
        cfs ? '2025년 1월 1일(당기초,수정전)' : '2025년 1월 1일(당기초, 수정전)',
        '2025년 1월 1일(당기초, 재작성)',
      ],
    ]) {
      test('explicit term/date/unit/restatement conflict $cfs $mutation', () {
        final body = raw(cfs ? 'cfs' : 'ofs');
        final changed = body.replaceAll(mutation[0], mutation[1]);
        expect(changed, isNot(body));
        expect(() => parse(cfs, body: changed), throwsFormatException);
      });
    }
    test(
      'wrong company $cfs rejects',
      () => expect(() => parse(cfs, corp: '01579021'), throwsFormatException),
    );
    test(
      'CE exact restatement label required $cfs',
      () => expect(
        () => parse(
          cfs,
          body: raw(cfs ? 'cfs' : 'ofs').replaceAll('당기초, 재작성', '당기초, 수정전'),
        ),
        throwsFormatException,
      ),
    );
    test(
      'CE current whole amount conflict $cfs',
      () => expect(
        () => parse(
          cfs,
          body: raw(cfs ? 'cfs' : 'ofs')
              .replaceAll('(60,189,027,959)', '(60,189,027,958)'),
        ),
        throwsFormatException,
      ),
    );
    test(
      'CFO missing is not permitted $cfs',
      () => expect(
        () => parse(
          cfs,
          body: raw(cfs ? 'cfs' : 'ofs').replaceAll('(4,829,577,714)', '-'),
        ),
        throwsFormatException,
      ),
    );
  }
}
