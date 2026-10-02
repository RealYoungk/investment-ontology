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
    ('20240814001895', '01022142', 2023, {'OFS'}),
    ('20241104000113', '01518506', 2023, {'OFS'}),
    ('20230328000161', '01315042', 2022, {'OFS'}),
    ('20240808000099', '00565215', 2023, {'OFS'}),
    ('20230323000665', '01026616', 2022, {'OFS'}),
    ('20250320001369', '01353848', 2024, {'OFS'}),
    ('20250326000875', '01085187', 2024, {'OFS'}),
    ('20250409000365', '00925967', 2024, {'OFS'}),
    ('20250407003814', '01119651', 2024, {'CFS'}),
    ('20250331002057', '01229240', 2024, {'CFS', 'OFS'}),
    ('20250321001451', '00541862', 2024, {'CFS'}),
    ('20230321001265', '01344363', 2022, {'OFS'}),
    ('20220819000262', '00450931', 2021, {'OFS'}),
    ('20230320001037', '00296290', 2022, {'CFS'}),
    ('20260323000876', '01352575', 2025, {'OFS'}),
    ('20260323000661', '01262023', 2025, {'OFS'}),
    ('20260323000763', '01119651', 2025, {'CFS'}),
    ('20260330001331', '01118643', 2025, {'OFS'}),
    ('20260319001111', '01188730', 2025, {'OFS'}),
    ('20260331003389', '00414540', 2025, {'OFS'}),
    ('20260323001652', '01020269', 2025, {'OFS'}),
    ('20220316000721', '00337296', 2021, {'OFS'}),
    ('20220322000487', '00521433', 2021, {'OFS'}),
    ('20220321000166', '01117422', 2021, {'OFS'}),
    ('20260709000504', '01034730', 2025, {'OFS'}),
    ('20250321001900', '00765897', 2024, {'OFS'}),
    ('20260319000348', '00521433', 2025, {'OFS'}),
    ('20260319000707', '00553025', 2025, {'CFS'}),
    ('20260323001028', '00611286', 2025, {'OFS'}),
    ('20250321001632', '00816696', 2024, {'OFS'}),
    ('20250321000468', '01117422', 2024, {'OFS'}),
    ('20250325000306', '01290132', 2024, {'OFS'}),
    ('20251124000372', '01669794', 2024, {'OFS'}),
    ('20250320001616', '00442631', 2024, {'OFS', 'CFS'}),
    ('20250318000596', '01352575', 2024, {'OFS', 'CFS'}),
    ('20260318001043', '01018802', 2025, {'CFS'}),
    ('20260318001370', '01507722', 2025, {'CFS'}),
    ('20260318000161', '00533809', 2025, {'CFS'}),
    ('20260313000656', '00393618', 2025, {'CFS'}),
    ('20260316001089', '01187458', 2025, {'CFS'}),
    ('20260309001126', '00965062', 2025, {'CFS'}),
    ('20251127001320', '01507722', 2024, {'CFS'}),
    ('20251127001311', '01507722', 2023, {'CFS'}),
    ('20250319000677', '01187458', 2024, {'CFS'}),
    ('20250318000162', '00533809', 2024, {'CFS'}),
    ('20250314001680', '00965062', 2024, {'CFS'}),
    ('20250314001180', '00393618', 2024, {'CFS'}),
    ('20240320000695', '01187458', 2023, {'CFS'}),
    ('20240318000263', '00533809', 2023, {'CFS'}),
    ('20240315000148', '00393618', 2023, {'CFS'}),
    ('20240313000197', '00965062', 2023, {'CFS'}),
    ('20230711000155', '01507722', 2022, {'CFS'}),
    ('20230327000966', '00533809', 2022, {'CFS'}),
    ('20230323001231', '01187458', 2022, {'CFS'}),
    ('20230317000730', '00965062', 2022, {'CFS'}),
    ('20230317000450', '00393618', 2022, {'CFS'}),
    ('20220722000193', '00533809', 2021, {'CFS'}),
    ('20220321000662', '01187458', 2021, {'CFS'}),
    ('20220318000594', '00965062', 2021, {'CFS'}),
    ('20220317000026', '00393618', 2021, {'CFS'}),
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
          filing('20990101000000', corp, year),
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
