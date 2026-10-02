import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const root = 'test/fixtures/financial_html/two-historical-issuer';
const positives = ['20240409003743', '20230714000369'];
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
    test(
      '$r actual historical declaration, whole seven and source provenance',
      () {
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
        final expected =
            jsonDecode(
                  File('$root/$r/reviewed-core.json').readAsStringSync(),
                )['rows']
                as List;
        final rows = actualRows(r);
        expect(rows, hasLength(7));
        for (var i = 0; i < rows.length; i++) {
          expect(rows[i]['thstrm_amount'], expected[i]['amount']);
          expect(rows[i]['account_nm'], expected[i]['label']);
          expect(rows[i]['account_id'], isNull);
          expect(rows[i]['html_provenance']['historicalCompanyIdentity'], v);
          expect(rows[i]['html_provenance']['periodStart'], '2022-01-01');
          expect(rows[i]['html_provenance']['periodEnd'], '2022-12-31');
        }
      },
    );
    test('$r foreign company or period cannot bind historical identity', () {
      expect(verify(r, corp: '00000000'), isNull);
      expect(verify(r, end: DateTime.utc(2023, 12, 31)), isNull);
    });
  }
}
