import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/redwoods_blank_header_source.dart';

import 'package:test/test.dart';

import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';

void main() {
  const d =
      'test/fixtures/financial_html/direct-issuer-name-clauses/20250321001825';
  final p = jsonDecode(File('$d/evidence.json').readAsStringSync());
  Uri url(String label) => Uri.parse(
    (p['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  String raw(String label) => File('$d/$label.html').readAsStringSync();
  List<Map<String, dynamic>> parse({String? body, Uri? source, String? code}) =>
      PublicFinancialHtml.parseStandardAnnual(
        coverHtml: raw('cover'),
        statementHtml: body ?? raw('ofs'),
        coverSource: url('cover'),
        statementSource: source ?? url('ofs'),
        receipt: p['receipt'],
        corpCode: code ?? p['corpCode'],
        companyName: p['masterName'],
        periodStart: DateTime.utc(2024),
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: false,
        issuerProof: PublicIssuerLegalName(
          shellHtml: raw('shell'),
          shellSource: url('shell'),
          overviewHtml: raw('issuer-overview'),
          overviewSource: url('issuer-overview'),
        ),
      );
  test('actual whole7 and supporting CE', () {
    final rows = parse();
    expect(rows.length, 8);
    final values = rows.map((r) => r['thstrm_amount']).toSet();
    expect(
      values,
      containsAll([
        '27857185529',
        '24984837907',
        '2872347622',
        '13636364',
        '-2779552869',
        '-5273584977',
        '-2360520418',
      ]),
    );
  });
  for (final pair in {
    'currentheader': '제15기말',
    'ceprofit': '(5,273,584,977)',
    'ceequity': '2,872,347,622',
    'period': '2024년 12월 31일(당기말)',
  }.entries) {
    test('reject altered ${pair.key}', () {
      expect(
        () => parse(body: raw('ofs').replaceAll(pair.value, '원문변조')),
        throwsFormatException,
      );
    });
  }
  test(
    'wrong company',
    () => expect(() => parse(code: '99999999'), throwsFormatException),
  );
  bool eligible({
    String receipt = '20250321001825',
    String corp = '00990396',
    bool cfs = false,
    int year = 2024,
    String term = '15',
    Uri? source,
  }) => RedwoodsBlankHeaderSource.eligible(
    receipt: receipt,
    corpCode: corp,
    consolidated: cfs,
    start: DateTime.utc(year),
    end: DateTime.utc(year, 12, 31),
    term: term,
    source: source ?? url('ofs'),
  );
  test('exact source scope and wrong receipt/basis/year/term/coordinates', () {
    expect(eligible(), isTrue);
    expect(eligible(receipt: '20250321001826'), isFalse);
    expect(eligible(corp: '99999999'), isFalse);
    expect(eligible(cfs: true), isFalse);
    expect(eligible(year: 2023), isFalse);
    expect(eligible(term: '14'), isFalse);
    for (final key in ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length']) {
      expect(
        eligible(
          source: url('ofs').replace(
            queryParameters: {...url('ofs').queryParameters, key: '999'},
          ),
        ),
        isFalse,
      );
    }
    expect(eligible(source: url('ofs').replace(host: 'example.com')), isFalse);
  });
  test('unchanged official cover/body SHA required even whitespace change', () {
    expect(
      () => RedwoodsBlankHeaderSource.verifyRaw(raw('cover'), raw('ofs')),
      returnsNormally,
    );
    expect(
      () => RedwoodsBlankHeaderSource.verifyRaw('${raw('cover')} ', raw('ofs')),
      throwsFormatException,
    );
    expect(
      () => RedwoodsBlankHeaderSource.verifyRaw(raw('cover'), '${raw('ofs')} '),
      throwsFormatException,
    );
  });
}
