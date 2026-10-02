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
  separateStatus: FilingFetchStatus.failed,
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
  test('Innovex official OFS attachment preserves direct whole7', () async {
    final f = target(
      corp: '01353848',
      receipt: '20260331004637',
      year: 2025,
      name: '사업보고서 (2025.12)',
    );
    final c = company(corp: '01353848', name: '(주)이노벡스');
    final result = await VerifiedAnnualSourceCache().verifyRegistered(
      f,
      c,
      FsDiv.separate,
    );
    final source = result.numeric!;
    expect(source.statementSource.queryParameters['dcmNo'], '11214857');
    expect(source.rows, hasLength(8));
    expect(
      source.rows.map((r) => r['thstrm_amount']),
      containsAll([
        '8360130649',
        '18944344124',
        '-10584213475',
        '6404028445',
        '-8534577157',
        '-8971893917',
        '-817842378',
        '-11316001',
      ]),
    );
    expect(source.rows.every((r) => r['account_id'] == null), isTrue);
  });
  test('changed official attachment bytes cannot replay', () async {
    final f = target(
      corp: '01353848',
      receipt: '20260331004637',
      year: 2025,
      name: '사업보고서 (2025.12)',
    );
    final c = company(corp: '01353848', name: '(주)이노벡스');
    final cache = VerifiedAnnualSourceCache(
      readAsset: (path) async {
        final b = await File(path).readAsBytes();
        return path.endsWith('/ofs.html') ? [...b, 32] : b;
      },
    );
    await expectLater(
      cache.verifyRegistered(f, c, FsDiv.separate),
      throwsFormatException,
    );
  });
  for (final bad in ['corp', 'year', 'period', 'basis']) {
    test('reject wrong $bad', () async {
      final f = target(
        corp: bad == 'corp' ? '99999999' : '01353848',
        receipt: '20260331004637',
        year: bad == 'year' ? 2024 : 2025,
        name: bad == 'period' ? '사업보고서 (2025.09)' : '사업보고서 (2025.12)',
      );
      final c = company(corp: '01353848', name: '(주)이노벡스');
      await expectLater(
        VerifiedAnnualSourceCache().verifyRegistered(
          f,
          c,
          bad == 'basis' ? FsDiv.consolidated : FsDiv.separate,
        ),
        throwsFormatException,
      );
    });
  }
}
