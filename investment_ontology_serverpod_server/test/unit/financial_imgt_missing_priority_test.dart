import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

DartFiling filing({
  String corp = '01579020',
  String receipt = '20260330001850',
  int year = 2025,
  FinancialReportCode kind = FinancialReportCode.annual,
  String error = 'api-noData-annual-public:attempt=2; Annual current statement title period mismatch',
  FilingFetchStatus cfs = FilingFetchStatus.failed,
  FilingFetchStatus ofs = FilingFetchStatus.failed,
}) => DartFiling(
  corpCode: corp,
  rceptNo: receipt,
  bsnsYear: year,
  reportName: '사업보고서 ($year.12)',
  reportCode: kind,
  discoveredAt: DateTime.utc(2026),
  attempts: 3,
  lastError: error,
  consolidatedStatus: cfs,
  separateStatus: ofs,
);
void main() {
  test('exact independently missing CFS and OFS are prioritized', () {
    for (final cfs in [true, false]) {
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(
          filing(
            cfs: cfs ? FilingFetchStatus.failed : FilingFetchStatus.stored,
            ofs: cfs ? FilingFetchStatus.stored : FilingFetchStatus.failed,
          ),
        ),
        isTrue,
      );
    }
  });
  for (final f in [
    filing(corp: '01579021'),
    filing(receipt: '20260330001851'),
    filing(year: 2024),
    filing(kind: FinancialReportCode.halfYear),
    filing(error: 'api-noData-annual-public:attempt=3; mismatch'),
    filing(cfs: FilingFetchStatus.stored, ofs: FilingFetchStatus.stored),
  ]) {
    test(
      'wrong identity or cap/status rejects ${f.toJson()}',
      () => expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        isFalse,
      ),
    );
  }
}
