import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final entries = VerifiedAnnualSourceRegistry.entries.where(
    (e) => e.ruleVersion == 'innovex-own-primary-cfs-printed-absence-v1',
  );
  test('three actual own annual consolidated absence packages', () {
    expect(entries.length, 3);
  });
  for (final e in entries) {
    test('${e.receipt} actual original body yields typed absence', () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        FsDiv.consolidated,
      );
      expect(result.numeric, isNull);
      final a = result.absence!;
      expect(a.evidence, '해당사항없음');
      expect(a.corpCode, '01353848');
      expect(a.sourceReceipt, e.receipt);
      expect(a.periodStart, DateTime.utc(e.year));
      expect(a.periodEnd, DateTime.utc(e.year, 12, 31));
      expect(a.statementSource.queryParameters['eleId'], '19');
    });
    for (final mutation in [
      'shell',
      'cover',
      'cfs',
      'corp',
      'year',
      'receipt',
    ]) {
      test('${e.receipt} rejects altered $mutation', () async {
        final f = filing(e);
        if (mutation == 'corp') f.corpCode = '00000000';
        if (mutation == 'year') f.bsnsYear = e.year - 1;
        if (mutation == 'receipt') f.rceptNo = '20200101000000';
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final bytes = await File(path).readAsBytes();
            return path.endsWith('/$mutation.html') ? [...bytes, 32] : bytes;
          },
        );
        await expectLater(
          cache.verifyRegistered(f, company(e), e.basis),
          throwsFormatException,
        );
      });
    }
  }
}
