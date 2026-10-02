import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in [
    '20230314001271',
    '20230309000572',
    '20230323001133',
  ]) {
    final entry = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
    Future<dynamic> verify(
      DartFiling f, {
      bool tamper = false,
      FsDiv basis = FsDiv.separate,
    }) => VerifiedAnnualSourceCache(
      readAsset: (path) async {
        final bytes = File(path).readAsBytesSync();
        return tamper && path.endsWith('ofs.html') ? [...bytes, 32] : bytes;
      },
    ).verifyRegistered(f, company(entry), basis);
    test(
      '$receipt immutable six direct accounts preserve absent revenue',
      () async {
        final f = filing(entry), before = filing(entry).toJson();
        final r = await verify(f);
        expect(r.numeric.rows.length, 6);
        expect(
          r.numeric.rows.every((dynamic row) => row['account_id'] == null),
          isTrue,
        );
        expect(
          r.numeric.rows.every(
            (dynamic row) =>
                row['html_provenance']['partialCoreProof']['missingAccount'] ==
                'revenue',
          ),
          isTrue,
        );
        expect(f.toJson(), before);
      },
    );
    for (final bad in ['corp', 'year', 'quarter', 'receipt']) {
      test('$receipt rejects wrong $bad', () async {
        final f = filing(entry);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = 2021;
          case 'quarter':
            f.reportCode = FinancialReportCode.halfYear;
          case 'receipt':
            f.rceptNo = '20230314001272';
        }
        expect(() => verify(f), throwsA(isA<FormatException>()));
      });
    }
    test(
      '$receipt immutable source SHA rejects tamper',
      () => expect(
        () => verify(filing(entry), tamper: true),
        throwsA(isA<FormatException>()),
      ),
    );
    test(
      '$receipt never reuses OFS for CFS',
      () => expect(
        () => verify(filing(entry), basis: FsDiv.consolidated),
        throwsA(isA<FormatException>()),
      ),
    );
  }
}
