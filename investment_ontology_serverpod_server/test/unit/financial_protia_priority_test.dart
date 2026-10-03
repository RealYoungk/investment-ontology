import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

void main() {
  DartFiling target() => DartFiling(
    rceptNo: '20230320000571',
    corpCode: '01267958',
    companyId: 1,
    reportName: '사업보고서 (2022.12)',
    bsnsYear: 2022,
    reportCode: FinancialReportCode.annual,
    attempts: 3,
    lastError: 'api-noData-annual-public:attempt=2',
    consolidatedStatus: FilingFetchStatus.failed,
    separateStatus: FilingFetchStatus.failed,
    discoveredAt: DateTime.utc(2026, 3, 18),
  );
  test('exact Protia printed annual period target priority keeps API attempts3 and publicattempt2', () {
    final f = target(), before = target().toJson();
    expect(FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f), true);
    expect(f.toJson(), before);
    expect(f.attempts, 3);
  });
  for (final div in ['OFS']) {
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
    'wrong year': target().copyWith(bsnsYear: 2023),
    'wrong period': target().copyWith(reportName: '사업보고서 (2023.12)'),
    'wrong month': target().copyWith(reportName: '[첨부추가]사업보고서 (2025.06)'),
    'wrong kind': target().copyWith(
      reportCode: FinancialReportCode.halfYear,
      reportName: '반기보고서 (2025.12)',
    ),
    'public cap3': target().copyWith(
      lastError: 'api-noData-annual-public:attempt=3',
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
