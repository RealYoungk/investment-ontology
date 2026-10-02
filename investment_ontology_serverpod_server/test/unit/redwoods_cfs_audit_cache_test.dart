import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

DartFiling target({
  String corp = '01020269',
  String receipt = '20260323001652',
  int year = 2025,
  FinancialReportCode kind = FinancialReportCode.annual,
  String name = '사업보고서 (2025.12)',
  FilingFetchStatus cfs = FilingFetchStatus.failed,
  int cap = 3,
}) => DartFiling(
  id: 1,
  companyId: 1,
  rceptNo: receipt,
  corpCode: corp,
  bsnsYear: year,
  reportCode: kind,
  reportName: name,
  consolidatedStatus: cfs,
  separateStatus: FilingFetchStatus.stored,
  attempts: 7,
  lastError: 'api-noData-annual-public:attempt=$cap; previous failure',
  discoveredAt: DateTime.utc(2026),
);
Company company({
  String corp = '01020269',
  String name = '(주) 탈로스',
  String? stock = '231090',
}) => Company(
  id: 1,
  corpCode: corp,
  name: name,
  stockCode: stock,
  fiscalMonth: 12,
);
void main() {
  test('RW official CFS attachment preserves direct whole7', () async {
    final f = target(
      corp: '00990396',
      receipt: '20250321001825',
      year: 2024,
      name: '사업보고서 (2024.12)',
    );
    final c = company(corp: '00990396', name: '(주)레드우즈');
    final result = await VerifiedAnnualSourceCache().verifyRegistered(
      f,
      c,
      FsDiv.consolidated,
    );
    final source = result.numeric!;
    expect(source.statementSource.queryParameters['dcmNo'], '10450232');
    expect(
      source.rows.map((r) => r['thstrm_amount']),
      containsAll([
        '27655923765',
        '24989599096',
        '2666324669',
        '13636364',
        '-2842030359',
        '-5035450099',
        '-2396964906',
      ]),
    );
    expect(source.rows.every((r) => r['account_id'] == null), isTrue);
  });
  test('changed official attachment bytes cannot replay', () async {
    final f = target(
      corp: '00990396',
      receipt: '20250321001825',
      year: 2024,
      name: '사업보고서 (2024.12)',
    );
    final c = company(corp: '00990396', name: '(주)레드우즈');
    final cache = VerifiedAnnualSourceCache(
      readAsset: (path) async {
        final b = await File(path).readAsBytes();
        return path.endsWith('/cfs.html') ? [...b, 32] : b;
      },
    );
    await expectLater(
      cache.verifyRegistered(f, c, FsDiv.consolidated),
      throwsFormatException,
    );
  });
}
