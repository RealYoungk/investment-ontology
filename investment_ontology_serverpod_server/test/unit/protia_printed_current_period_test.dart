import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/protia_printed_current_period.dart';

void main() {
  const dir = 'assets/financial_source_cache/20230320000571-ofs';
  final cover = File('$dir/cover.html').readAsStringSync(),
      body = File('$dir/ofs.html').readAsStringSync();
  final issuer = PublicIssuerLegalName(
    shellHtml: File('$dir/shell.html').readAsStringSync(),
    shellSource: Uri.parse(
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230320000571',
    ),
    overviewHtml: File('$dir/overview.html').readAsStringSync(),
    overviewSource: Uri.parse(
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230320000571&dcmNo=9074672&eleId=3&offset=20803&length=70974&dtd=dart3.xsd',
    ),
  );
  List<Map<String, dynamic>> parse({
    String? c,
    String? b,
    String rec = '20230320000571',
    String corp = '01267958',
    bool cfs = false,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: c ?? cover,
    statementHtml: b ?? body,
    coverSource: Uri.parse(ProtiaPrintedCurrentPeriod.coverUri),
    statementSource: Uri.parse(ProtiaPrintedCurrentPeriod.statementUri),
    receipt: rec,
    corpCode: corp,
    companyName: '주식회사 프로티아',
    periodStart: DateTime.utc(2022, 1, 1),
    periodEnd: DateTime.utc(2022, 12, 31),
    consolidated: cfs,
    issuerProof: issuer,
  );
  test('actual full printed current dates, seven whole values and honest nonnumeric term', () {
    final rows = parse();
    expect(rows.length, 8);
    final p =
        (rows.first['html_provenance'] as Map)['supportingPeriodEvidence']
            as Map;
    expect(p['numericTermSynthesized'], false);
    expect(p['currentProfit'], '1252814775');
  });
  for (final token in [
    '당기말 2022년',
    '당기 2022년',
    '2022.01.01',
    '2022.12.31',
    '1,252,814,775',
    '15,989,349,336',
    '14,525,145,962',
    '17,409,446,591',
    '1,420,097,255',
  ]) {
    test('reject independent raw current proof conflict $token', () {
      final changed = body.replaceAll(token, 'CONFLICT');
      expect(changed != body, true);
      expect(() => parse(b: changed), throwsFormatException);
    });
  }
  test('wrong own company/receipt/basis', () {
    expect(() => parse(corp: '00000000'), throwsFormatException);
    expect(() => parse(rec: '20230320000572'), throwsFormatException);
    expect(() => parse(cfs: true), throwsFormatException);
  });
}
