import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/anymedi_audit_period_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20230103000440',
    FsDiv.separate,
  )!;
  test('AnyMedi own main full365day8 plus audit witness', () async {
    final f = filing(e), c = company(e);
    final r = await VerifiedAnnualSourceCache().verifyRegistered(f, c, e.basis);
    final n = r.numeric!, rows = n.rows;
    expect(n.periodStart, DateTime.utc(2021, 1, 1));
    expect(n.periodEnd, DateTime.utc(2021, 12, 31));
    expect(rows.length, 8);
    final expected = jsonDecode(
      File('${e.assetDirectory}/expected-rows.json').readAsStringSync(),
    ) as List;
    for (var i = 0; i < 8; i++) {
      expect(rows[i]['account_nm'], expected[i][0]);
      expect(rows[i]['thstrm_amount'], expected[i][1]);
      expect(rows[i]['account_id'], isNull);
      final p = rows[i]['html_provenance'] as Map;
      expect(p['periodStart'], '2021-01-01');
      expect(p['unit'], '원');
      expect(p['unitMultiplier'], '1');
      expect(p['annualComparableToFullYear'], true);
      expect(p['coverPrintedEndConflict'], '2021-12-21');
      expect(p['coverConflictNotRewritten'], true);
      expect(p['supportingAuditReceipt'], '20221226000436');
      expect((p['supportingAuditSources'] as List).length, 3);
      expect(p['fullStatementCollected'], false);
    }
    expect(rows[5]['thstrm_amount'], '-11157925382');
    expect(rows.last['thstrm_amount'], '-1202826176');
    final facts = [
      for (var i = 0; i < 8; i++)
        FinancialFact(
          id: i + 1,
          reportId: 2,
          companyId: 1,
          sourceId: 3,
          bsnsYear: 2021,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          statement: i < 3
              ? FinancialStatementKind.balanceSheet
              : i < 6
              ? FinancialStatementKind.comprehensiveIncome
              : FinancialStatementKind.cashFlow,
          accountName: rows[i]['account_nm'] as String,
          amount: BigInt.parse(rows[i]['thstrm_amount'] as String),
          currency: 'KRW',
        ),
    ];
    expect(
      FinancialAccounts.pick(facts).map((a) => a.key).toSet(),
      containsAll([
        'assets',
        'liabilities',
        'equity',
        'revenue',
        'operatingIncome',
        'netIncome',
        'operatingCashFlow',
        'capex',
      ]),
    );
    final report = FinancialReport(
      id: 2,
      companyId: 1,
      rceptNo: e.receipt,
      bsnsYear: 2021,
      reportCode: FinancialReportCode.annual,
      fsDiv: e.basis,
      reportName: f.reportName,
      sourceId: 3,
      factCount: 8,
      fetchedAt: DateTime.utc(2026),
    );
    final source = Source(
      id: 3,
      kind: SourceKind.dartReport,
      reference: e.receipt,
      title: 'HTML 부분 핵심계정 SHA256:${n.sourceDigest}',
      url: n.statementSource.toString(),
      retrievedAt: DateTime.utc(2026),
    );
    final audit = Source(
      kind: SourceKind.dartReport,
      reference: 'financial-api-noData-source:${e.receipt}:separate',
      url: source.url,
      retrievedAt: DateTime.utc(2026),
      title: jsonEncode({
        'action': 'verified-keyless-annual-source-after-api-noData',
        'targetReceipt': e.receipt,
        'sourceReceipt': e.receipt,
        'corpCode': c.corpCode,
        'reportName': report.reportName,
        'fsDiv': 'separate',
        'format': 'html',
        'sha256': n.sourceDigest,
        'coreRows': 8,
        'coreRowProvenance': rows,
      }),
    );
    final duration = FinancialSourceDuration.validate(
      report: report,
      company: c,
      reportSource: source,
      audit: audit,
    );
    expect(duration, isNotNull);
    expect(duration!.days, 365);
    expect(duration.isShort, false);
    expect(duration.label, '2021.01.01 ~ 2021.12.31 (365일)');
  });
  for (final bad in [
    'corp',
    'year',
    'receipt',
    'quarter',
    'issuer',
    'shell',
    'cover',
    'ofs',
    'audit-shell',
    'audit-opinion',
    'audit-statement',
    'opposite',
  ]) {
    test('AnyMedi source rejects $bad', () async {
      final f = filing(e), c = company(e);
      switch (bad) {
        case 'corp':
          f.corpCode = '00000000';
        case 'year':
          f.bsnsYear = 2020;
        case 'receipt':
          f.rceptNo = '20260323000000';
        case 'quarter':
          f.reportCode = FinancialReportCode.halfYear;
        case 'issuer':
          c.name = '다른회사';
      }
      final cache = VerifiedAnnualSourceCache(
        readAsset: (path) async {
          final bytes = File(path).readAsBytesSync();
          return path.endsWith('$bad.html') ? [...bytes, 32] : bytes;
        },
      );
      expect(
        () => cache.verifyRegistered(
          f,
          c,
          bad == 'opposite' ? FsDiv.consolidated : e.basis,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  }
  test('AnyMedi declared actual interval rejects coverDec21', () {
    final p = AnyMediAuditPeriodSource.profile;
    final raw = <String, String>{
      for (final s in p['sources'] as List)
        s['label'] as String: File('${e.assetDirectory}/${s['file']}')
            .readAsStringSync(),
    };
    final uris = <String, Uri>{
      for (final s in p['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    expect(
      () => AnyMediAuditPeriodSource.parse(
        receipt: e.receipt,
        corpCode: e.corpCode,
        companyName: e.companyName,
        consolidated: false,
        start: DateTime.utc(2021),
        end: DateTime.utc(2021, 12, 21),
        raw: raw,
        uris: uris,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
