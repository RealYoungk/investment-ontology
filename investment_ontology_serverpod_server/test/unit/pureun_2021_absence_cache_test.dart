import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20220308000292',
    FsDiv.consolidated,
  )!;
  test(
    'own2021 exact legal actor, annual cover and literal CFS absence',
    () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      expect(result.numeric, isNull);
      expect(result.absence, isNotNull);
      expect(result.absence!.sourceReceipt, e.receipt);
    },
  );
  for (final file in [
    'shell.html',
    'cover.html',
    'overview.html',
    'cfs.html',
    'manifest.json',
  ]) {
    test(
      'own2021 rejects altered $file before absence classification',
      () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final bytes = File(path).readAsBytesSync();
            return path.endsWith('/$file') ? [...bytes, 32] : bytes;
          },
        );
        expect(
          () => cache.verifyRegistered(filing(e), company(e), e.basis),
          throwsA(isA<FormatException>()),
        );
      },
    );
  }
  test('own2021 rejects different fiscal year and actor', () async {
    for (final foreign in [false, true]) {
      final f = filing(e), c = company(e);
      if (foreign) {
        c.corpCode = '00000000';
      } else {
        f.bsnsYear = 2022;
      }
      expect(
        () => VerifiedAnnualSourceCache().verifyRegistered(f, c, e.basis),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
