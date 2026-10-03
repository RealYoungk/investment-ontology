import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const dir = 'assets/financial_source_cache/20260327001807-cfs';
  final manifest =
      jsonDecode(File('$dir/manifest.json').readAsStringSync()) as Map;
  Uri uri(String label) => Uri.parse(
    (manifest['sources'] as List).singleWhere(
      (x) => x['label'] == label,
    )['url'],
  );
  final cover = File('$dir/cover.html').readAsStringSync();
  final statement = File('$dir/cfs.html').readAsStringSync();
  List<Map<String, dynamic>> parse({
    String? html,
    String? coverHtml,
    String corp = '01018617',
    String receipt = '20260327001807',
    bool cfs = true,
    DateTime? end,
    Uri? source,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: coverHtml ?? cover,
    statementHtml: html ?? statement,
    coverSource: uri('cover'),
    statementSource: source ?? uri('cfs'),
    receipt: receipt,
    corpCode: corp,
    companyName: '(주)메디쎄이',
    periodStart: DateTime.utc(2025),
    periodEnd: end ?? DateTime.utc(2025, 12, 31),
    consolidated: cfs,
  );
  test(
    'actual own CFS raw seven core match whole CE without rewriting header',
    () {
      final rows = parse();
      expect(rows.length, 7);
      final amounts = rows.map((r) => r['thstrm_amount']).toSet();
      expect(
        amounts,
        containsAll([
          '45102016879',
          '7405512610',
          '37696504269',
          '28309005387',
          '3953011720',
          '3328325280',
          '3457919863',
        ]),
      );
      expect(
        rows.every(
          (r) => r['account_id'] == null && r['rcept_no'] == '20260327001807',
        ),
        isTrue,
      );
      final proof = rows.first['html_provenance']['supportingPeriodEvidence'];
      expect(proof['rawHeader'], '제 23당) 기말');
      expect(proof['currentProfit'], '3328325280');
      expect(proof['closingEquity'], '37696504269');
      expect(statement, contains('제 23당) 기말'));
    },
  );
  final negatives = <String, List<Map<String, dynamic>> Function()>{
    'wrong corp': () => parse(corp: '01018618'),
    'wrong receipt': () => parse(receipt: '20260327001808'),
    'wrong basis': () => parse(cfs: false),
    'wrong year': () => parse(end: DateTime.utc(2024, 12, 31)),
    'wrong term': () => parse(coverHtml: cover.replaceAll('23', '24')),
    'wrong source coordinates': () => parse(
      source: uri('cfs').replace(
        queryParameters: {...uri('cfs').queryParameters, 'offset': '428968'},
      ),
    ),
    'wrong whole equity': () =>
        parse(html: statement.replaceAll('37,696,504,269', '37,696,504,268')),
    'wrong CE net only': () {
      final ce = statement.indexOf('연 결 자 본 변 동 표');
      final cf = statement.indexOf('연 결 현 금 흐 름 표');
      expect(ce, greaterThan(0));
      expect(cf, greaterThan(ce));
      final altered = statement
          .substring(ce, cf)
          .replaceAll('3,328,325,280', '3,328,325,281');
      expect(altered, isNot(statement.substring(ce, cf)));
      return parse(
        html: statement.substring(0, ce) + altered + statement.substring(cf),
      );
    },
    'wrong unit': () => parse(html: statement.replaceAll('단위 : 원', '단위 : USD')),
    'wrong CF current term': () =>
        parse(html: statement.replaceAll('제 23당) 기말', '제 22당) 기말')),
    'wrong CF current date': () =>
        parse(html: statement.replaceAll('2025년 01월 01일부터', '2024년 01월 01일부터')),
    'parent-labelled whole net': () =>
        parse(html: statement.replaceAll('당기순이익(손실)', '지배기업당기순이익(손실)')),
    'current monetary ambiguity': () =>
        parse(html: statement.replaceAll('3,457,919,863', '3,457,919,863 1')),
  };
  for (final entry in negatives.entries) {
    test(entry.key, () => expect(entry.value, throwsFormatException));
  }
}
