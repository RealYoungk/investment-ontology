import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final entries = VerifiedAnnualSourceRegistry.entries
      .where((e) => e.ruleVersion == 'own-primary-cfs-explicit-absence-v1')
      .toList();
  test(
    'independently bound seven own nonnumeric sources',
    () => expect(entries.length, 7),
  );
  for (final e in entries) {
    for (final mutation in [
      'corp',
      'receipt',
      'year',
      'halfYear',
      'opposite',
      'shell',
      'cover',
      'cfs',
    ]) {
      test('${e.receipt} own absence preserves guarded $mutation', () async {
        final f = filing(e), c = company(e);
        switch (mutation) {
          case 'corp':
            f.corpCode = '00000000';
          case 'receipt':
            f.rceptNo = '20200101000000';
          case 'year':
            f.bsnsYear = e.year - 1;
          case 'halfYear':
            f.reportCode = FinancialReportCode.halfYear;
        }
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final b = File(path).readAsBytesSync();
            return path.endsWith('$mutation.html') ? [...b, 32] : b;
          },
        );
        final approvedOfs = VerifiedAnnualSourceRegistry.find(
          e.receipt,
          FsDiv.separate,
        );
        if (mutation == 'opposite' && approvedOfs != null) {
          final result = await cache.verifyRegistered(f, c, FsDiv.separate);
          expect(result.absence, isNull);
          expect(result.numeric, isNotNull);
          expect(result.numeric!.sourceReceipt, e.receipt);
          expect(result.numeric!.rows.every((r) => r['fs_div'] == 'OFS'), true);
          expect(result.numeric!.rows.length, inInclusiveRange(7, 8));
        } else {
          expect(
            () => cache.verifyRegistered(
              f,
              c,
              mutation == 'opposite' ? FsDiv.separate : e.basis,
            ),
            throwsA(isA<FormatException>()),
          );
        }
      });
    }
  }
}
