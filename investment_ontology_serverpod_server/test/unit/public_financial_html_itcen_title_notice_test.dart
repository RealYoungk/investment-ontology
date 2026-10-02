import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/itcen_primary_title_source.dart';

import 'package:test/test.dart';

import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';

void main() {
  const d =
      'test/fixtures/financial_html/direct-issuer-name-clauses/20230317000589';
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
        periodStart: DateTime.utc(2022),
        periodEnd: DateTime.utc(2022, 12, 31),
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
        '18514649493',
        '10415681439',
        '8098968054',
        '39515795103',
        '2171898590',
        '2219605920',
        '4910154628',
        '2174388262',
      ]),
    );
  });
  for (final pair in {
    'currentheader': '제 12(당) 기',
    'ceprofit': '2,219,605,920',
    'ceequity': '8,098,968,054',
    'period': '2022.12.31 (당기말)',
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
    String receipt = '20230317000589',
    String corp = '01113499',
    bool cfs = false,
    int year = 2022,
    String term = '12',
    Uri? source,
  }) => ItcenPrimaryTitleSource.eligible(
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
    expect(eligible(year: 2021), isFalse);
    expect(eligible(term: '11'), isFalse);
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
      () => ItcenPrimaryTitleSource.verifyRaw(raw('cover'), raw('ofs')),
      returnsNormally,
    );
    expect(
      () => ItcenPrimaryTitleSource.verifyRaw('${raw('cover')} ', raw('ofs')),
      throwsFormatException,
    );
    expect(
      () => ItcenPrimaryTitleSource.verifyRaw(raw('cover'), '${raw('ofs')} '),
      throwsFormatException,
    );
  });
  test('direct title table beats later approval paragraph mention', () {
    final before = raw('ofs').substring(0, raw('ofs').indexOf('과'));
    // Explicit minimal structural replica, not a financial source fixture.
    const replica =
        '<TABLE><TR><TD>재 무 상 태 표</TD></TR><TR><TD>제12(당)기 2022년12월31일현재</TD></TR></TABLE><P>※상기 제12기 재무상태표에 대한 사항은 승인 전입니다.</P>';
    expect(
      ItcenPrimaryTitleSource.primaryPrefix(replica, 'BS'),
      contains('제12(당)기2022년12월31일현재'),
    );
    expect(
      () => ItcenPrimaryTitleSource.primaryPrefix(
        '<P>재무상태표 제12기2022년12월31일현재</P>',
        'BS',
      ),
      throwsFormatException,
    );
    expect(
      () => ItcenPrimaryTitleSource.primaryPrefix(replica, 'CIS'),
      throwsFormatException,
    );
    expect(before, isNotEmpty);
  });
}
