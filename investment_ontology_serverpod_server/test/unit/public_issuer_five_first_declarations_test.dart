import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/direct-issuer-seven';
const positives = [
  '20240814001895',
  '20241104000113',
  '20230328000161',
  '20240808000099',
  '20230323000665',
];
String raw(String r, String n) => File('$root/$r/$n.html').readAsStringSync();
Map meta(String r) =>
    jsonDecode(File('$root/$r/proof.json').readAsStringSync());
Uri uri(String r, String n) => Uri.parse(
  (meta(r)['sources'] as List).singleWhere((s) => s['label'] == n)['url'],
);
PublicIssuerLegalName evidence(String r, {String? overview, Uri? source}) =>
    PublicIssuerLegalName(
      shellHtml: raw(r, 'shell'),
      shellSource: uri(r, 'shell'),
      overviewHtml: overview ?? raw(r, 'overview'),
      overviewSource: source ?? uri(r, 'overview'),
    );
Map<String, String>? verify(
  String r, {
  PublicIssuerLegalName? proof,
  String? corp,
  DateTime? end,
}) => (proof ?? evidence(r)).verify(
  receipt: r,
  corpCode: corp ?? meta(r)['corpCode'],
  masterName: meta(r)['companyName'],
  printedName: meta(r)['printedCoverName'],
  coverSource: uri(r, 'cover'),
  coverHtml: raw(r, 'cover'),
  periodStart: DateTime.utc(meta(r)['bsnsYear']),
  periodEnd: end ?? DateTime.utc(meta(r)['bsnsYear'], 12, 31),
);
List<Map<String, dynamic>> actualRows(String r) =>
    PublicFinancialHtml.parseStandardAnnual(
      coverHtml: raw(r, 'cover'),
      statementHtml: raw(r, 'ofs'),
      coverSource: uri(r, 'cover'),
      statementSource: uri(r, 'ofs'),
      receipt: r,
      corpCode: meta(r)['corpCode'],
      companyName: meta(r)['companyName'],
      periodStart: DateTime.utc(meta(r)['bsnsYear']),
      periodEnd: DateTime.utc(meta(r)['bsnsYear'], 12, 31),
      consolidated: false,
      issuerProof: evidence(r),
    );
void main() {
  for (final r in positives) {
    test('$r actual direct declaration and source core', () {
      for (final s in meta(r)['sources'] as List) {
        expect(
          sha256
              .convert(File('$root/$r/${s['label']}.html').readAsBytesSync())
              .toString(),
          s['sha256'],
        );
      }
      final v = verify(r)!;
      expect(v['currentName'], meta(r)['companyName']);
      expect(
        PublicIssuerLegalName.normalize(v['declaredLegalName']!),
        PublicIssuerLegalName.normalize(meta(r)['printedCoverName']),
      );
      expect(v['receipt'], r);
      expect(v['legalNameEvidenceSource'], uri(r, 'overview').toString());
      final expected =
          jsonDecode(
                File('$root/$r/reviewed-core.json').readAsStringSync(),
              )['rows']
              as List;
      final rows = actualRows(r);
      expect(rows.length, expected.length);
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i]['thstrm_amount'], expected[i]['amount']);
        expect(rows[i]['account_nm'], expected[i]['label']);
        expect(rows[i]['account_id'], isNull);
        expect(rows[i]['html_provenance']['historicalCompanyIdentity'], v);
      }
    });
    test('$r foreign corp period and node reject', () {
      expect(verify(r, corp: '00000000'), isNull);
      expect(verify(r, end: DateTime.utc(2025, 12, 31)), isNull);
      expect(
        verify(
          r,
          proof: evidence(
            r,
            source: uri(r, 'overview').replace(
              queryParameters: {
                ...uri(r, 'overview').queryParameters,
                'eleId': '999',
              },
            ),
          ),
        ),
        isNull,
      );
    });
    for (final pair in [
      ('subsidiary', '당사의 명칭은', '당사의 자회사 명칭은'),
      ('future', '당사의 명칭은', '당사의 변경예정 명칭은'),
      ('history', '1. 회사의 개요', '2. 회사의 연혁'),
      ('later declaration', '당사의 명칭은', '먼저 과거 연혁입니다.</p><p>당사의 명칭은'),
    ]) {
      test('$r rejects ${pair.$1}', () {
        final original = raw(r, 'overview');
        expect(original.contains(pair.$2), isTrue);
        expect(
          verify(
            r,
            proof: evidence(r, overview: original.replaceAll(pair.$2, pair.$3)),
          ),
          isNull,
        );
      });
    }
  }
  for (final r in ['20240319000287', '20230714000217']) {
    test('$r no direct naming stays rejected', () => expect(verify(r), isNull));
  }
  test(
    'MD future notice is not naming candidate',
    () => expect(
      verify('20240814001895')!['declaredLegalName'],
      contains('메가일렉트로닉스'),
    ),
  );
}
