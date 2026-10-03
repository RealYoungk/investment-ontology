import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_conflict_cache.dart';

void main() {
  test('finite negative registry excludes generic six and numeric storage', () {
    expect(KnownAnnualConflictCache.profiles, hasLength(7));
    expect(
      KnownAnnualConflictCache.profiles.map((p) => p['receipt']).toSet(),
      hasLength(5),
    );
  });
  for (final p in KnownAnnualConflictCache.profiles) {
    final div = p['consolidated'] == true ? FsDiv.consolidated : FsDiv.separate;
    final c = Company(
      id: 17,
      corpCode: p['corpCode'] as String,
      name: 'exact fixture',
      stockCode: '123456',
    );
    final f = DartFiling(
      id: 23,
      companyId: 17,
      corpCode: c.corpCode,
      rceptNo: p['receipt'] as String,
      reportName: '사업보고서 (${p['year']}.12)',
      bsnsYear: p['year'] as int,
      reportCode: FinancialReportCode.annual,
      discoveredAt: DateTime.utc(2026),
      attempts: 3,
      consolidatedStatus: FilingFetchStatus.failed,
      separateStatus: FilingFetchStatus.failed,
    );
    test('${p['receipt']} ${div.name} exact pinned conflict canonical evidence', () async {
      final proof = await KnownAnnualConflictCache().verify(f, c, div);
      expect(proof.evidence['consolidated'], div == FsDiv.consolidated);
      expect(proof.evidence['statementSource'], p['statementSource']);
      expect(proof.evidence['statementSha256'], p['statementSha256']);
      expect(proof.evidence['financialFactsStored'], false);
      expect(proof.evidence['noData'], false);
      expect(proof.evidence['collectionComplete'], false);
      expect(proof.evidence['apiCalls'], 0);
      expect(proof.evidence['networkRequests'], 0);
      expect(f.attempts, 3);
      expect(f.consolidatedStatus, FilingFetchStatus.failed);
      final corrupt = KnownAnnualConflictCache(
        readFile: (path) async {
          final bytes = await File(path).readAsBytes();
          return path.endsWith(
                '${f.rceptNo}-${div == FsDiv.consolidated ? 'cfs' : 'ofs'}.html',
              )
              ? [...bytes, 32]
              : bytes;
        },
      );
      await expectLater(corrupt.verify(f, c, div), throwsFormatException);
      final corruptManifest = KnownAnnualConflictCache(
        readFile: (path) async {
          final bytes = await File(path).readAsBytes();
          return path.endsWith('manifest.json') ? [...bytes, 32] : bytes;
        },
      );
      await expectLater(
        corruptManifest.verify(f, c, div),
        throwsFormatException,
      );
    });
    test(
      '${p['receipt']} ${div.name} owner/currentperiod/status/basis reject',
      () {
        for (final changed in [
          f.copyWith(companyId: 18),
          f.copyWith(corpCode: '00000000'),
          f.copyWith(rceptNo: '20260101000000'),
          f.copyWith(bsnsYear: f.bsnsYear! - 1),
          f.copyWith(reportName: '사업보고서 (${f.bsnsYear! - 1}.12)'),
          f.copyWith(reportCode: FinancialReportCode.halfYear),
          f.copyWith(attempts: 2),
          f.copyWith(
            lastError:
                'api-noData-annual-public:attempt=2; ordinary retry eligible',
          ),
          f.copyWith(lastError: 'api-noData-annual-public:unknown'),
          f.copyWith(
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.noData,
          ),
        ]) {
          expect(KnownAnnualConflictCache.profile(changed, c, div), isNull);
        }
        expect(
          KnownAnnualConflictCache.profile(f, c.copyWith(id: 18), div),
          isNull,
        );
      },
    );
  }
}
