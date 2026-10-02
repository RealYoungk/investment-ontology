import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

void main() {
  DartFiling filing() => DartFiling(
    id: 1,
    companyId: 1,
    corpCode: '01018617',
    rceptNo: '20260327001807',
    bsnsYear: 2025,
    reportCode: FinancialReportCode.annual,
    reportName: '[기재정정]사업보고서 (2025.12)',
    consolidatedStatus: FilingFetchStatus.failed,
    separateStatus: FilingFetchStatus.stored,
    attempts: 3,
    lastError: 'api-noData-annual-public:attempt=2; previous failure',
    discoveredAt: DateTime.utc(2026),
  );
  test('exact CFS pending profile dispatches without changing prior OFS', () {
    final f = filing(), before = filing().toJson();
    expect(
      FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
      isTrue,
    );
    expect(f.toJson(), before);
  });
  final cases = <String, void Function(DartFiling)>{
    'wrong corp': (f) => f.corpCode = '01018618',
    'wrong receipt': (f) => f.rceptNo = '20260327001808',
    'wrong year': (f) => f.bsnsYear = 2024,
    'wrong report kind': (f) => f.reportCode = FinancialReportCode.halfYear,
    'wrong period': (f) => f.reportName = '사업보고서 (2024.12)',
    'only wrong basis needs': (f) {
      f.consolidatedStatus = FilingFetchStatus.stored;
      f.separateStatus = FilingFetchStatus.failed;
    },
    'exhausted public': (f) =>
        f.lastError = 'api-noData-annual-public:attempt=3; previous failure',
  };
  for (final e in cases.entries) {
    test(e.key, () {
      final f = filing();
      e.value(f);
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        isFalse,
      );
    });
  }
}
