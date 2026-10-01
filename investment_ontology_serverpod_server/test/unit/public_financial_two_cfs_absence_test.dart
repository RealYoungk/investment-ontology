import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const root = 'test/fixtures/financial_html/two-cfs-absence';
Map proof(String r) =>
    jsonDecode(File('$root/$r/proof.json').readAsStringSync());
String fixture(String r, String n) =>
    File('$root/$r/$n.html').readAsStringSync();
Uri source(String r, String n) => Uri.parse(
  (proof(r)['sources'] as List).singleWhere((x) => x['label'] == n)['url'],
);
Future<PublicFinancialHtmlSource> fetch(
  String r, {
  String? body,
  String? cover,
  bool cfs = true,
}) =>
    PublicFinancialHtmlFetcher(
      MockClient((req) async {
        final n = req.url.path == '/dsaf001/main.do'
            ? 'shell'
            : req.url.queryParameters['eleId'] ==
                  source(r, 'cover').queryParameters['eleId']
            ? 'cover'
            : 'cfs';
        return http.Response.bytes(
          utf8.encode(
            n == 'shell'
                ? fixture(r, n)
                : n == 'cover'
                ? cover ?? fixture(r, n)
                : body ?? fixture(r, n),
          ),
          200,
          request: req,
        );
      }),
    ).fetchAnnual(
      r,
      reportName: proof(r)['reportName'],
      corpCode: proof(r)['corpCode'],
      companyName: proof(r)['name'],
      bsnsYear: proof(r)['bsnsYear'],
      periodEnd: DateTime.utc(proof(r)['bsnsYear'], 12, 31),
      consolidated: cfs,
    );
void main() {
  for (final r in ['20250318000596', '20260318001043']) {
    test('actual pure CFS absent with exact source provenance $r', () async {
      await expectLater(
        fetch(r),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((x) => x.sourceReceipt, 'receipt', r)
              .having((x) => x.statementSource, 'URI', source(r, 'cfs'))
              .having((x) => x.corpCode, 'corp', proof(r)['corpCode']),
        ),
      );
    });
    for (final suffix in [
      '<TABLE><TR><TD>100</TD></TR></TABLE>',
      '<SCRIPT>1</SCRIPT>',
      '<P>단, 종속회사를 취득하였습니다.</P>',
    ]) {
      test(
        'extra numeric/script/conditional content not absence $r $suffix',
        () async {
          await expectLater(
            fetch(
              r,
              body: fixture(r, 'cfs').replaceFirst('</BODY>', '$suffix</BODY>'),
            ),
            throwsA(
              isA<FormatException>().having(
                (x) => x is PublicFinancialHtmlBasisNotApplicable,
                'absence',
                false,
              ),
            ),
          );
        },
      );
    }
    test('wrong actual period cannot emit absence $r', () async {
      final y = proof(r)['bsnsYear'];
      await expectLater(
        fetch(r, cover: fixture(r, 'cover').replaceAll('$y년', '${y - 1}년')),
        throwsFormatException,
      );
    });
    test('OFS request never accepts CFS literal $r', () async {
      await expectLater(
        fetch(r, cfs: false),
        throwsA(
          isA<FormatException>().having(
            (x) => x is PublicFinancialHtmlBasisNotApplicable,
            'absence',
            false,
          ),
        ),
      );
    });
  }
}
