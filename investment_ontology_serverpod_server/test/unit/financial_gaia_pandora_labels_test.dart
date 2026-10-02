import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

const base = 'test/fixtures/financial_html/gaia-pandora-labels';
String raw(String receipt, String label) =>
    File('$base/$receipt/$label.html').readAsStringSync();
Map proof(String receipt) =>
    jsonDecode(File('$base/$receipt/proof.json').readAsStringSync()) as Map;
Uri uri(String receipt, String label) => Uri.parse(
  (proof(receipt)['sources'] as List).singleWhere(
    (s) => s['label'] == label,
  )['url'],
);
List<Map<String, dynamic>> parse(
  String receipt,
  String basis, {
  String? body,
}) => PublicFinancialHtml.parseStandardAnnual(
  coverHtml: raw(receipt, 'cover'),
  statementHtml: body ?? raw(receipt, basis),
  coverSource: uri(receipt, 'cover'),
  statementSource: uri(receipt, basis),
  receipt: receipt,
  corpCode: receipt == '20250331002057'
      ? '01229240'
      : receipt == '20250324000541'
      ? '01109690'
      : '00541862',
  companyName: receipt == '20250331002057'
      ? '(주)가이아코퍼레이션'
      : receipt == '20250324000541'
      ? '도부(주)'
      : '(주)판도라티비',
  periodStart: DateTime.utc(2024),
  periodEnd: DateTime.utc(2024, 12, 31),
  consolidated: basis == 'cfs',
);
FinancialFact fact(
  String label,
  FinancialStatementKind statement, {
  int id = 1,
  String? detail,
}) => FinancialFact(
  id: id,
  reportId: 1,
  companyId: 1,
  bsnsYear: 2024,
  reportCode: FinancialReportCode.annual,
  fsDiv: FsDiv.consolidated,
  statement: statement,
  accountName: label,
  accountDetail: detail,
  amount: BigInt.from(123),
  sourceId: 1,
);
void main() {
  for (final (receipt, basis, expected) in [
    (
      '20250331002057',
      'cfs',
      [
        '15816328779',
        '8915857379',
        '6900471400',
        '38633888094',
        '1559856344',
        '782413078',
        '1720344085',
      ],
    ),
    (
      '20250331002057',
      'ofs',
      [
        '15814969342',
        '8913314379',
        '6901654963',
        '38007328696',
        '743891690',
        '162080194',
        '1778904801',
      ],
    ),
    (
      '20250321001451',
      'cfs',
      [
        '22749749953',
        '6191642693',
        '16558107260',
        '16692604170',
        '1345038893',
        '2006257368',
        '3041316505',
      ],
    ),
  ]) {
    test(
      'actual whole seven printed accounts/source/period mapped $receipt:$basis',
      () {
        for (final label in ['cover', basis]) {
          expect(
            sha256
                .convert(File('$base/$receipt/$label.html').readAsBytesSync())
                .toString(),
            (proof(receipt)['sources'] as List).singleWhere(
              (s) => s['label'] == label,
            )['sha256'],
          );
        }
        final rows = parse(receipt, basis);
        expect(rows.take(7).map((r) => r['thstrm_amount']).toList(), expected);
        final facts = <FinancialFact>[];
        for (var i = 0; i < rows.length; i++) {
          final r = rows[i];
          final p = r['html_provenance'] as Map;
          expect(r['account_id'], isNull);
          expect(r['currency'], 'KRW');
          expect(p['source'], uri(receipt, basis).toString());
          expect(p['printedLabel'], r['account_nm']);
          expect(p['periodStart'], '2024-01-01');
          expect(p['periodEnd'], '2024-12-31');
          expect(p['unit'], '원');
          facts.add(
            fact(
              r['account_nm'],
              r['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : r['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.comprehensiveIncome,
              id: i + 1,
            ).copyWith(
              amount: BigInt.parse(r['thstrm_amount']),
              currency: 'KRW',
            ),
          );
        }
        final lines = FinancialAccounts.pick(facts);
        for (final (key, amount) in [
          ('revenue', expected[3]),
          ('netIncome', expected[5]),
          ('operatingCashFlow', expected[6]),
        ]) {
          expect(
            lines.singleWhere((l) => l.key == key).amount,
            BigInt.parse(amount),
          );
        }
        final sql = FinancialAccounts.resolvedIdSql('f');
        expect(sql, contains("'영업활동으로인한현금흐름(1+2+3)'"));
        expect(sql, contains("'연결당기순손익'"));
        if (receipt == '20250331002057') {
          expect(rows[6]['account_nm'], 'Ⅰ. 영업활동으로 인한 현금흐름(1+2+3)');
        }
        if (receipt == '20250321001451') {
          expect(rows[5]['account_nm'], 'Ⅵ. 연결당기순손익');
        }
      },
    );
  }
  for (final bad in [
    '현금흐름(1+2)',
    '현금흐름(1+2+4)',
    '현금흐름(1+2+3)기타',
    '현금흐름(주1+2+3)',
  ]) {
    test(
      'similar arithmetic CFO label rejected $bad',
      () => expect(
        () => parse(
          '20250331002057',
          'cfs',
          body: raw('20250331002057', 'cfs').replaceAll('현금흐름(1+2+3)', bad),
        ),
        throwsFormatException,
      ),
    );
  }
  for (final bad in [
    '지배기업연결당기순손익',
    '비지배지분연결당기순손익',
    '주당연결당기순손익',
    '계속영업연결당기순손익',
    '연결당기순손익의귀속',
  ]) {
    test(
      'whole profit cannot use attribution/EPS/continuing $bad',
      () => expect(
        () => parse(
          '20250321001451',
          'cfs',
          body: raw('20250321001451', 'cfs').replaceAll('연결당기순손익', bad),
        ),
        throwsFormatException,
      ),
    );
  }
  test('finite mappings reject malformed labels, wrong statements, details and duplicate candidates', () {
    for (final pair in [
      (
        '영업활동으로인한현금흐름(1+2+3)',
        'operatingCashFlow',
        FinancialStatementKind.cashFlow,
      ),
      ('연결당기순손익', 'netIncome', FinancialStatementKind.comprehensiveIncome),
    ]) {
      expect(
        FinancialAccounts.pick([fact(pair.$1, pair.$3)]).single.key,
        pair.$2,
      );
      expect(
        FinancialAccounts.pick([
          fact(pair.$1, FinancialStatementKind.equityChanges),
        ]),
        isEmpty,
      );
      expect(
        FinancialAccounts.pick([fact(pair.$1, pair.$3, detail: 'component')]),
        isEmpty,
      );
      expect(
        FinancialAccounts.pick([
          fact(pair.$1, pair.$3),
          fact(pair.$1, pair.$3, id: 2),
        ]),
        isEmpty,
      );
      for (final bad in ['기타${pair.$1}', '${pair.$1}기타', '${pair.$1}(1)']) {
        expect(FinancialAccounts.pick([fact(bad, pair.$3)]), isEmpty);
      }
    }
  });
  test(
    'actual Dobu inconsistent BS remains rejected despite seven printed rows',
    () => expect(() => parse('20250324000541', 'cfs'), throwsFormatException),
  );
}
