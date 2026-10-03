import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20260429001010',
    FsDiv.separate,
  )!;
  test(
    'exact own audit package yields target receipt seven, four reads',
    () async {
      var reads = 0;
      final r = await VerifiedAnnualSourceCache(
        readAsset: (p) async {
          reads++;
          return File(p).readAsBytes();
        },
      ).verifyRegistered(filing(e), company(e), e.basis);
      expect(reads, 4);
      expect(r.absence, isNull);
      expect(r.numeric!.sourceReceipt, e.receipt);
      expect(r.numeric!.correctionReceipt, isNull);
      expect(r.numeric!.rows, hasLength(7));
      expect(
        r.numeric!.rows.last['html_provenance']['sourceRole'],
        'exact-target-own-audit-primary',
      );
    },
  );
  test('SHA failure closed', () async {
    final c = VerifiedAnnualSourceCache(
      readAsset: (p) async {
        final b = await File(p).readAsBytes();
        return p.endsWith('ofs.html') ? [...b, 32] : b;
      },
    );
    expect(
      () => c.verifyRegistered(filing(e), company(e), e.basis),
      throwsFormatException,
    );
  });
  test('CFS missing package is not inferred absence', () {
    expect(
      VerifiedAnnualSourceRegistry.find(e.receipt, FsDiv.consolidated),
      isNull,
    );
  });
  for (final pair in <String, DartFiling>{
    'wrongcorp': filing(e).copyWith(corpCode: '01035942'),
    'wrongyear': filing(e).copyWith(bsnsYear: 2024),
    'quarter': filing(e).copyWith(reportCode: FinancialReportCode.halfYear),
    'stored': filing(e).copyWith(separateStatus: FilingFetchStatus.stored),
    'not exhausted': filing(e)
        .copyWith(lastError: 'api-noData-annual-public:attempt=2;'),
  }.entries) {
    test(
      pair.key,
      () =>
          expect(VerifiedAnnualSourceCache.eligibleFor(pair.value, e), isFalse),
    );
  }
}
