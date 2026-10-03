import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/koreainvestment_own_eight_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in ['20250320000814', '20250320000804']) {
    final e = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.consolidated)!;
    final profile = KoreaInvestmentOwnEightSource.profiles[receipt] as Map;
    test('$receipt actual normal cache current8 own four sources', () async {
      var reads = 0;
      final result = await VerifiedAnnualSourceCache(
        readAsset: (p) async {
          reads++;
          return File(p).readAsBytes();
        },
      ).verifyRegistered(filing(e), company(e), e.basis);
      expect(reads, 5);
      expect(result.absence, isNull);
      final rows = result.numeric!.rows;
      expect(rows, hasLength(8));
      expect(
        rows.map((r) => r['thstrm_amount']),
        (profile['core'] as List).map((c) => c['value']),
      );
      for (final r in rows) {
        final p = r['html_provenance'] as Map;
        expect(p['printedUnit'], '원');
        expect(p['fullStatementCollected'], false);
        expect(p['notesVerified'], false);
        expect(p['literalFlowMonth'], '012');
        expect(p['crossPrecisionEqualityClaim'], false);
      }
    });
    for (final file in [
      'shell.html',
      'cover.html',
      'cfs.html',
      'notes.html',
      'manifest.json',
    ]) {
      test('$receipt normal adapter refuses changed $file bytes', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = await File(p).readAsBytes();
            return p.endsWith('/$file') ? [...b, 32] : b;
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(e), company(e), e.basis),
          throwsFormatException,
        );
      });
    }
    test('$receipt helper rejects opposite, wrong issuer and wrong period', () {
      final manifest = jsonDecode(
        File('${e.assetDirectory}/manifest.json').readAsStringSync(),
      );
      final raw = <String, String>{
        for (final s in manifest['sources'])
          s['label'] as String: File('${e.assetDirectory}/${s['file']}')
              .readAsStringSync(),
      };
      final uris = <String, Uri>{
        for (final s in manifest['sources'])
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      for (final mismatch in ['basis', 'corp', 'year', 'receipt']) {
        expect(
          () => KoreaInvestmentOwnEightSource.parse(
            raw: raw,
            uris: uris,
            receipt: mismatch == 'receipt' ? '20250320000000' : receipt,
            corp: mismatch == 'corp' ? '00104856' : e.corpCode,
            start: DateTime.utc(mismatch == 'year' ? 2020 : e.year),
            end: DateTime.utc(e.year, 12, 31),
            consolidated: mismatch != 'basis',
          ),
          throwsFormatException,
        );
      }
    });
  }
}
