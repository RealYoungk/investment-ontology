import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

DartFiling filing({
  String corp = '01458161',
  String receipt = '20250526000504',
  int attempt = 2,
  String name = '사업보고서 (2024.12)',
  bool stored = false,
}) => DartFiling(
  rceptNo: receipt,
  corpCode: corp,
  reportName: name,
  bsnsYear: 2024,
  reportCode: FinancialReportCode.annual,
  discoveredAt: DateTime.utc(2026),
  consolidatedStatus: stored
      ? FilingFetchStatus.stored
      : FilingFetchStatus.pending,
  separateStatus: stored ? FilingFetchStatus.stored : FilingFetchStatus.failed,
  lastError: 'api-noData-annual-public:attempt=$attempt',
);
void main() {
  test('known verified TXR remaining CFS or OFS gains priority without changing attempts', () {
    final f = filing();
    expect(FinancialFactsSync.verifiedTxrRecoveryPriority(f), isTrue);
    expect(f.lastError, 'api-noData-annual-public:attempt=2');
  });
  test('exhausted attempts, foreign company, other receipt or period and already stored remain unprioritized', () {
    for (final f in [
      filing(attempt: 3),
      filing(corp: '00000001'),
      filing(receipt: '20250526000505'),
      filing(name: '사업보고서 (2024.11)'),
      filing(stored: true),
    ]) {
      expect(FinancialFactsSync.verifiedTxrRecoveryPriority(f), isFalse);
    }
  });
}
