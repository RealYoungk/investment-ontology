import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

List<Map<String, dynamic>> parseCns({
  String? body,
  String receipt = '20260319000677',
  String corp = '01116380',
  bool consolidated = false,
}) {
  const dir = 'test/fixtures/financial_html/cns-year-only';
  final proof = jsonDecode(File('$dir/proof.json').readAsStringSync()) as Map;
  final sources = proof['sources'] as List;
  Uri uri(String label) => Uri.parse(
    (sources.singleWhere((s) => s['label'] == label) as Map)['url'],
  );
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: File('$dir/cover.html').readAsStringSync(),
    statementHtml: body ?? File('$dir/ofs.html').readAsStringSync(),
    coverSource: uri('cover'),
    statementSource: uri('ofs'),
    receipt: receipt,
    corpCode: corp,
    companyName: '씨앤에스링크',
    periodStart: DateTime.utc(2025, 1, 1),
    periodEnd: DateTime.utc(2025, 12, 31),
    consolidated: consolidated,
  );
}

void main() {
  test(
    'exact trailing numeric footnotes only; printed labels remain intact',
    () {
      expect(FinancialAccounts.normalizedName('Ⅰ.매출액(주석16,17)'), '매출액');
      expect(FinancialAccounts.normalizedName('매출액(주석16,A)'), '매출액(주석16,A)');
      expect(FinancialAccounts.normalizedName('매출(주석16)액'), '매출(주석16)액');
      expect(FinancialAccounts.normalizedName('매출액(주석)'), '매출액(주석)');
    },
  );
  final body = File('test/fixtures/financial_html/cns-year-only/ofs.html')
      .readAsStringSync();
  test('actual year-only core uses independently corroborated CE dates', () {
    final rows = parseCns();
    expect(rows.length, 7);
    expect(rows.every((r) => r['account_id'] == null), isTrue);
    final proof =
        (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
            as Map;
    expect(proof['closingEquity'], '3800784543');
    expect(proof['currentProfit'], '1179965236');
    expect(proof['periodStart'], '2025-01-01');
    expect(proof['periodEnd'], '2025-12-31');
  });
  for (final mutation in <String, String>{
    'wrong CE opening date': body.replaceAll('2025.1.1', '2025.2.1'),
    'wrong CE closing date': body.replaceAll('2025.12.31', '2025.12.30'),
    'wrong term': body.replaceAll('제26기', '제27기'),
    'duplicate current header': body
        .replaceAll('2024년도', '2025년도')
        .replaceAll('제25기', '제26기'),
    'foreign unit': body.replaceAll('단위 : 원', '단위 : USD'),
    'contradictory closing equity': body.replaceFirst(
      '3,800,784,543',
      '3,800,784,544',
    ),
    'contradictory current profit': body.replaceFirst(
      '1,179,965,236',
      '1,179,965,237',
    ),
    'missing equity table': body.replaceAll('자본변동표', '기타변동표'),
  }.entries) {
    test(
      mutation.key,
      () => expect(() => parseCns(body: mutation.value), throwsFormatException),
    );
  }
  test(
    'foreign receipt rejects',
    () => expect(
      () => parseCns(receipt: '20260319000678'),
      throwsFormatException,
    ),
  );
  test(
    'foreign company rejects',
    () => expect(() => parseCns(corp: '01116381'), throwsFormatException),
  );
  test(
    'wrong basis rejects',
    () => expect(() => parseCns(consolidated: true), throwsFormatException),
  );
}
