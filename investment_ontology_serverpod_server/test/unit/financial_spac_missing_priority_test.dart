import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

DartFiling filing({
  String corp = '01601222',
  String receipt = '20230315000997',
  int year = 2022,
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
  test('only exact OFS is prioritized for both SPAC receipts', () {
    for (final p in [
      ('01601222', '20230315000997'),
      ('01476219', '20230308000311'),
    ]) {
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(
          filing(corp: p.$1, receipt: p.$2, cfs: FilingFetchStatus.stored),
        ),
        isTrue,
      );
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(
          filing(corp: p.$1, receipt: p.$2, ofs: FilingFetchStatus.stored),
        ),
        isFalse,
      );
    }
  });
  for (final p in [
    ('01601222', '20230315000997'),
    ('01476219', '20230308000311'),
  ]) {
    for (final f in [
      filing(corp: '00000001', receipt: p.$2),
      filing(corp: p.$1, receipt: '20260330001851'),
      filing(corp: p.$1, receipt: p.$2, year: 2021),
      filing(corp: p.$1, receipt: p.$2, kind: FinancialReportCode.halfYear),
      filing(
        corp: p.$1,
        receipt: p.$2,
        error: 'api-noData-annual-public:attempt=3; mismatch',
      ),
      filing(
        corp: p.$1,
        receipt: p.$2,
        cfs: FilingFetchStatus.stored,
        ofs: FilingFetchStatus.stored,
      ),
      filing(
        corp: p.$1,
        receipt: p.$2,
        cfs: FilingFetchStatus.failed,
        ofs: FilingFetchStatus.stored,
      ),
    ]) {
      test(
        'exact source rejects wrong/cap/basis/status ${f.toJson()}',
        () => expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
          isFalse,
        ),
      );
    }
  }
}
