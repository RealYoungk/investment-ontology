import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

void main() {
  for (final profile in [
    ('20240401000698', '01229240', 2023, false),
    ('20220315000038', '01035942', 2021, true),
    ('20260309001820', '01205514', 2025, false),
    ('20240321000933', '01206717', 2023, true),
  ]) {
    final receipt = profile.$1,
        corp = profile.$2,
        year = profile.$3,
        cfs = profile.$4;
    DartFiling target() => DartFiling(
      rceptNo: receipt,
      corpCode: corp,
      companyId: 1,
      reportName: '사업보고서 ($year.12)',
      bsnsYear: year,
      reportCode: FinancialReportCode.annual,
      attempts: 3,
      lastError: 'api-noData-annual-public:attempt=2',
      consolidatedStatus: FilingFetchStatus.failed,
      separateStatus: FilingFetchStatus.failed,
      discoveredAt: DateTime.utc(2026, 3, 18),
    );
    test('exact current attachment target priority keeps API attempts3 and publicattempt2', () {
      final f = target(), before = target().toJson();
      expect(
        FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
        true,
      );
      expect(f.toJson(), before);
      expect(f.attempts, 3);
    });
    for (final div in [cfs ? 'CFS' : 'OFS']) {
      test('verified $div still needs recovery', () {
        final f = target().copyWith(
          consolidatedStatus: div == 'CFS'
              ? FilingFetchStatus.pending
              : FilingFetchStatus.stored,
          separateStatus: div == 'OFS'
              ? FilingFetchStatus.failed
              : FilingFetchStatus.stored,
        );
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
          true,
        );
      });
    }
    final negatives = <String, DartFiling>{
      'wrong corp': target().copyWith(corpCode: '00963001'),
      'original source receipt': target().copyWith(rceptNo: '20260317000808'),
      'wrong year': target().copyWith(bsnsYear: year - 1),
      'wrong period': target().copyWith(reportName: '사업보고서 (${year - 1}.12)'),
      'wrong month': target().copyWith(reportName: '사업보고서 ($year.06)'),
      'wrong kind': target().copyWith(
        reportCode: FinancialReportCode.halfYear,
        reportName: '반기보고서 ($year.12)',
      ),
      'public cap3': target().copyWith(
        lastError: 'api-noData-annual-public:attempt=3',
      ),
      'verified basis stored only unsupported basis failed': target().copyWith(
        consolidatedStatus: cfs
            ? FilingFetchStatus.stored
            : FilingFetchStatus.failed,
        separateStatus: cfs
            ? FilingFetchStatus.failed
            : FilingFetchStatus.stored,
      ),
      'already stored': target().copyWith(
        consolidatedStatus: FilingFetchStatus.stored,
        separateStatus: FilingFetchStatus.stored,
      ),
      'source absent bases': target().copyWith(
        consolidatedStatus: FilingFetchStatus.noData,
        separateStatus: FilingFetchStatus.noData,
      ),
    };
    for (final e in negatives.entries) {
      test('reject ${e.key}', () {
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(e.value),
          false,
        );
      });
    }
  }
}
