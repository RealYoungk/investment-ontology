import '../support/financial_html_test_clock.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

void main() {
  const d = 'assets/financial_source_cache/20250319000477-ofs';
  final m = jsonDecode(File('$d/manifest.json').readAsStringSync());
  Future<PublicFinancialHtmlSource> fetch({
    String? cover,
    String? overview,
    String corp = '01518506',
    String receipt = '20250319000477',
  }) {
    final docs = <String, List<int>>{};
    for (final s in m['sources']) {
      final bytes = File('$d/${s['file']}').readAsBytesSync();
      expect(sha256.convert(bytes).toString(), s['sha256']);
      docs[s['url']] = s['label'] == 'cover' && cover != null
          ? utf8.encode(cover)
          : s['label'] == 'overview' && overview != null
          ? utf8.encode(overview)
          : bytes;
    }
    return fastFinancialHtmlFetcher(
      MockClient((r) async {
        final bytes = docs[r.url.toString()];
        if (bytes == null) throw const FormatException('Unbound source');
        return http.Response.bytes(bytes, 200, request: r);
      }),
    ).fetchAnnual(
      receipt,
      reportName: '사업보고서 (2024.12)',
      corpCode: corp,
      companyName: '(주)타조이엔터테인먼트',
      bsnsYear: 2024,
      periodEnd: DateTime.utc(2024, 12, 31),
      consolidated: false,
    );
  }

  test('actual own source dot cover and seven whole rows', () async {
    final s = await fetch();
    expect(s.rows, hasLength(7));
    expect(s.rows.map((r) => r['thstrm_amount']).toList(), [
      '5096941833',
      '2299074888',
      '2797866945',
      '13218343123',
      '1301851464',
      '1097322856',
      '477899769',
    ]);
    for (final r in s.rows) {
      expect(r['account_id'], isNull);
      expect(r['currency'], 'KRW');
      expect(r['html_provenance']['periodStart'], '2024-01-01');
      expect(r['html_provenance']['periodEnd'], '2024-12-31');
      expect(
        r['html_provenance']['historicalCompanyIdentity']['declaredLegalName'],
        '주식회사 타조엔터테인먼트',
      );
    }
  });
  test('wrong identity, printed date and non-direct section reject', () async {
    await expectLater(fetch(corp: '01518507'), throwsFormatException);
    await expectLater(fetch(receipt: '20250319000478'), throwsFormatException);
    final c = File('$d/cover.html').readAsStringSync();
    await expectLater(
      fetch(cover: c.replaceAll('2024.12.31', '2023.12.31')),
      throwsFormatException,
    );
    final o = File('$d/overview.html').readAsStringSync();
    for (final a in [
      o.replaceAll('당사의 명칭은', '향후 당사의 명칭은'),
      o.replaceAll('나. 회사의 법적ㆍ상업적 명칭', '나. 회사의 연혁'),
      o.replaceAll('당사의 명칭은', '자회사의 명칭은'),
      o.replaceAll('1. 회사의 개요', '2. 다른 회사의 개요'),
      o.replaceAll(
        '영문명은 TAJOY entertainment., LTD. 입니다.',
        '영문명은 TAJOY entertainment., LTD. 입니다. 다른 회사는 주식회사 타회사입니다.',
      ),
    ]) {
      await expectLater(fetch(overview: a), throwsFormatException);
    }
  });
}
