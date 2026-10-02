import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

void main() {
  for (final (receipt, corp) in [
    ('20260316001455', '00445869'),
    ('20260326000677', '01290132'),
  ]) {
    group(receipt, () {
      DartFiling filing() => DartFiling(
        id: 1,
        companyId: 1,
        corpCode: corp,
        rceptNo: receipt,
        bsnsYear: 2025,
        reportCode: FinancialReportCode.annual,
        reportName: '[기재정정]사업보고서 (2025.12)',
        consolidatedStatus: FilingFetchStatus.stored,
        separateStatus: FilingFetchStatus.failed,
        attempts: 3,
        lastError: 'api-noData-annual-public:attempt=2; previous failure',
        discoveredAt: DateTime.utc(2026),
      );
      test('exact OFS pending profile preserves prior CFS', () {
        final f = filing(), before = filing().toJson();
        expect(
          FinancialFactsSync.verifiedDurationSourceRecoveryPriority(f),
          isTrue,
        );
        expect(f.toJson(), before);
      });
      final cases = <String, void Function(DartFiling)>{
        'wrong corp': (f) => f.corpCode = '99999999',
        'wrong receipt': (f) => f.rceptNo = '19990101000000',
        'wrong year': (f) => f.bsnsYear = 2024,
        'wrong report kind': (f) => f.reportCode = FinancialReportCode.halfYear,
        'wrong period': (f) => f.reportName = '사업보고서 (2024.12)',
        'only wrong basis needs': (f) {
          f.consolidatedStatus = FilingFetchStatus.failed;
          f.separateStatus = FilingFetchStatus.stored;
        },
        'exhausted public': (f) => f.lastError =
            'api-noData-annual-public:attempt=3; previous failure',
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
    });
  }
}
