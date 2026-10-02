import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_verified_duration_priority_test.dart' show filing;

const root = 'test/fixtures/financial_html/jilgyungyi-dated-term';
const receipt = '20230321000972';
String raw(String n, {String r = receipt}) =>
    File('$root/$r/$n.html').readAsStringSync();
Uri uri(String n, {String r = receipt}) => Uri.parse(
  (jsonDecode(File('$root/$r/proof.json').readAsStringSync())['sources']
          as List)
      .singleWhere((s) => s['label'] == n)['url'],
);
List<Map<String, dynamic>> parse({
  String? body,
  String? cover,
  String corp = '01063556',
  Uri? source,
  String r = receipt,
  int year = 2022,
  bool consolidated = true,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: cover ?? raw('cover', r: r),
  statementHtml: body ?? raw('cfs', r: r),
  coverSource: uri('cover', r: r),
  statementSource: source ?? uri('cfs', r: r),
  receipt: r,
  corpCode: corp,
  companyName: '(주)질경이',
  periodStart: DateTime.utc(year),
  periodEnd: DateTime.utc(year, 12, 31),
  consolidated: consolidated,
);
Future<PublicFinancialHtmlSource> fetch() =>
    PublicFinancialHtmlFetcher(
      MockClient((request) async {
        final label = [
          'shell',
          'cover',
          'cfs',
        ].singleWhere((n) => uri(n) == request.url);
        return http.Response.bytes(
          utf8.encode(raw(label)),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
          request: request,
        );
      }),
    ).fetchAnnual(
      receipt,
      reportName: '사업보고서 (2022.12)',
      corpCode: '01063556',
      companyName: '(주)질경이',
      bsnsYear: 2022,
      periodEnd: DateTime.utc(2022, 12, 31),
      consolidated: true,
    );
void main() {
  test(
    'actual separate current term and full date titles preserve whole7 and CE',
    () {
      final rows = parse();
      expect(rows.length, inInclusiveRange(7, 8));
      final expected = {
        '자산총계': '5880929737',
        '부채총계': '6307895583',
        '자본총계': '-426965846',
        'Ⅰ. 매출액': '9091448170',
        'Ⅴ. 영업이익(손실)': '-971045103',
        'Ⅷ. 당기순손실': '-1102090301',
        'Ⅰ. 영업활동으로 인한 현금흐름': '-872183556',
      };
      for (final e in expected.entries) {
        final row = rows.singleWhere(
          (r) =>
              (r['account_nm'] as String).replaceAll(RegExp(r'\s+'), '') ==
              e.key.replaceAll(RegExp(r'\s+'), ''),
        );
        expect(row['thstrm_amount'], e.value);
        expect(row['account_id'], null);
        expect(row['currency'], 'KRW');
        final proof = row['html_provenance']['supportingPeriodEvidence'];
        expect(proof['wholeTotalColumn'], 6);
        expect(proof['currentProfit'], '-1102090301');
        expect(proof['closingEquity'], '-426965846');
      }
    },
  );
  test('normal official mock transport preserves exact body rows', () async {
    final source = await fetch();
    expect(source.rows, parse());
    expect(source.sourceReceipt, receipt);
    expect(source.statementSource, uri('cfs'));
  });
  final body = raw('cfs');
  for (final c in [
    ('wrong current dates', body.replaceAll('2022년 1월 1일부터', '2022년 2월 1일부터')),
    ('wrong BS dates', body.replaceAll('2022년 12월 31일 현재', '2021년 12월 31일 현재')),
    ('wrong explicit term', body.replaceAll('제 10(당) 기', '제 11(당) 기')),
    ('wrong current column', body.replaceAll('제 10(당) 기', '제 9(전) 기')),
    ('unsupported unit', body.replaceAll('(단위 : 원)', '(단위 : USD)')),
    (
      'foreign statement company',
      body.replaceAll('주식회사 질경이와 그 종속기업', '주식회사 다른회사와 그 종속기업'),
    ),
    ('CE date conflict', body.replaceAll('2022.1.1(당기초)', '2021.1.1(당기초)')),
    ('CE parent header is not whole', body.replaceAll('합 &nbsp;계', '지배기업 합계')),
    (
      'mandatory whole profit absent',
      body.replaceAll('Ⅷ. 당기순손실', 'Ⅷ. 지배기업소유주 순손실'),
    ),
    (
      'multiple current date',
      body.replaceFirst(
        '당기: 2022년 1월 1일부터 2022년 12월 31일까지',
        '당기: 2022년 1월 1일부터 2022년 12월 31일까지 당기: 2022년 1월 1일부터 2022년 12월 31일까지',
      ),
    ),
  ]) {
    test(c.$1, () {
      expect(c.$2, isNot(body), reason: 'Actual fixture mutation must apply');
      expect(() => parse(body: c.$2), throwsFormatException);
    });
  }
  test('extra wrong-year CE current marker cannot coexist with valid date', () {
    expect(
      () => parse(body: body.replaceAll('2021.1.1(전기초)', '2021.1.1(당기초)')),
      throwsFormatException,
    );
  });
  test('second different explicitly current term conflicts', () {
    expect(
      () => parse(body: body.replaceFirst('제 9(전) 기', '제 11(당) 기')),
      throwsFormatException,
    );
  });
  test('multiple current monetary headers reject', () {
    expect(
      () => parse(body: body.replaceFirst('제 9(전) 기', '제 10(당) 기')),
      throwsFormatException,
    );
  });
  test('CE whole amount cannot be replaced by parent or NCI', () {
    final at = body.indexOf('2022.1.1(당기초)');
    final profitAt = body.indexOf('당기순손실', at);
    final end = body.indexOf('</TR>', profitAt);
    final cellAt = body.substring(0, end).lastIndexOf('(1,102,090,301)');
    expect(cellAt, greaterThan(profitAt));
    for (final amount in ['-', '0', '(1,102,090,302)']) {
      final changed = body.replaceRange(
        cellAt,
        cellAt + '(1,102,090,301)'.length,
        amount,
      );
      expect(changed, isNot(body));
      expect(() => parse(body: changed), throwsFormatException);
    }
  });
  test(
    'FY2023 actual conflicting current terms remain rejected',
    () => expect(
      () => parse(r: '20240321000985', year: 2023),
      throwsFormatException,
    ),
  );
  test(
    'wrong corporation cannot invoke profile',
    () => expect(() => parse(corp: '99999999'), throwsFormatException),
  );
  test('wrong receipt/dcm cannot invoke profile', () {
    for (final replacement in ['9082269', '20230321000973']) {
      expect(
        () => parse(
          source: uri('cfs').replace(
            query: uri('cfs').query.replaceAll(
              replacement.startsWith('908') ? '9082268' : receipt,
              replacement,
            ),
          ),
        ),
        throwsFormatException,
      );
    }
  });
  test('wrong requested year/basis rejects', () {
    expect(() => parse(year: 2023), throwsFormatException);
    expect(() => parse(consolidated: false), throwsFormatException);
  });
  test('exact finite priority preserves source caps and identity', () {
    final f = filing(receipt, '01063556', 2022, ofs: FilingFetchStatus.stored);
    expect(FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f), true);
    for (final bad in [
      f.copyWith(corpCode: '99999999'),
      f.copyWith(bsnsYear: 2023),
      f.copyWith(reportName: '반기보고서 (2022.06)'),
      f.copyWith(lastError: 'api-noData-annual-public:attempt=3;'),
      f.copyWith(consolidatedStatus: FilingFetchStatus.stored),
    ]) {
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(bad),
        false,
      );
    }
  });
}
