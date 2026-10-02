import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const root = 'test/fixtures/financial_html/legal-two-grammars';
String raw(String r, String n) => File('$root/$r/$n.html').readAsStringSync();
Map<String, dynamic> meta(String r) =>
    jsonDecode(File('$root/$r/proof.json').readAsStringSync());
Uri uri(String r, String n) => Uri.parse(
  (meta(r)['sources'] as List).singleWhere((v) => v['label'] == n)['url'],
);
PublicIssuerLegalName evidence(
  String r, {
  String? overview,
  String? shell,
  Uri? overviewUri,
}) => PublicIssuerLegalName(
  shellHtml: shell ?? raw(r, 'shell'),
  shellSource: uri(r, 'shell'),
  overviewHtml: overview ?? raw(r, 'overview'),
  overviewSource: overviewUri ?? uri(r, 'overview'),
);
Map<String, String>? verify(
  String r, {
  PublicIssuerLegalName? proof,
  String? corp,
  DateTime? end,
}) => (proof ?? evidence(r)).verify(
  receipt: r,
  corpCode: corp ?? meta(r)['corpCode'],
  masterName: meta(r)['name'],
  printedName: r == '20260330001331' ? '주식회사 로보쓰리에이아이' : '에스케이시그넷 주식회사',
  coverSource: uri(r, 'cover'),
  coverHtml: raw(r, 'cover'),
  periodStart: DateTime.utc(2025),
  periodEnd: end ?? DateTime.utc(2025, 12, 31),
);
void main() {
  for (final r in ['20260330001331', '20260319001111']) {
    test(
      '$r actual legal declaration binds seven financial rows and source proof',
      () {
        final proof = verify(r)!;
        expect(proof['corpCode'], meta(r)['corpCode']);
        expect(proof['receipt'], r);
        expect(proof['periodEnd'], '2025-12-31');
        expect(
          proof['declaredLegalName'],
          contains(r == '20260330001331' ? '로보쓰리에이아이' : '에스케이시그넷'),
        );
        final rows = PublicFinancialHtml.parseStandardAnnual(
          coverHtml: raw(r, 'cover'),
          statementHtml: raw(r, 'ofs'),
          coverSource: uri(r, 'cover'),
          statementSource: uri(r, 'ofs'),
          receipt: r,
          corpCode: meta(r)['corpCode'],
          companyName: meta(r)['name'],
          periodStart: DateTime.utc(2025),
          periodEnd: DateTime.utc(2025, 12, 31),
          consolidated: false,
          issuerProof: evidence(r),
        );
        expect(rows.length, 7);
        expect(
          rows.every((v) => v['account_id'] == null && v['currency'] == 'KRW'),
          isTrue,
        );
        for (final row in rows) {
          final p = row['html_provenance'] as Map;
          expect(p['historicalCompanyIdentity']['receipt'], r);
        }
      },
    );
    test(
      '$r runtime fetch revalidates official identity without extra domains',
      () async {
        final fetcher = PublicFinancialHtmlFetcher(
          MockClient((request) async {
            final label = [
              'shell',
              'cover',
              'overview',
              'ofs',
            ].singleWhere((n) => uri(r, n) == request.url);
            return http.Response.bytes(
              utf8.encode(raw(r, label)),
              200,
              request: request,
            );
          }),
        );
        final result = await fetcher.fetchAnnual(
          r,
          reportName: '사업보고서 (2025.12)',
          corpCode: meta(r)['corpCode'],
          companyName: meta(r)['name'],
          bsnsYear: 2025,
          periodEnd: DateTime.utc(2025, 12, 31),
          consolidated: false,
        );
        expect(result.rows.length, 7);
        expect(result.sourceReceipt, r);
        expect(result.statementSource, uri(r, 'ofs'));
      },
    );
    test('$r foreign corp/end/dcm/source-scope rejected', () {
      expect(verify(r, corp: '00000001'), isNull);
      expect(verify(r, end: DateTime.utc(2024, 12, 31)), isNull);
      expect(
        verify(
          r,
          proof: evidence(
            r,
            overviewUri: uri(r, 'overview').replace(
              query: uri(r, 'overview').query.replaceFirst('dcmNo=', 'dcmNo=9'),
            ),
          ),
        ),
        isNull,
      );
      expect(
        verify(
          r,
          proof: evidence(
            r,
            overview: raw(r, 'overview').replaceAll('회사의 법적ㆍ상업적 명칭', '다른 정보'),
          ),
        ),
        isNull,
      );
    });
  }
  const s = '20260330001331';
  for (final prefix in ['향후 ', '정관변경안 상정: ', '가정: ', '변경예정: ']) {
    test(
      'future conditional cannot supply current legal name $prefix',
      () => expect(
        verify(
          s,
          proof: evidence(
            s,
            overview: raw(
              s,
              'overview',
            ).replaceFirst('당사의 명칭은', '$prefix당사의 명칭은'),
          ),
        ),
        isNull,
      ),
    );
  }
  test('proposal alone cannot validate Solumix current cover', () {
    final body = raw(
      s,
      'overview',
    ).replaceFirst('&quot;주식회사 로보쓰리에이아이&quot;', '&quot;주식회사 솔루믹스&quot;');
    expect(verify(s, proof: evidence(s, overview: body)), isNull);
  });
  const k = '20260319001111';
  test(
    'English-only name cannot infer Korean issuer',
    () => expect(
      verify(
        k,
        proof: evidence(
          k,
          overview: raw(
            k,
            'overview',
          ).replaceFirst(': 에스케이시그넷 주식회사(영문명', ': SK Signet Inc.(영문명'),
        ),
      ),
      isNull,
    ),
  );
  test(
    'colon legal statement after unrelated paragraph is not direct heading declaration',
    () => expect(
      verify(
        k,
        proof: evidence(
          k,
          overview: raw(
            k,
            'overview',
          ).replaceFirst(': 에스케이시그넷', '다른 정보입니다.<BR/>: 에스케이시그넷'),
        ),
      ),
      isNull,
    ),
  );
  test(
    'two direct declarations remain ambiguous',
    () => expect(
      verify(
        k,
        proof: evidence(
          k,
          overview: raw(k, 'overview').replaceFirst(
            ': 에스케이시그넷 주식회사(영문명 : SK Signet Inc.)',
            ': 에스케이시그넷 주식회사(영문명 : SK Signet Inc.)<BR/>당사의 명칭은 &quot;에스케이시그넷 주식회사&quot; 이며, 영문으로 &quot;SK Signet Inc.&quot;로 표기합니다.',
          ),
        ),
      ),
      isNull,
    ),
  );
}
