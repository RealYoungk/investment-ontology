import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  group('20220315000921 cfs core50', () {
    final e = VerifiedAnnualSourceRegistry.find(
      '20220315000921',
      FsDiv.consolidated,
    )!;
    Future<dynamic> verify(DartFiling f, {bool tamper = false, FsDiv? div}) =>
        VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = File(p).readAsBytesSync();
            return tamper && p.endsWith('cfs.html') ? [...b, 32] : b;
          },
        ).verifyRegistered(f, company(e), div ?? e.basis);
    test('actual whole 8 accounts pinned source', () async {
      final r = await verify(filing(e));
      expect(r.numeric.rows.length, 8);
      expect(
        r.numeric.rows.every((dynamic x) => x['account_id'] == null),
        true,
      );
    });
    for (final bad in ['corp', 'receipt', 'year', 'kind']) {
      test('reject $bad', () async {
        final f = filing(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'receipt':
            f.rceptNo = '20220315000000';
          case 'year':
            f.bsnsYear = 2020;
          case 'kind':
            f.reportCode = FinancialReportCode.halfYear;
        }
        expect(() => verify(f), throwsA(isA<FormatException>()));
      });
    }
    test(
      'SHA mutation rejected',
      () => expect(
        () => verify(filing(e), tamper: true),
        throwsA(isA<FormatException>()),
      ),
    );
    test('existing opposite package is independently source bound', () async {
      final other = VerifiedAnnualSourceRegistry.find(
        e.receipt,
        FsDiv.separate,
      )!;
      expect(other.assetDirectory, isNot(e.assetDirectory));
      final r = await verify(filing(e), div: FsDiv.separate);
      expect(r.numeric.rows.first['html_provenance']['basis'], 'OFS');
      expect(
        r.numeric.statementSource,
        isNot((await verify(filing(e))).numeric.statementSource),
      );
    });
  });
  group('20220315001273 cfs core50', () {
    final e = VerifiedAnnualSourceRegistry.find(
      '20220315001273',
      FsDiv.consolidated,
    )!;
    Future<dynamic> verify(DartFiling f, {bool tamper = false, FsDiv? div}) =>
        VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = File(p).readAsBytesSync();
            return tamper && p.endsWith('cfs.html') ? [...b, 32] : b;
          },
        ).verifyRegistered(f, company(e), div ?? e.basis);
    test('actual whole 8 accounts pinned source', () async {
      final r = await verify(filing(e));
      expect(r.numeric.rows.length, 8);
      expect(
        r.numeric.rows.every((dynamic x) => x['account_id'] == null),
        true,
      );
    });
    for (final bad in ['corp', 'receipt', 'year', 'kind']) {
      test('reject $bad', () async {
        final f = filing(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'receipt':
            f.rceptNo = '20220315000000';
          case 'year':
            f.bsnsYear = 2020;
          case 'kind':
            f.reportCode = FinancialReportCode.halfYear;
        }
        expect(() => verify(f), throwsA(isA<FormatException>()));
      });
    }
    test(
      'SHA mutation rejected',
      () => expect(
        () => verify(filing(e), tamper: true),
        throwsA(isA<FormatException>()),
      ),
    );
    test('existing opposite package is independently source bound', () async {
      final other = VerifiedAnnualSourceRegistry.find(
        e.receipt,
        FsDiv.separate,
      )!;
      expect(other.assetDirectory, isNot(e.assetDirectory));
      final r = await verify(filing(e), div: FsDiv.separate);
      expect(r.numeric.rows.first['html_provenance']['basis'], 'OFS');
      expect(
        r.numeric.statementSource,
        isNot((await verify(filing(e))).numeric.statementSource),
      );
    });
  });
  group('20220331001729 ofs core50', () {
    final e = VerifiedAnnualSourceRegistry.find(
      '20220331001729',
      FsDiv.separate,
    )!;
    Future<dynamic> verify(DartFiling f, {bool tamper = false, FsDiv? div}) =>
        VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = File(p).readAsBytesSync();
            return tamper && p.endsWith('ofs.html') ? [...b, 32] : b;
          },
        ).verifyRegistered(f, company(e), div ?? e.basis);
    test('actual whole 7 accounts pinned source', () async {
      final r = await verify(filing(e));
      expect(r.numeric.rows.length, 7);
      expect(
        r.numeric.rows.every((dynamic x) => x['account_id'] == null),
        true,
      );
    });
    for (final bad in ['corp', 'receipt', 'year', 'kind']) {
      test('reject $bad', () async {
        final f = filing(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'receipt':
            f.rceptNo = '20220315000000';
          case 'year':
            f.bsnsYear = 2020;
          case 'kind':
            f.reportCode = FinancialReportCode.halfYear;
        }
        expect(() => verify(f), throwsA(isA<FormatException>()));
      });
    }
    test(
      'SHA mutation rejected',
      () => expect(
        () => verify(filing(e), tamper: true),
        throwsA(isA<FormatException>()),
      ),
    );
    test(
      'opposite basis rejected',
      () => expect(
        () => verify(filing(e), div: FsDiv.consolidated),
        throwsA(isA<FormatException>()),
      ),
    );
  });
}
