import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const dir = 'test/fixtures/financial_html/bilingual-issuer/20230414002057';
  String raw(String label) => File('$dir/$label.html').readAsStringSync();
  final meta = jsonDecode(File('$dir/proof.json').readAsStringSync());
  Uri uri(String label) => Uri.parse(
    (meta['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  PublicIssuerLegalName proof({String? overview}) => PublicIssuerLegalName(
    shellHtml: raw('shell'),
    shellSource: uri('shell'),
    overviewHtml: overview ?? raw('overview'),
    overviewSource: uri('overview'),
  );
  Map<String, String>? verify({
    String? overview,
    String? printed,
    String? corp,
  }) => proof(overview: overview).verify(
    receipt: '20230414002057',
    corpCode: corp ?? '01226234',
    masterName: '(주)와이바이오로직스',
    printedName: printed ?? '(주)와이바이오로직스(Y-BiologicsInc.)',
    coverSource: uri('cover'),
    coverHtml: raw('cover'),
    periodStart: DateTime.utc(2022),
    periodEnd: DateTime.utc(2022, 12, 31),
  );
  test('all official bytes retain their own URI and SHA', () {
    for (final source in meta['sources']) {
      expect(
        sha256
            .convert(File('$dir/${source['file']}').readAsBytesSync())
            .toString(),
        source['sha256'],
      );
      expect(
        Uri.parse(source['url']).queryParameters['rcpNo'],
        '20230414002057',
      );
    }
  });
  test(
    'own CFS pure section verifies not-applicable without numeric inference',
    () async {
      final loader = PublicFinancialHtmlFetcher(
        MockClient((req) async {
          final source = (meta['sources'] as List).singleWhere(
            (s) => s['url'] == req.url.toString(),
          );
          return http.Response.bytes(
            File('$dir/${source['file']}').readAsBytesSync(),
            200,
          );
        }),
      );
      await expectLater(
        loader.fetchAnnual(
          '20230414002057',
          reportName: '사업보고서 (2022.12)',
          corpCode: '01226234',
          companyName: '(주)와이바이오로직스',
          bsnsYear: 2022,
          periodEnd: DateTime.utc(2022, 12, 31),
          consolidated: true,
        ),
        throwsA(
          isA<PublicFinancialHtmlBasisNotApplicable>()
              .having((e) => e.evidence, 'printed evidence', '*해당사항이 없습니다.')
              .having((e) => e.statementSource, 'actual CFS node', uri('cfs')),
        ),
      );
    },
  );
  for (final mutation in [
    '<P>*해당사항이 없습니다. 주석을 참고하십시오.</P>',
    '<P>*해당사항이 없습니다.</P><TABLE><TR><TD>1</TD></TR></TABLE>',
    '<P>*해당사항이 없습니다. 법률에 따른 내용입니다.</P>',
  ]) {
    test(
      'not-applicable inference rejects context or numbers: $mutation',
      () async {
        final loader = PublicFinancialHtmlFetcher(
          MockClient((req) async {
            final source = (meta['sources'] as List).singleWhere(
              (s) => s['url'] == req.url.toString(),
            );
            var bytes = File('$dir/${source['file']}').readAsBytesSync();
            if (source['label'] == 'cfs') {
              bytes = utf8.encode(
                utf8
                    .decode(bytes)
                    .replaceFirst('<P>*해당사항이 없습니다.</P>', mutation),
              );
            }
            return http.Response.bytes(bytes, 200);
          }),
        );
        await expectLater(
          loader.fetchAnnual(
            '20230414002057',
            reportName: '사업보고서 (2022.12)',
            corpCode: '01226234',
            companyName: '(주)와이바이오로직스',
            bsnsYear: 2022,
            periodEnd: DateTime.utc(2022, 12, 31),
            consolidated: true,
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e is PublicFinancialHtmlBasisNotApplicable,
              'not classified absent',
              isFalse,
            ),
          ),
        );
      },
    );
  }
  test(
    'normal official transport retains historical cover and exact raw core',
    () async {
      final fetched = <Uri>[];
      final loader = PublicFinancialHtmlFetcher(
        MockClient((req) async {
          final source = (meta['sources'] as List).singleWhere(
            (s) => s['url'] == req.url.toString(),
          );
          fetched.add(req.url);
          return http.Response.bytes(
            File('$dir/${source['file']}').readAsBytesSync(),
            200,
          );
        }),
      );
      final result = await loader.fetchAnnual(
        '20230414002057',
        reportName: '사업보고서 (2022.12)',
        corpCode: '01226234',
        companyName: '(주)와이바이오로직스',
        bsnsYear: 2022,
        periodEnd: DateTime.utc(2022, 12, 31),
        consolidated: false,
      );
      expect(result.rows.length, 8);
      expect(result.issuerProof, isNotNull);
      expect(result.sourceReceipt, '20230414002057');
      expect(result.statementSource, uri('ofs'));
      expect(fetched, contains(uri('overview')));
    },
  );
  test('official bilingual names are corroborated without translation', () {
    final result = verify();
    expect(result, isNotNull);
    expect(result!['declaredLegalName'], '주식회사 와이바이오로직스');
    expect(result['declaredEnglishName'], 'Y-Biologics, Inc.');
  });
  test('actual whole financial parser remains strict after identity', () {
    final rows = PublicFinancialHtml.parseStandardAnnual(
      coverHtml: raw('cover'),
      statementHtml: raw('ofs'),
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      receipt: '20230414002057',
      corpCode: '01226234',
      companyName: '(주)와이바이오로직스',
      periodStart: DateTime.utc(2022),
      periodEnd: DateTime.utc(2022, 12, 31),
      consolidated: false,
      issuerProof: proof(),
    );
    expect(
      {for (final r in rows) r['account_nm']: r['thstrm_amount']},
      {
        '자산총계': '29322648895',
        '부채총계': '17029482330',
        '자본총계': '12293166565',
        '매출액': '4150557898',
        '영업이익(손실)': '-18830214970',
        '당기순이익(손실)': '-18804401066',
        '영업활동으로 인한 현금흐름': '-10104924654',
        '유형자산의 취득': '-1088240488',
      },
    );
    expect(
      rows.every((r) => r['account_id'] == null && r['currency'] == 'KRW'),
      isTrue,
    );
  });
  test('old Protia first naming declaration with spaced heading remains source bound', () {
    const root = 'test/fixtures/financial_html/bilingual-issuer/20220321000965';
    String body(String label) => File('$root/$label.html').readAsStringSync();
    final data = jsonDecode(File('$root/proof.json').readAsStringSync());
    Uri source(String label) => Uri.parse(
      (data['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final evidence = PublicIssuerLegalName(
      shellHtml: body('shell'),
      shellSource: source('shell'),
      overviewHtml: body('overview'),
      overviewSource: source('overview'),
    );
    final name = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .firstMatch(
          body('cover').replaceAll(RegExp('<[^>]*>|\\s+|&nbsp;'), ''),
        )!
        .group(1)!;
    final identity = evidence.verify(
      receipt: data['receipt'],
      corpCode: data['corp'],
      masterName: data['name'],
      printedName: name,
      coverSource: source('cover'),
      coverHtml: body('cover'),
      periodStart: DateTime.utc(2021),
      periodEnd: DateTime.utc(2021, 12, 31),
    );
    expect(identity, isNotNull);
    expect(
      () => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: body('cover'),
        statementHtml: body('ofs'),
        coverSource: source('cover'),
        statementSource: source('ofs'),
        receipt: data['receipt'],
        corpCode: data['corp'],
        companyName: data['name'],
        periodStart: DateTime.utc(2021),
        periodEnd: DateTime.utc(2021, 12, 31),
        consolidated: false,
        issuerProof: evidence,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'reason',
          'Annual current statement title period mismatch',
        ),
      ),
    );
  });
  test('old Redwoods direct legal naming remains whole-source bound', () {
    const root = 'test/fixtures/financial_html/bilingual-issuer/20220321001531';
    String body(String label) => File('$root/$label.html').readAsStringSync();
    final data = jsonDecode(File('$root/proof.json').readAsStringSync());
    Uri source(String label) => Uri.parse(
      (data['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final evidence = PublicIssuerLegalName(
      shellHtml: body('shell'),
      shellSource: source('shell'),
      overviewHtml: body('overview'),
      overviewSource: source('overview'),
    );
    final name = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .firstMatch(
          body('cover').replaceAll(RegExp('<[^>]*>|\\s+|&nbsp;'), ''),
        )!
        .group(1)!;
    final identity = evidence.verify(
      receipt: data['receipt'],
      corpCode: data['corp'],
      masterName: data['name'],
      printedName: name,
      coverSource: source('cover'),
      coverHtml: body('cover'),
      periodStart: DateTime.utc(2021),
      periodEnd: DateTime.utc(2021, 12, 31),
    );
    expect(identity, isNotNull);
    expect(
      () => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: body('cover'),
        statementHtml: body('ofs'),
        coverSource: source('cover'),
        statementSource: source('ofs'),
        receipt: data['receipt'],
        corpCode: data['corp'],
        companyName: data['name'],
        periodStart: DateTime.utc(2021),
        periodEnd: DateTime.utc(2021, 12, 31),
        consolidated: false,
        issuerProof: evidence,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'reason',
          'Annual primary statement title mismatch',
        ),
      ),
    );
  });
  for (final replacement in [
    '예정된 명칭은',
    '변경할 명칭은',
    '종속회사의 명칭은',
  ]) {
    test('future or another issuer naming remains rejected: $replacement', () {
      expect(
        verify(overview: raw('overview').replaceAll('당사의 명칭은', replacement)),
        isNull,
      );
    });
  }
  test('English declaration is not guessed from Korean', () {
    expect(
      verify(
        overview: raw('overview').replaceAll('Y-Biologics, Inc.', 'Other Inc.'),
      ),
      isNull,
    );
    expect(verify(corp: '00123456'), isNull);
    expect(verify(printed: '(주)와이바이오로직스(OtherInc.)'), isNull);
  });
}
