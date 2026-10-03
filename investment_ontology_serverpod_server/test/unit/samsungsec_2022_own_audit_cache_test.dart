import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    '20230309000572',
    FsDiv.consolidated,
  )!;
  test(
    'normal cache adapter verifies five exact own documents and current eight',
    () async {
      var reads = 0;
      final result = await VerifiedAnnualSourceCache(
        readAsset: (p) async {
          reads++;
          return File(p).readAsBytes();
        },
      ).verifyRegistered(filing(e), company(e), e.basis);
      expect(reads, 6);
      expect(result.absence, isNull);
      expect(result.numeric!.rows, hasLength(8));
      expect(result.numeric!.rows[3]['account_nm'], '영업수익');
      expect(
        result.numeric!.rows[3]['html_provenance']['printedPhysicalLabel'],
        '소계',
      );
      expect(
        result.numeric!.rows[3]['html_provenance']['precisionUnit'],
        '1000',
      );
      expect(result.numeric!.rows[4]['html_provenance']['precisionUnit'], '1');
    },
  );
  for (final filename in [
    'audit-shell.html',
    'audit-primary.html',
    'main-cfs.html',
  ]) {
    test('normal adapter rejects altered $filename bytes', () async {
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final bytes = await File(p).readAsBytes();
          return p.endsWith('/$filename') ? [...bytes, 32] : bytes;
        },
      );
      await expectLater(
        cache.verifyRegistered(filing(e), company(e), e.basis),
        throwsFormatException,
      );
    });
  }
  for (final mutation in ['unknown-filename', 'unknown-label']) {
    test('normal adapter rejects manifest $mutation', () async {
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final bytes = await File(p).readAsBytes();
          if (!p.endsWith('manifest.json')) return bytes;
          final raw = String.fromCharCodes(bytes);
          return (mutation == 'unknown-filename'
                  ? raw.replaceFirst('audit-primary.html', 'unknown.html')
                  : raw.replaceFirst('auditShell', 'unknownLabel'))
              .codeUnits;
        },
      );
      await expectLater(
        cache.verifyRegistered(filing(e), company(e), e.basis),
        throwsFormatException,
      );
    });
  }
}
