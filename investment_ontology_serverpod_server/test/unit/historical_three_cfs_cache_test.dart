import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

void main() {
  final entries = VerifiedAnnualSourceRegistry.entries.where(
    (e) => e.ruleVersion == 'historical-receipt-bound-cfs-explicit-none-v1',
  );
  for (final e in entries) {
    test(
      '${e.receipt} normal cached exact absence without numeric transplant',
      () async {
        final filing = DartFiling(
          id: 1,
          companyId: 1,
          corpCode: e.corpCode,
          rceptNo: e.receipt,
          bsnsYear: e.year,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (${e.year}.12)',
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'api-noData-annual-public:attempt=3; failure',
          discoveredAt: DateTime.utc(2026),
        );
        final reads = <String>[];
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            reads.add(p);
            return File(p).readAsBytes();
          },
        );
        final result = await cache.verifyRegistered(
          filing,
          Company(
            id: 1,
            corpCode: e.corpCode,
            name: e.companyName,
            stockCode: '000001',
            fiscalMonth: 12,
          ),
          FsDiv.consolidated,
        );
        expect(result.numeric, isNull);
        expect(result.absence, isNotNull);
        expect(result.absence!.corpCode, e.corpCode);
        expect(result.absence!.sourceReceipt, e.receipt);
        expect(result.absence!.periodStart, DateTime.utc(e.year, 1, 1));
        expect(result.absence!.periodEnd, DateTime.utc(e.year, 12, 31));
        expect(result.absence!.issuerIdentityEvidence!['corpCode'], e.corpCode);
        expect(
          result.absence!.issuerIdentityEvidence!['numericApproval'],
          'false',
        );
        expect(reads, hasLength(4));
        expect(filing.consolidatedStatus, FilingFetchStatus.failed);
      },
    );
  }
}
