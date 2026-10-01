import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

DartFiling filing(
  String receipt,
  String corp,
  int year, {
  int publicAttempts = 1,
  FinancialReportCode code = FinancialReportCode.annual,
  String? name,
  FilingFetchStatus cfs = FilingFetchStatus.failed,
  FilingFetchStatus ofs = FilingFetchStatus.failed,
}) => DartFiling(
  rceptNo: receipt,
  corpCode: corp,
  bsnsYear: year,
  reportCode: code,
  reportName: name ?? '사업보고서 ($year.12)',
  consolidatedStatus: cfs,
  separateStatus: ofs,
  attempts: 7,
  lastError:
      'api-noData-annual-public:attempt=$publicAttempts; verified parser failure',
  discoveredAt: DateTime.utc(2026),
);
void main() {
  for (final (receipt, corp, year, bases) in [
    ('20251124000372', '01669794', 2024, {'OFS'}),
    ('20250320001616', '00442631', 2024, {'OFS', 'CFS'}),
    ('20250318000596', '01352575', 2024, {'OFS', 'CFS'}),
    ('20260318001043', '01018802', 2025, {'CFS'}),
  ]) {
    test('exact verified $receipt priority retains ledger/public attempts', () {
      final f = filing(receipt, corp, year);
      final original = f.toJson();
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        isTrue,
      );
      expect(f.toJson(), original);
      expect(f.attempts, 7);
    });
    for (final basis in ['CFS', 'OFS']) {
      test(
        '$receipt $basis only eligible when that source basis is verified',
        () {
          final f = filing(
            receipt,
            corp,
            year,
            cfs: basis == 'CFS'
                ? FilingFetchStatus.pending
                : FilingFetchStatus.stored,
            ofs: basis == 'OFS'
                ? FilingFetchStatus.pending
                : FilingFetchStatus.stored,
          );
          expect(
            FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
            bases.contains(basis),
          );
        },
      );
    }
    test('$receipt completed public noData basis is not re-prioritized', () {
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(
          filing(
            receipt,
            corp,
            year,
            cfs: FilingFetchStatus.noData,
            ofs: FilingFetchStatus.stored,
          ),
        ),
        isFalse,
      );
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(
          filing(
            receipt,
            corp,
            year,
            cfs: FilingFetchStatus.stored,
            ofs: FilingFetchStatus.noData,
          ),
        ),
        isFalse,
      );
      final fresh = filing(
        receipt,
        corp,
        year,
        cfs: FilingFetchStatus.noData,
        ofs: FilingFetchStatus.noData,
      ).copyWith(lastError: null);
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(fresh),
        isTrue,
      );
    });
    test(
      '$receipt rejects foreign corp/receipt/year/kind/period/attempt limit/completed',
      () {
        for (final f in [
          filing(receipt, '00000001', year),
          filing('${receipt.substring(0, 13)}9', corp, year),
          filing(receipt, corp, year + 1),
          filing(receipt, corp, year, code: FinancialReportCode.halfYear),
          filing(receipt, corp, year, name: '반기보고서 ($year.12)'),
          filing(receipt, corp, year, name: '사업보고서 ($year.11)'),
          filing(receipt, corp, year, name: '사업보고서 (${year + 1}.12)'),
          filing(receipt, corp, year, publicAttempts: 3),
          filing(receipt, corp, year, publicAttempts: 4),
          filing(
            receipt,
            corp,
            year,
            cfs: FilingFetchStatus.stored,
            ofs: FilingFetchStatus.stored,
          ),
          filing(
            receipt,
            corp,
            year,
            cfs: FilingFetchStatus.unsupported,
            ofs: FilingFetchStatus.unsupported,
          ),
        ]) {
          expect(
            FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
            isFalse,
            reason: f.toJson().toString(),
          );
        }
      },
    );
  }
}
