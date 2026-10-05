import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const directory = 'test/fixtures/financial_html/a1-first-direct';
String raw(String name) => File('$directory/$name.html').readAsStringSync();
Map meta() => jsonDecode(File('$directory/proof.json').readAsStringSync());
Uri uri(String name) => Uri.parse(
  (meta()['sources'] as List).singleWhere((s) => s['label'] == name)['url'],
);
PublicIssuerLegalName proof({String? overview}) => PublicIssuerLegalName(
  shellHtml: raw('shell'),
  shellSource: uri('shell'),
  overviewHtml: overview ?? raw('overview'),
  overviewSource: uri('overview'),
);
Map<String, String>? verify({
  String? overview,
  String corp = '00614089',
  String receipt = '20260316001360',
  DateTime? end,
}) => proof(overview: overview).verify(
  receipt: receipt,
  corpCode: corp,
  masterName: '주식회사 에이원큐브텍',
  printedName: '주식회사에이원알폼',
  coverSource: uri('cover'),
  coverHtml: raw('cover'),
  periodStart: DateTime.utc(2025),
  periodEnd: end ?? DateTime.utc(2025, 12, 31),
);
void main() {
  test('exact A1 source declares its printed historical issuer and full current eight', () {
    for (final s in meta()['sources'] as List) {
      expect(
        sha256
            .convert(File('$directory/${s['label']}.html').readAsBytesSync())
            .toString(),
        s['sha256'],
      );
    }
    final identity = verify()!;
    expect(identity['currentName'], '주식회사 에이원큐브텍');
    expect(identity['declaredLegalName'], '주식회사 에이원알폼');
    expect(identity['receipt'], '20260316001360');
    final rows = PublicFinancialHtml.parseStandardAnnual(
      coverHtml: raw('cover'),
      statementHtml: raw('ofs'),
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      receipt: '20260316001360',
      corpCode: '00614089',
      companyName: '주식회사 에이원큐브텍',
      periodStart: DateTime.utc(2025),
      periodEnd: DateTime.utc(2025, 12, 31),
      consolidated: false,
      issuerProof: proof(),
    );
    final expected = jsonDecode(
      File('$directory/reviewed-core.json').readAsStringSync(),
    ) as List;
    expect(rows, hasLength(8));
    for (var i = 0; i < rows.length; i++) {
      expect(rows[i]['thstrm_amount'], expected[i]['thstrm_amount']);
      expect(rows[i]['account_nm'], expected[i]['account_nm']);
      expect(rows[i]['account_id'], isNull);
      expect(rows[i]['html_provenance']['historicalCompanyIdentity'], identity);
    }
  });
  test('mock exact attachment-add transport retains current master plus printed legal proof', () async {
    final files = {
      for (final s in meta()['sources'] as List) s['url']: raw(s['label']),
    };
    final result =
        await fastFinancialHtmlFetcher(
          MockClient((r) async {
            expect(r.url.queryParameters.containsKey('crtfc_key'), false);
            final body = files[r.url.toString()];
            if (body == null) throw const FormatException('Uncached source');
            return http.Response.bytes(utf8.encode(body), 200, request: r);
          }),
        ).fetchAnnual(
          '20260316001360',
          reportName: '[첨부추가]사업보고서 (2025.12)',
          corpCode: '00614089',
          companyName: '주식회사 에이원큐브텍',
          bsnsYear: 2025,
          periodEnd: DateTime.utc(2025, 12, 31),
          consolidated: false,
        );
    expect(result.rows, hasLength(8));
    expect(result.sourceReceipt, '20260316001360');
    expect(result.issuerProof, isNotNull);
  });
  for (final pair in [
    ('future', '당사의 명칭은', '당사의 변경예정 명칭은'),
    ('other', '당사의 명칭은', '자회사의 명칭은'),
    ('later', '당사의 명칭은', '과거 내역입니다.<BR/>당사의 명칭은'),
    ('history', '1. 회사의 개요', '2. 회사의 연혁'),
    ('English substitution', '주식회사 에이원알폼', 'A ONE ALFORM'),
    ('intervening', '또한 영문으로는', '별도 설명입니다.<BR/>또한 영문으로는'),
    ('tail proposal', '또한 영문으로는', '향후 영문으로는'),
  ]) {
    test('first exact A1 rejects ${pair.$1}', () {
      final o = raw('overview');
      expect(o.contains(pair.$2), true);
      expect(verify(overview: o.replaceAll(pair.$2, pair.$3)), isNull);
    });
  }
  test('wrong own corp receipt period reject', () {
    expect(verify(corp: '00000000'), isNull);
    expect(verify(receipt: '20260316001361'), isNull);
    expect(verify(end: DateTime.utc(2024, 12, 31)), isNull);
  });
}
