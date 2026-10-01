import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:test/test.dart';

void main() {
  const receipt = '20260709000400';
  const digest =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const url =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=21&offset=109130&length=43771&dtd=dart4.xsd';
  final company = Company(id: 1, corpCode: '00925967', name: '이엠티');
  FinancialSourceDuration? check({
    int year = 2026,
    String period = '2026.03',
    String start = '2026-01-01',
    String end = '2026-03-31',
    void Function(Map<String, dynamic>)? change,
    bool manual = false,
    String? reportUrl,
    String? sourceSha,
    String? rawJson,
  }) {
    final report = FinancialReport(
      id: 2,
      companyId: 1,
      rceptNo: receipt,
      bsnsYear: year,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.separate,
      reportName: '사업보고서 ($period)',
      sourceId: 3,
      factCount: 7,
      fetchedAt: DateTime.utc(2026),
    );
    final source = Source(
      id: 3,
      kind: SourceKind.dartReport,
      reference: receipt,
      title: 'HTML 부분 핵심계정 SHA256:${sourceSha ?? digest}',
      url: reportUrl ?? url,
      retrievedAt: DateTime.utc(2026),
    );
    final metadata = <String, dynamic>{
      'action': 'verified-keyless-annual-source-after-api-noData',
      'targetReceipt': receipt,
      'sourceReceipt': receipt,
      'corpCode': company.corpCode,
      'reportName': report.reportName,
      'fsDiv': 'separate',
      'format': 'html',
      'sha256': digest,
      'coreRows': 7,
      'coreRowProvenance': List.generate(
        7,
        (_) => {
          'currency': 'KRW',
          'html_provenance': {
            'source': url,
            'basis': 'OFS',
            'periodStart': start,
            'periodEnd': end,
          },
        },
      ),
    };
    change?.call(metadata);
    final audit = Source(
      kind: manual ? SourceKind.manual : SourceKind.dartReport,
      reference: 'financial-api-noData-source:$receipt:separate',
      title: rawJson ?? jsonEncode(metadata),
      url: url,
      retrievedAt: DateTime.utc(2026),
    );
    return FinancialSourceDuration.validate(
      report: report,
      company: company,
      reportSource: source,
      audit: audit,
    );
  }

  FinancialSourceDuration? anchor({
    void Function(Map<String, dynamic>)? change,
    String? sourceCorp,
    String? targetCorp,
    String? targetName,
  }) {
    final report = FinancialReport(
      id: 2,
      companyId: 1,
      rceptNo: receipt,
      bsnsYear: 2026,
      reportCode: FinancialReportCode.annual,
      fsDiv: FsDiv.separate,
      reportName: '사업보고서 (2026.03)',
      sourceId: 3,
      factCount: 7,
      fetchedAt: DateTime.utc(2026),
    );
    final source = Source(
      id: 3,
      kind: SourceKind.dartReport,
      reference: receipt,
      title: 'DART 원문 XBRL 핵심계정 · SHA256:$digest',
      url: 'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$receipt',
      retrievedAt: DateTime.utc(2026),
    );
    DartFiling filing(String r, String corp, String name) => DartFiling(
      rceptNo: r,
      companyId: 1,
      corpCode: corp,
      reportName: name,
      bsnsYear: 2026,
      reportCode: FinancialReportCode.annual,
      consolidatedStatus: FilingFetchStatus.stored,
      separateStatus: FilingFetchStatus.stored,
      discoveredAt: DateTime.utc(2026),
    );
    const target = '20260710000001';
    final metadata = <String, dynamic>{
      'kind': 'verified-source-cover-period-metadata', 'sourceReceipt': receipt,
      'targetReceipt': target, 'corpCode': company.corpCode,
      'coverSource': url,
      'shellSource': 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
      // Cover digest is a different document from the monetary ZIP digest.
      'sha256':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'periodStart': '2025-04-01T00:00:00.000Z',
      'periodEnd': '2026-03-31T00:00:00.000Z',
    };
    change?.call(metadata);
    final audit = Source(
      kind: SourceKind.dartReport,
      reference: 'financial-source-period-anchor:$receipt:$target',
      url: url,
      title: jsonEncode(metadata),
      retrievedAt: DateTime.utc(2026),
    );
    return FinancialSourceDuration.validateAnchor(
      report: report,
      company: company,
      reportSource: source,
      audit: audit,
      sourceFiling: filing(
        receipt,
        sourceCorp ?? company.corpCode,
        report.reportName,
      ),
      targetFiling: filing(
        target,
        targetCorp ?? company.corpCode,
        targetName ?? report.reportName,
      ),
    );
  }

  test('364 and 367 days are not exact twelve months; closing day must be month end', () {
    expect(
      check(period: '2026.12', start: '2026-01-02', end: '2026-12-31')!.isShort,
      isTrue,
    );
    expect(
      FinancialSourceDuration(
        DateTime.utc(2025, 12, 30),
        DateTime.utc(2026, 12, 31),
      ).isShort,
      isTrue,
    );
    expect(check(end: '2026-03-30'), isNull);
  });

  test('independent original-cover anchor proves a full year without equating cover and ZIP hashes', () {
    expect(anchor()!.days, 365);
    expect(anchor()!.isShort, isFalse);
    expect(anchor(change: (m) => m['periodStart'] = '2026-01-01')!.days, 90);
  });
  test('foreign company, target period, receipt, cover or shell cannot anchor dates', () {
    expect(anchor(sourceCorp: 'foreign'), isNull);
    expect(anchor(targetCorp: 'foreign'), isNull);
    expect(anchor(targetName: '사업보고서 (2026.06)'), isNull);
    for (final field in [
      'targetReceipt',
      'sourceReceipt',
      'corpCode',
      'kind',
      'sha256',
    ]) {
      expect(anchor(change: (m) => m[field] = 'wrong'), isNull, reason: field);
    }
    expect(
      anchor(
        change: (m) => m['shellSource'] =
            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260710000001',
      ),
      isNull,
    );
    expect(
      anchor(change: (m) => m['coverSource'] = 'https://example.com/foreign'),
      isNull,
    );
    expect(anchor(change: (m) => m['periodStart'] = '2026-02-30'), isNull);
  });

  test(
    'source-bound 90 days are explicit; 365 and 366 remain eligible full years',
    () {
      expect(check()!.label, '2026.01.01 ~ 2026.03.31 (90일)');
      expect(check()!.isShort, isTrue);
      expect(check(period: '2026.12', end: '2026-12-31')!.days, 365);
      expect(check(period: '2026.12', end: '2026-12-31')!.isShort, isFalse);
      expect(
        check(
          year: 2024,
          period: '2024.12',
          start: '2024-01-01',
          end: '2024-12-31',
        )!.days,
        366,
      );
    },
  );
  test('malformed dates or JSON never infer a short period or throw', () {
    expect(check(start: '2026-02-30'), isNull);
    expect(check(start: '2026-04-01'), isNull);
    expect(check(end: '2026-02-28'), isNull);
    expect(check(rawJson: '{broken'), isNull);
    expect(check(rawJson: '[]'), isNull);
  });
  test('wrong identity, mixed periods, URL or SHA reject proof', () {
    for (final field in [
      'targetReceipt',
      'sourceReceipt',
      'corpCode',
      'fsDiv',
      'reportName',
      'action',
    ]) {
      expect(check(change: (m) => m[field] = 'wrong'), isNull, reason: field);
    }
    expect(check(manual: true), isNull);
    expect(
      check(
        change: (m) =>
            ((m['coreRowProvenance'] as List).last['html_provenance']
                    as Map)['periodEnd'] =
                '2026-03-30',
      ),
      isNull,
    );
    expect(check(change: (m) => m['coreRows'] = 8), isNull);
    expect(check(reportUrl: 'https://example.com/foreign'), isNull);
    expect(
      check(
        sourceSha:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ),
      isNull,
    );
    expect(
      check(
        change: (m) =>
            ((m['coreRowProvenance'] as List).first['html_provenance']
                    as Map)['source'] =
                'https://example.com/foreign',
      ),
      isNull,
    );
  });
}
