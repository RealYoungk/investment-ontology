import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

void main() {
  for (final r in ['20220322000542', '20220429000083']) {
    test('$r immutable own annual OFS and guards', () async {
      final e = VerifiedAnnualSourceRegistry.entries.singleWhere(
        (x) => x.receipt == r && x.basis == FsDiv.separate,
      );
      final f = DartFiling(
        id: 1,
        companyId: 1,
        corpCode: e.corpCode,
        rceptNo: r,
        bsnsYear: 2021,
        reportCode: FinancialReportCode.annual,
        reportName: '사업보고서 (2021.12)',
        consolidatedStatus: FilingFetchStatus.failed,
        separateStatus: FilingFetchStatus.failed,
        attempts: 3,
        lastError: 'api-noData-annual-public:attempt=3; source failed',
        discoveredAt: DateTime.utc(2026),
      );
      final c = Company(
        id: 1,
        corpCode: e.corpCode,
        name: e.companyName,
        stockCode: '000001',
        fiscalMonth: 12,
      );
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async => File(p).readAsBytes(),
      );
      final result = await cache.verifyRegistered(f, c, FsDiv.separate);
      expect(result.numeric!.rows.length, inInclusiveRange(7, 8));
      expect(result.numeric!.sourceReceipt, r);
      expect(VerifiedAnnualSourceCache.eligibleFor(f, e), isTrue);
      for (final bad in [
        f.copyWith(corpCode: '00000000'),
        f.copyWith(bsnsYear: 2022),
        f.copyWith(reportName: '사업보고서 (2021.06)'),
        f.copyWith(reportCode: FinancialReportCode.halfYear),
        f.copyWith(
          lastError: 'api-noData-annual-public:attempt=4; source failed',
        ),
      ]) {
        expect(VerifiedAnnualSourceCache.eligibleFor(bad, e), isFalse);
      }
      expect(VerifiedAnnualSourceRegistry.find(r, FsDiv.consolidated), isNull);
    });
  }
}
