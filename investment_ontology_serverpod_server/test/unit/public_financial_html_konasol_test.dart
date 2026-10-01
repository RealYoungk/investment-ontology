import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

String raw(String n) =>
    File('test/fixtures/financial_html/konasol/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  ((jsonDecode(
                File('test/fixtures/financial_html/konasol/proof.json')
                    .readAsStringSync(),
              ) as Map)['sources']
              as List)
          .cast<Map>()
          .singleWhere((s) => s['label'] == n)['url']
      as String,
);
List<Map<String, dynamic>> parse({
  String? body,
  String corp = '00666329',
  String receipt = '20260331004755',
  bool consolidated = false,
  Uri? source,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw('cover'),
  statementHtml: body ?? raw('ofs'),
  coverSource: uri('cover'),
  statementSource: source ?? uri('ofs'),
  receipt: receipt,
  corpCode: corp,
  companyName: '주식회사 코나솔',
  periodStart: DateTime.utc(2025, 1, 1),
  periodEnd: DateTime.utc(2025, 12, 31),
  consolidated: consolidated,
);
PublicFinancialHtmlSource actualSource() => PublicFinancialHtmlSource(
  sourceReceipt: '20260331004755',
  correctionReceipt: null,
  correctionSource: null,
  coverHtml: raw('cover'),
  coverSource: uri('cover'),
  statementHtml: raw('ofs'),
  statementSource: uri('ofs'),
  periodStart: DateTime.utc(2025, 1, 1),
  periodEnd: DateTime.utc(2025, 12, 31),
  rows: parse(),
);
void main() {
  test('actual exact Konasol source crosschecks split headers and CE current dates', () {
    final r = parse();
    expect(r.length, greaterThanOrEqualTo(7));
    expect(
      r.singleWhere(
        (x) =>
            x['sj_div'] == 'CIS' &&
            x['account_nm'].toString().contains('당기순이익'),
      )['thstrm_amount'],
      '18014062159',
    );
    expect(r.every((x) => x['account_id'] == null), true);
    expect(
      (r.first['html_provenance'] as Map)['supportingPeriodEvidence'],
      isNotNull,
    );
  });
  for (final mutation in <String, String>{
    'start': '2025년 01월 01일(보고금액)',
    'end': '2025년 12월 31일(당기말)',
    'equity': '31,274,647,196',
    'profit': '18,014,062,159',
    'year': '(2025년)',
    'term': '(제29기)',
  }.entries) {
    test('reject changed ${mutation.key}', () {
      final b = mutation.key == 'profit'
          ? raw('ofs').replaceFirst(mutation.value, '1')
          : raw('ofs').replaceAll(
              mutation.value,
              mutation.key == 'equity' || mutation.key == 'profit'
                  ? '1'
                  : mutation.value
                        .replaceAll('2025', '2024')
                        .replaceAll('29', '28'),
            );
      expect(() => parse(body: b), throwsFormatException);
    });
  }
  test('wrong corporate scope rejects', () {
    expect(() => parse(corp: '00666328'), throwsFormatException);
  });
  test('wrong basis rejects', () {
    expect(() => parse(consolidated: true), throwsFormatException);
  });
  test('wrong source document rejects', () {
    expect(
      () => parse(
        source: uri('ofs').replace(
          queryParameters: {...uri('ofs').queryParameters, 'dcmNo': '11215245'},
        ),
      ),
      throwsFormatException,
    );
  });
  test('same-column year binding rejects a single shifted current year', () {
    expect(
      () => parse(body: raw('ofs').replaceFirst('(2025년)', '(2024년)')),
      throwsFormatException,
    );
  });
  test('duplicated supporting CE table rejects', () {
    final body = raw('ofs');
    final tables = RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(body).toList();
    final ce = tables[5];
    final duplicate = body.replaceRange(
      ce.start,
      ce.end,
      '${ce.group(0)}${ce.group(0)}',
    );
    expect(() => parse(body: duplicate), throwsFormatException);
  });
  test('duplicated CE current closing date rejects', () {
    expect(
      () => parse(
        body: raw('ofs').replaceAll('2024년 12월 31일(전기말)', '2025년 12월 31일(당기말)'),
      ),
      throwsFormatException,
    );
  });
}
