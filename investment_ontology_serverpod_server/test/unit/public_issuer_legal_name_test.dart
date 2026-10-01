import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const fixtureRoot = 'test/fixtures/financial_html/issuer-legalname';
String raw(String receipt, String label) =>
    File('$fixtureRoot/$receipt/$label.html').readAsStringSync();
Uri source(String receipt, String label) {
  final p = jsonDecode(
    File('$fixtureRoot/$receipt/proof.json').readAsStringSync(),
  ) as Map;
  return Uri.parse(
    (p['sources'] as List).singleWhere((v) => v['label'] == label)['url'],
  );
}

PublicIssuerLegalName proof(
  String receipt, {
  String? shell,
  String? overview,
  Uri? overviewUri,
}) => PublicIssuerLegalName(
  shellHtml: shell ?? raw(receipt, 'shell'),
  shellSource: source(receipt, 'shell'),
  overviewHtml: overview ?? raw(receipt, 'overview'),
  overviewSource: overviewUri ?? source(receipt, 'overview'),
);
Map<String, String>? verify(
  String receipt, {
  PublicIssuerLegalName? evidence,
  String? corp,
  String? printed,
  DateTime? start,
  DateTime? end,
  Uri? cover,
}) {
  final pureun = receipt == '20230315000460';
  return (evidence ?? proof(receipt)).verify(
    receipt: receipt,
    corpCode: corp ?? (pureun ? '00124805' : '01669794'),
    masterName: pureun ? '(주)푸른저축은행' : '(주)아이엘로보틱스',
    printedName: printed ?? (pureun ? '(주)푸른상호저축은행' : '주식회사아이엘커누스'),
    coverSource: cover ?? source(receipt, 'cover'),
    coverHtml: raw(receipt, 'cover'),
    periodStart: start ?? DateTime.utc(pureun ? 2022 : 2024, 1, 1),
    periodEnd: end ?? DateTime.utc(pureun ? 2022 : 2024, 12, 31),
  );
}

List<Map<String, dynamic>> actualIssuerRows(String receipt) {
  final pureun = receipt == '20230315000460';
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: raw(receipt, 'cover'),
    statementHtml: raw(receipt, 'ofs'),
    coverSource: source(receipt, 'cover'),
    statementSource: source(receipt, 'ofs'),
    receipt: receipt,
    corpCode: pureun ? '00124805' : '01669794',
    companyName: pureun ? '(주)푸른저축은행' : '(주)아이엘로보틱스',
    periodStart: DateTime.utc(pureun ? 2022 : 2024, 1, 1),
    periodEnd: DateTime.utc(pureun ? 2022 : 2024, 12, 31),
    consolidated: false,
    issuerProof: proof(receipt),
  );
}

void main() {
  test('exact annual transport adds only source-bound overview and reparses actual seven core', () async {
    const rec = '20251124000372';
    final calls = <String>[];
    final fetcher = PublicFinancialHtmlFetcher(
      MockClient((request) async {
        final matches = [
          'shell',
          'cover',
          'overview',
          'ofs',
        ].where((label) => source(rec, label) == request.url).toList();
        expect(matches, hasLength(1));
        final label = matches.single;
        calls.add(label);
        return http.Response.bytes(
          utf8.encode(raw(rec, label)),
          200,
          request: request,
        );
      }),
    );
    final result = await fetcher.fetchAnnual(
      rec,
      reportName: '사업보고서 (2024.12)',
      corpCode: '01669794',
      companyName: '(주)아이엘로보틱스',
      bsnsYear: 2024,
      periodEnd: DateTime.utc(2024, 12, 31),
      consolidated: false,
    );
    expect(calls, ['shell', 'cover', 'overview', 'ofs']);
    expect(result.rows, hasLength(7));
    expect(result.issuerProof, isNotNull);
    final rows = PublicFinancialHtml.parseStandardAnnual(
      coverHtml: result.coverHtml,
      statementHtml: result.statementHtml,
      coverSource: result.coverSource,
      statementSource: result.statementSource,
      receipt: rec,
      corpCode: '01669794',
      companyName: '(주)아이엘로보틱스',
      periodStart: result.periodStart,
      periodEnd: result.periodEnd,
      consolidated: false,
      issuerProof: result.issuerProof,
    );
    expect(rows, result.rows);
    expect(result.correctionReceipt, isNull);
  });
  test('transport issuer failure does not fetch numeric statement or become noData', () async {
    const rec = '20251124000372';
    final calls = <String>[];
    final fetcher = PublicFinancialHtmlFetcher(
      MockClient((request) async {
        final label = [
          'shell',
          'cover',
          'overview',
          'ofs',
        ].singleWhere((label) => source(rec, label) == request.url);
        calls.add(label);
        return http.Response.bytes(
          utf8.encode(
            label == 'overview'
                ? raw(rec, label).replaceAll('한글', '영문')
                : raw(rec, label),
          ),
          200,
          request: request,
        );
      }),
    );
    await expectLater(
      fetcher.fetchAnnual(
        rec,
        reportName: '사업보고서 (2024.12)',
        corpCode: '01669794',
        companyName: '아이엘로보틱스',
        bsnsYear: 2024,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: false,
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'identity failure',
          'Exact annual legal issuer corroboration failed',
        ),
      ),
    );
    expect(calls, ['shell', 'cover', 'overview']);
  });

  for (final receipt in ['20230315000460', '20251124000372']) {
    test('exact official legal issuer $receipt', () {
      final p = verify(receipt);
      expect(p, isNotNull);
      expect(p!['receipt'], receipt);
      expect(p['legalNameEvidenceSha256'], hasLength(64));
    });
  }
  test(
    'wrongcorp rejects',
    () => expect(verify('20251124000372', corp: '00124805'), isNull),
  );
  test(
    'wrong receipt URI rejects',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overviewUri: source('20251124000372', 'overview').replace(
            queryParameters: {
              ...source('20251124000372', 'overview').queryParameters,
              'rcpNo': '20230315000460',
            },
          ),
        ),
      ),
      isNull,
    ),
  );
  test(
    'wrong dcm rejects',
    () => expect(
      verify(
        '20251124000372',
        cover: source('20251124000372', 'cover').replace(
          queryParameters: {
            ...source('20251124000372', 'cover').queryParameters,
            'dcmNo': '999',
          },
        ),
      ),
      isNull,
    ),
  );
  test(
    'wrong printed name rejects',
    () => expect(verify('20251124000372', printed: '아이엘로보틱스'), isNull),
  );
  test(
    'wrong cover end rejects',
    () => expect(
      verify('20251124000372', end: DateTime.utc(2023, 12, 31)),
      isNull,
    ),
  );
  test(
    'short annual name widening prohibited',
    () => expect(
      verify('20251124000372', start: DateTime.utc(2024, 10, 1)),
      isNull,
    ),
  );
  test(
    'global body occurrence not evidence',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw(
            '20251124000372',
            'overview',
          ).replaceAll('나. 회사의 법적ㆍ상업적 명칭', '나. 회사의 연혁'),
        ),
      ),
      isNull,
    ),
  );
  test(
    'subsidiary heading not issuer',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw(
            '20251124000372',
            'overview',
          ).replaceAll('나. 회사의 법적ㆍ상업적 명칭', '나. 종속회사의 법적ㆍ상업적 명칭'),
        ),
      ),
      isNull,
    ),
  );
  test(
    'duplicate issuer heading rejects',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw(
            '20251124000372',
            'overview',
          ).replaceFirst('</BODY>', '<p>나. 회사의 법적ㆍ상업적 명칭</p></BODY>'),
        ),
      ),
      isNull,
    ),
  );
  test(
    'multiple direct Korean cells reject',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw('20251124000372', 'overview').replaceFirst(
            '<TD width=\'144\' height=\'23\' align=\'CENTER\'>영문</TD>',
            '<TD width=\'144\' height=\'23\' align=\'CENTER\'>한글</TD>',
          ),
        ),
      ),
      isNull,
    ),
  );
  test(
    'ordinary malformed table spoof rejects',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: '<p>나. 회사의 법적ㆍ상업적 명칭</p><p>주식회사 아이엘커누스</p><p>다. 설립일자</p>',
        ),
      ),
      isNull,
    ),
  );
  test(
    'script-derived issuer text rejected',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw('20251124000372', 'overview')
              .replaceFirst('<BODY bgcolor=', '<BODY bgcolor=')
              .replaceFirst(
                "<P><BR/></P>",
                '<script>untrusted</script><P><BR/></P>',
              ),
        ),
      ),
      isNull,
    ),
  );
  test(
    'duplicate own corp in shell rejected',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          shell:
              "${raw('20251124000372', 'shell')}openCorpInfoNew('00124805', 'winCorpInfo', '/dsae001/selectPopup.ax')",
        ),
      ),
      isNull,
    ),
  );
  test(
    'a valid legal name does not waive wrong current financial period',
    () => expect(
      () => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: raw('20251124000372', 'cover'),
        statementHtml: raw(
          '20251124000372',
          'ofs',
        ).replaceAll('2024년 12월 31일', '2023년 12월 31일'),
        coverSource: source('20251124000372', 'cover'),
        statementSource: source('20251124000372', 'ofs'),
        receipt: '20251124000372',
        corpCode: '01669794',
        companyName: '아이엘로보틱스',
        periodStart: DateTime.utc(2024, 1, 1),
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: false,
        issuerProof: proof('20251124000372'),
      ),
      throwsFormatException,
    ),
  );
  test('actual IL annual seven values retain printed identity audit', () {
    final rows = actualIssuerRows('20251124000372');
    expect(rows, hasLength(7));
    expect(rows.every((v) => v['account_id'] == null), isTrue);
    expect(
      (rows.first['html_provenance'] as Map)['historicalCompanyIdentity'],
      containsPair('declaredLegalName', '주식회사 아이엘커누스'),
    );
  });
  test(
    'actual Pureun identity does not waive incomplete whole core',
    () => expect(
      () => actualIssuerRows('20230315000460'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'core guard',
          'Annual primary core missing or balance mismatch',
        ),
      ),
    ),
  );
  test(
    'wrong issuer overview scope rejects',
    () => expect(
      verify(
        '20251124000372',
        evidence: proof(
          '20251124000372',
          overview: raw(
            '20251124000372',
            'overview',
          ).replaceAll('I. 회사의 개요', 'II. 사업의 내용'),
        ),
      ),
      isNull,
    ),
  );
}
