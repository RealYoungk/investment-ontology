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
  test('actual own CFS onecell table gives typed absence', () async {
    final f = target(
      corp: '01353848',
      receipt: '20260331004637',
      year: 2025,
      name: '사업보고서 (2025.12)',
    );
    final r = await VerifiedAnnualSourceCache().verifyRegistered(
      f,
      company(corp: '01353848', name: '(주)이노벡스'),
      FsDiv.consolidated,
    );
    expect(r.numeric, isNull);
    expect(r.absence!.evidence, '해당사항없음');
    expect(r.absence!.statementSource.queryParameters['eleId'], '19');
  });
  for (final label in ['cfs', 'cover']) {
    test('tampered $label rejects', () async {
      final f = target(
        corp: '01353848',
        receipt: '20260331004637',
        year: 2025,
        name: '사업보고서 (2025.12)',
      );
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final b = await File(p).readAsBytes();
          return p.endsWith('/$label.html') ? [...b, 32] : b;
        },
      );
      await expectLater(
        cache.verifyRegistered(
          f,
          company(corp: '01353848', name: '(주)이노벡스'),
          FsDiv.consolidated,
        ),
        throwsFormatException,
      );
    });
  }
}
