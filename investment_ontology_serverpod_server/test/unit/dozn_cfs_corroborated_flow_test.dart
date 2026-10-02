import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dozn_corroborated_flow_period.dart';

void main() {
  final cover = File(
    'assets/financial_source_cache/20250328001780-cfs/cover.html',
  ).readAsStringSync();
  final body = File('assets/financial_source_cache/20250328001780-cfs/cfs.html')
      .readAsStringSync();
  List<Map<String, dynamic>> parse({
    String? c,
    String? b,
    String receipt = '20250328001780',
    String corp = '01563667',
    bool cfs = true,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: c ?? cover,
    statementHtml: b ?? body,
    coverSource: Uri.parse(DoznCorroboratedFlowPeriod.coverUri),
    statementSource: Uri.parse(DoznCorroboratedFlowPeriod.consolidatedUri),
    receipt: receipt,
    corpCode: corp,
    companyName: '(주)더즌',
    periodStart: DateTime.utc(2024, 1, 1),
    periodEnd: DateTime.utc(2024, 12, 31),
    consolidated: cfs,
  );
  test('actual immutable source has direct core and honest corroborated flow provenance', () {
    final rows = parse();
    expect(rows.length, 8);
    expect(
      rows.map((r) => r['thstrm_amount']),
      unorderedEquals([
        '115669842342',
        '74302000525',
        '41367841817',
        '62657767124',
        '10022797774',
        '9917308588',
        '20891307095',
        '-1467710372',
      ]),
    );
    expect(rows.any((r) => r['thstrm_amount'] == '10028364955'), false);
    expect(
      rows.where((r) => r['thstrm_amount'] == '62657767124'),
      hasLength(1),
    );
    final proof =
        (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
            as Map;
    expect(proof['flowCaptionPrintedStart'], false);
    expect(proof['openingCash'], '62036528499');
  });
  for (final token in [
    '2024.01.01',
    '2024.12.31',
    '9,917,308,588',
    '41,367,841,817',
    '62,036,528,499',
    '80,683,745,769',
    '18,544,830,439',
    '102,386,831',
    '20,891,307,095',
    '30,759,747,402',
    '단위',
    '2024년 12월 31일',
    '제 8 기',
    '115,669,842,342',
    '74,302,000,525',
  ]) {
    test('independent printed evidence conflict: $token', () {
      final changed = body.replaceAll(token, 'CONFLICT');
      expect(changed != body, isTrue);
      expect(() => parse(b: changed), throwsFormatException);
    });
  }
  test('wrong own company/receipt/basis rejected', () {
    expect(() => parse(corp: '00000000'), throwsFormatException);
    expect(() => parse(receipt: '20250328001781'), throwsFormatException);
    expect(() => parse(cfs: false), throwsFormatException);
  });
  test('annual start conflict rejected', () {
    expect(
      () => parse(c: cover.replaceAll('01월', '02월')),
      throwsFormatException,
    );
  });
}
