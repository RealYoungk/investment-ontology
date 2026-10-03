import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final receipt in ['20250321001653', '20220331003444']) {
    final e = VerifiedAnnualSourceRegistry.find(
      receipt,
      receipt == '20250321001653' ? FsDiv.consolidated : FsDiv.separate,
    )!;
    test('$receipt independent actual8 and eleven raw cross-checks', () async {
      final result = await VerifiedAnnualSourceCache().verifyRegistered(
        filing(e),
        company(e),
        e.basis,
      );
      expect(result.absence, isNull);
      final proof = jsonDecode(
        File('${e.assetDirectory}/independent-proof.json').readAsStringSync(),
      ) as Map;
      expect((proof['differences'] as Map).length, 11);
      expect((proof['differences'] as Map).values, everyElement(0));
      final expected = jsonDecode(
        File('${e.assetDirectory}/expected-rows.json').readAsStringSync(),
      ) as List;
      final rows = result.numeric!.rows;
      expect(rows.length, 8);
      for (var i = 0; i < 8; i++) {
        expect(rows[i]['account_nm'], expected[i][0]);
        expect(rows[i]['thstrm_amount'], expected[i][1]);
        expect(rows[i]['account_id'], isNull);
        final p = rows[i]['html_provenance'] as Map;
        expect(p['source'], result.numeric!.statementSource.toString());
        expect(p['fullStatementCollected'], false);
        expect(p['allStatementRowsVerified'], false);
        expect(p['uncollectedOptionalAccounts'], isEmpty);
      }
    });
    for (final bad in ['corp', 'year', 'receipt', 'quarter', 'sha', 'issuer']) {
      test('$receipt rejects $bad without laundering', () async {
        final f = filing(e), c = company(e);
        switch (bad) {
          case 'corp':
            f.corpCode = '00000000';
          case 'year':
            f.bsnsYear = e.year - 1;
          case 'receipt':
            f.rceptNo = '20260323000000';
          case 'quarter':
            f.reportCode = FinancialReportCode.halfYear;
          case 'issuer':
            c.name = '다른 회사';
        }
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = File(p).readAsBytesSync();
            return bad == 'sha' && p.endsWith('${e.statementLabel}.html')
                ? [...b, 32]
                : b;
          },
        );
        expect(
          () => cache.verifyRegistered(f, c, e.basis),
          throwsA(isA<FormatException>()),
        );
      });
    }
  }
}
