import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/header18_linked_primary_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final entries =
      (jsonDecode(
        File('assets/financial_source_cache/header18-candidates.json')
            .readAsStringSync(),
      ) as List).map((e) {
        final m = jsonDecode(
          File('${e['directory']}/manifest.json').readAsStringSync(),
        ) as Map;
        return AnnualSourceCacheEntry(
          receipt: e['targetReceipt'] as String,
          corpCode: e['corpCode'] as String,
          companyName: m['companyName'] as String,
          year: e['year'] as int,
          basis: e['basis'] == 'cfs' ? FsDiv.consolidated : FsDiv.separate,
          assetDirectory: e['directory'] as String,
          manifestDigest: e['manifestSha256'] as String,
          ruleVersion: m['ruleVersion'] as String,
          absenceLiteral: m['absenceLiteral'] as String?,
        );
      }).toList();
  test('exact candidate count is numeric13 and absence5', () {
    expect(entries.where((e) => e.absenceLiteral == null), hasLength(13));
    expect(entries.where((e) => e.absenceLiteral != null), hasLength(5));
  });
  final first = entries.first;
  for (final mutation in [
    'corp',
    'receipt',
    'year',
    'body',
    'cover',
    'targetShell',
    'originalShell',
    'audit',
    'manifest',
  ]) {
    test(
      'immutable identity/source $mutation rejects before source storage',
      () async {
        final f = filing(first);
        final changed = switch (mutation) {
          'corp' => f.copyWith(corpCode: '00000000'),
          'receipt' => f.copyWith(rceptNo: '20260101000001'),
          'year' => f.copyWith(bsnsYear: first.year + 1),
          _ => f,
        };
        List<int> bytes = File('${first.assetDirectory}/manifest.json')
            .readAsBytesSync();
        if (mutation == 'manifest') bytes = [...bytes, 32];
        expect(
          Header18LinkedPrimarySource.verify(
            entry: first,
            company: company(first),
            filing: changed,
            rawManifest: bytes,
            read: (path) async {
              final raw = await File(path).readAsBytes();
              final label = mutation == 'body' ? 'primary' : mutation;
              return path.endsWith('/$label.html') ? [...raw, 32] : raw;
            },
          ),
          throwsFormatException,
        );
      },
    );
  }
  for (final e in entries) {
    test(
      'actual ${e.receipt}:${e.basis.name} keeps published original body and period',
      () async {
        final result = await Header18LinkedPrimarySource.verify(
          entry: e,
          company: company(e),
          filing: filing(e),
          rawManifest: File('${e.assetDirectory}/manifest.json')
              .readAsBytesSync(),
          read: (p) => File(p).readAsBytes(),
        );
        if (e.absenceLiteral == null) {
          expect(result.numeric!.rows.length, inInclusiveRange(7, 8));
          final manifest = jsonDecode(
            File('${e.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          expect(
            result.numeric!.sourceReceipt,
            manifest['numericSourceReceipt'],
          );
          expect(
            result.numeric!.coverSource.queryParameters['rcpNo'],
            manifest['originalReceipt'],
          );
          expect(
            result.numeric!.statementSource.queryParameters['rcpNo'],
            manifest['numericSourceReceipt'],
          );
          expect(
            result.numeric!.correctionReceipt,
            result.numeric!.sourceReceipt == e.receipt ? isNull : e.receipt,
          );
          final proof =
              (result.numeric!.rows.first['html_provenance']
                      as Map)['linkedPrimaryEvidence']
                  as Map;
          expect(proof['sourceRole'], manifest['sourceRole']);
          expect(proof['originalCoverReceipt'], manifest['originalReceipt']);
          expect(result.absence, isNull);
        } else {
          expect(
            result.absence!.sourceReceipt,
            Header18LinkedPrimarySource.originalFor(e.receipt, e.basis),
          );
          expect(result.numeric, isNull);
        }
      },
    );
  }
}
