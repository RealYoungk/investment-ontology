import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dozn_corroborated_flow_period.dart';

void main() {
  final cover = File(
    'assets/financial_source_cache/20250328001780-ofs/cover.html',
  ).readAsStringSync();
  final body = File('assets/financial_source_cache/20250328001780-ofs/ofs.html')
      .readAsStringSync();
  List<Map<String, dynamic>> parse({
    String? c,
    String? b,
    String receipt = '20250328001780',
    String corp = '01563667',
    bool cfs = false,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: c ?? cover,
    statementHtml: b ?? body,
    coverSource: Uri.parse(DoznCorroboratedFlowPeriod.coverUri),
    statementSource: Uri.parse(DoznCorroboratedFlowPeriod.statementUri),
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
      rows.where((r) => r['thstrm_amount'] == '62698656963'),
      hasLength(1),
    );
    final proof =
        (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
            as Map;
    expect(proof['flowCaptionPrintedStart'], false);
    expect(proof['openingCash'], '61061036103');
  });
  for (final token in [
    '2024.01.01',
    '2024.12.31',
    '10,348,432,461',
    '41,377,666,510',
    '61,061,036,103',
    '79,158,449,860',
    '18,086,566,418',
    '10,847,339',
    '21,300,356,609',
    '30,431,701,786',
    '단위',
    '2024년 12월 31일',
    '제 8 기',
    '115,670,733,823',
    '74,293,067,313',
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
    expect(() => parse(cfs: true), throwsFormatException);
  });
  test('annual start conflict rejected', () {
    expect(
      () => parse(c: cover.replaceAll('01월', '02월')),
      throwsFormatException,
    );
  });
}
