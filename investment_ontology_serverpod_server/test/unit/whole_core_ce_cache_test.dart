import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in [
    '20220315000921',
    '20220315001266',
    '20220315001273',
    '20230317000614',
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
      '$receipt immutable seven direct accounts retain independent CE',
      () async {
        final f = filing(entry), before = filing(entry).toJson();
        final r = await verify(f);
        expect(r.numeric.rows.length, receipt == '20220315001266' ? 7 : 8);
        expect(
          r.numeric.rows.every((dynamic row) => row['account_id'] == null),
          isTrue,
        );
        expect(
          r.numeric.rows.every(
            (dynamic row) =>
                row['html_provenance']['wholeCoreProof']['rule'] ==
                'whole-core-independent-ce-v1',
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
            f.bsnsYear = entry.year - 1;
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
    test('$receipt never reuses OFS for CFS', () async {
      final cfs = VerifiedAnnualSourceRegistry.find(
        receipt,
        FsDiv.consolidated,
      );
      if (cfs == null) {
        expect(
          () => verify(filing(entry), basis: FsDiv.consolidated),
          throwsA(isA<FormatException>()),
        );
        return;
      }
      final paths = <String>[];
      final result = await VerifiedAnnualSourceCache(
        readAsset: (path) async {
          paths.add(path);
          return File(path).readAsBytesSync();
        },
      ).verifyRegistered(filing(entry), company(entry), FsDiv.consolidated);
      expect(
        paths.every((path) => path.startsWith('${cfs.assetDirectory}/')),
        true,
      );
      expect(
        result.numeric!.rows.every(
          (row) => row['html_provenance']['basis'] == 'CFS',
        ),
        true,
      );
      expect(
        result.numeric!.statementSource,
        isNot((await verify(filing(entry))).numeric.statementSource),
      );
      expect(
        () => VerifiedAnnualSourceCache(
          readAsset: (path) async => path.endsWith('cfs.html')
              ? File('${entry.assetDirectory}/ofs.html').readAsBytesSync()
              : File(path).readAsBytesSync(),
        ).verifyRegistered(filing(entry), company(entry), FsDiv.consolidated),
        throwsA(isA<FormatException>()),
      );
    });
  }
}
