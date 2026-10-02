import 'dart:io';
import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/pureun_six_core_profile.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  final cover = File('test/fixtures/financial_html/pureun-six-core/cover.html')
      .readAsStringSync();
  final statement = File(
    'test/fixtures/financial_html/pureun-six-core/ofs.html',
  ).readAsStringSync();
  List<Map<String, dynamic>> parse({
    String? html,
    String? coverHtml,
    String receipt = '20230315000460',
    String corp = '00124805',
    String name = '(주)푸른저축은행',
    bool cfs = false,
    DateTime? end,
    Uri? source,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: coverHtml ?? cover,
    statementHtml: html ?? statement,
    coverSource: Uri.parse(PureunSixCoreProfile.coverUri),
    statementSource: source ?? Uri.parse(PureunSixCoreProfile.statementUri),
    receipt: receipt,
    corpCode: corp,
    companyName: name,
    periodStart: DateTime.utc(2022),
    periodEnd: end ?? DateTime.utc(2022, 12, 31),
    consolidated: cfs,
  );
  bool proof(List<Map<String, dynamic>> rows) =>
      PureunSixCoreProfile.storedProof(
        rows,
        sourceDigest: PureunSixCoreProfile.digest,
        sourceUrl: PureunSixCoreProfile.statementUri,
        companyCode: '00124805',
        targetReceipt: '20230315000460',
        basis: 'separate',
        year: 2022,
        reportName: '사업보고서 (2022.12)',
      );
  test(
    'actual whole company six exact primary amounts and unknown CE unit',
    () {
      final rows = parse();
      expect(rows, hasLength(6));
      expect(
        rows.map((r) => r['thstrm_amount']),
        unorderedEquals(PureunSixCoreProfile.amounts.values),
      );
      expect(proof(rows), isTrue);
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(row['currency'], 'KRW');
        expect(
          row['html_provenance']['pureunSixCore']['cePrintedUnit'],
          'unknown',
        );
        expect(
          row['html_provenance']['pureunSixCore']['missingRequiredAccounts'],
          ['revenue'],
        );
      }
    },
  );
  test('wrong corporation receipt basis master name end and node reject', () {
    for (final f in [
      () => parse(corp: '00000000'),
      () => parse(receipt: '20230315000461'),
      () => parse(cfs: true),
      () => parse(name: '다른회사'),
      () => parse(end: DateTime.utc(2021, 12, 31)),
      () => parse(
        source: Uri.parse(
          PureunSixCoreProfile.statementUri.replaceFirst(
            'eleId=19',
            'eleId=20',
          ),
        ),
      ),
    ]) {
      expect(f, throwsFormatException);
    }
  });
  test('raw source changes money CE dates currency aggregate and duplicate rows reject', () {
    for (final changed in [
      statement.replaceFirst('1,408,747,122,384', '1,408,747,122,385'),
      statement.replaceFirst('2022.12.31', '2021.12.31'),
      statement.replaceFirst('(단위 : 원)', '(단위 : 천원)'),
      statement.replaceFirst('X. 영업이익', 'X. 영업수익'),
      statement.replaceFirst('20,081,583,946', '20,081,583,947'),
      '$statement ',
    ]) {
      expect(() => parse(html: changed), throwsFormatException);
    }
    expect(() => parse(coverHtml: '$cover '), throwsFormatException);
  });
  test('caller audit cannot assign CE currency or alter current value', () {
    for (final field in [
      'cePrintedUnit',
      'ceWholeProfit',
      'ceEndingEquity',
      'ceCurrentStartRow',
    ]) {
      final rows = parse();
      rows.first['html_provenance']['pureunSixCore'][field] = 'tampered';
      expect(proof(rows), isFalse);
    }
    final rows = parse();
    rows.first['thstrm_amount'] = '0';
    expect(proof(rows), isFalse);
    final fakePrinted = parse();
    fakePrinted.first['html_provenance']['printedAmount'] =
        '1,,408,747,122,384';
    fakePrinted.first['html_provenance']['printedCurrentCells'] = [
      '1,,408,747,122,384',
    ];
    expect(proof(fakePrinted), isFalse);
  });
  test('source duration accepts only the exact six audit and cannot accept a six-row caller flag', () {
    final c = Company(
      id: 1,
      corpCode: PureunSixCoreProfile.corpCode,
      name: '(주)푸른저축은행',
    );
    final r = FinancialReport(
      id: 2,
      companyId: 1,
      rceptNo: PureunSixCoreProfile.receipt,
      bsnsYear: 2022,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.separate,
      reportName: '사업보고서 (2022.12)',
      sourceId: 3,
      factCount: 6,
      fetchedAt: DateTime.utc(2026),
    );
    final source = Source(
      id: 3,
      kind: SourceKind.dartReport,
      reference: r.rceptNo,
      title:
          '${PureunSixCoreProfile.title} SHA256:${PureunSixCoreProfile.digest}',
      url: PureunSixCoreProfile.statementUri,
      retrievedAt: DateTime.utc(2026),
    );
    final payload = <String, dynamic>{
      'action': 'verified-keyless-annual-source-after-api-noData',
      'targetReceipt': r.rceptNo,
      'sourceReceipt': r.rceptNo,
      'corpCode': c.corpCode,
      'reportName': r.reportName,
      'fsDiv': 'separate',
      'format': 'html',
      'sha256': PureunSixCoreProfile.digest,
      'coverSource': PureunSixCoreProfile.coverUri,
      'coreRows': 6,
      'coreRowProvenance': parse(),
    };
    FinancialSourceDuration? check() => FinancialSourceDuration.validate(
      report: r,
      company: c,
      reportSource: source,
      audit: Source(
        kind: SourceKind.dartReport,
        reference: 'financial-api-noData-source:${r.rceptNo}:separate',
        title: jsonEncode(payload),
        url: source.url,
        retrievedAt: DateTime.utc(2026),
      ),
    );
    expect(check()?.days, 365);
    payload['coreRowProvenance'][0]['html_provenance']['pureunSixCore']['cePrintedUnit'] =
        '원';
    expect(check(), isNull);
  });
}
