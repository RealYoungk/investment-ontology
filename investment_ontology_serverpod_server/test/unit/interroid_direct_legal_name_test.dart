import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/issuer-legalname/20250325000306';
String raw(String n) => File('$root/$n.html').readAsStringSync();
Uri uri(String n) => Uri.parse(
  (jsonDecode(File('$root/proof.json').readAsStringSync())['sources'] as List)
      .singleWhere((v) => v['label'] == n)['url'],
);
PublicIssuerLegalName proof([String? overview]) => PublicIssuerLegalName(
  shellHtml: raw('shell'),
  shellSource: uri('shell'),
  overviewHtml: overview ?? raw('overview'),
  overviewSource: uri('overview'),
);
Map<String, String>? verify({
  String? overview,
  String corp = '01290132',
  String receipt = '20250325000306',
  String printed = '주식회사에이아이더뉴트리진',
}) => proof(overview).verify(
  receipt: receipt,
  corpCode: corp,
  masterName: '주식회사 인터로이드',
  printedName: printed,
  coverSource: uri('cover'),
  coverHtml: raw('cover'),
  periodStart: DateTime.utc(2024, 1, 1),
  periodEnd: DateTime.utc(2024, 12, 31),
);
List<Map<String, dynamic>> rows([String? statement]) =>
    PublicFinancialHtml.parseStandardAnnual(
      coverHtml: raw('cover'),
      statementHtml: statement ?? raw('ofs'),
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      receipt: '20250325000306',
      corpCode: '01290132',
      companyName: '주식회사 인터로이드',
      periodStart: DateTime.utc(2024, 1, 1),
      periodEnd: DateTime.utc(2024, 12, 31),
      consolidated: false,
      issuerProof: proof(),
    );
void main() {
  test('actual inline direct declaration binds historical printed name and whole seven', () {
    expect(verify()?['declaredLegalName'], '주식회사 에이아이더뉴트리진');
    final r = rows();
    expect(r.length, 8);
    expect(r.any((v) => v['thstrm_amount'] == '-3373662856'), isTrue);
    expect(r.every((v) => v['account_id'] == null), isTrue);
  });
  test('wrong source identity and printed name fail closed', () {
    expect(verify(corp: '00000000'), isNull);
    expect(verify(receipt: '20250325000307'), isNull);
    expect(verify(printed: '다른회사'), isNull);
  });
  for (final modifier in ['예정인 ', '상정된 ', '가정된 ', '타회사의 ', '역사상 ']) {
    test('rejects $modifier declaration', () {
      expect(
        verify(
          overview: raw('overview')
              .replaceFirst("당사의 법적·상업적 명칭은", '$modifier당사의 법적·상업적 명칭은'),
        ),
        isNull,
      );
    });
  }
  test('English only is not Korean legal name', () {
    expect(
      verify(
        overview: raw('overview').replaceFirst("당사의 법적·상업적 명칭은", '당사의 영문 명칭은'),
      ),
      isNull,
    );
  });
  test('CF component or other activity does not satisfy CFO', () {
    for (final name in ['투자활동 순현금흐름', '영업활동 순현금흐름 구성요소', '영업활동 순현금흐름(주석)']) {
      expect(
        () => rows(raw('ofs').replaceAll('영업활동 순현금흐름', name)),
        throwsFormatException,
      );
    }
  });
  test('actual capex is directly printed and all eight current values remain exact', () {
    final parsed = rows();
    final expected = [
      '13696583931',
      '9355487006',
      '4341096925',
      '10341927448',
      '-3298968631',
      '-7634644220',
      '-3373662856',
      '-12196328',
    ];
    expect(parsed.map((r) => r['thstrm_amount']), unorderedEquals(expected));
    expect(parsed.every((r) => r['currency'] == 'KRW'), isTrue);
  });
  test(
    'wrong financial dates currency and balance retain strict rejection',
    () {
      for (final changed in [
        raw('ofs').replaceAll('2024년 12월 31일', '2023년 12월 31일'),
        raw('ofs').replaceAll('(단위: 원)', '(단위: USD)'),
        raw('ofs').replaceAll('13,696,583,931', '13,696,583,930'),
      ]) {
        expect(() => rows(changed), throwsFormatException);
      }
    },
  );
}
