import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/kbif_halfyear_five.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';

void main() {
  final m = KbifHalfYearFive.profile['metadata'] as Map<String, dynamic>;
  final doc = <String, dynamic>{'metadata': m, 'proof': <String, dynamic>{}};
  final fixture = Directory('test/fixtures/issuer_documents/kbif_halfyear');
  test(
    'normal issuer rows extract own current5 from exact PDF and complete text',
    () async {
      final rows = await IssuerFinancialsSync.rows(fixture, [doc]);
      expect(rows, hasLength(1));
      expect(rows.single['auditStatus'], 'notExtracted');
      expect(rows.single['includeInTtm'], false);
      expect(rows.single['regularReportCode'], isNull);
      expect(rows.single['fullStatementCollected'], false);
      final a = rows.single['accounts'] as List;
      expect(a, hasLength(5));
      expect(a.map((v) => v['amountInteger']), [
        '1008537000000',
        '167166000000',
        '841371000000',
        '34397000000',
        '26771000000',
      ]);
      expect(
        a.every(
          (v) => v['precisionUnit'] == '1000000',
        ),
        true,
      );
      expect(
        (rows.single['unextractedMetrics'] as List).map((v) => v['metric']),
        containsAll([
          'operatingProfit',
          'assetManagementCashFlow',
          'equityChanges',
        ]),
      );
      expect(IssuerFinancialsFeed.validate(rows), rows);
    },
  );
  test('compiled source profile exactly equals package manifest and tax/Q2 excluded', () {
    final package = jsonDecode(
      File('assets/issuer_documents/kbif_halfyear_five_profile.json')
          .readAsStringSync(),
    );
    expect(KbifHalfYearFive.profile, package);
    final row = package['expected'] as Map;
    expect(row['basis'], 'ownFund');
    expect(row['auditStatus'], 'notExtracted');
    expect((row['accounts'] as List).map((v) => v['pageOrdinal']), [
      13,
      13,
      13,
      15,
      15,
    ]);
    expect((row['accounts'] as List).map((v) => v['currentTokenIndex']), [
      0,
      2,
      2,
      0,
      0,
    ]);
    expect((row['sourceDiscrepancies'] as List).last['residualMillion'], '1');
    expect(
      (row['excludedComparatives'] as List).last['printedAmount'],
      '39,930',
    );
    expect(row['validation']['detailHierarchyComplete'], false);
  });
  for (final k in [
    'periodStart',
    'periodEnd',
    'corpCode',
    'sha256',
    'documentType',
  ]) {
    test('reject altered source metadata $k', () {
      final changed = {...m, k: 'wrong'};
      expect(KbifHalfYearFive.supports({'metadata': changed}), false);
      expect(
        () => KbifHalfYearFive.parseRaw(
          changed,
          File('${fixture.path}/${m['sha256']}.halfyear-results.txt')
              .readAsBytesSync(),
        ),
        throwsFormatException,
      );
    });
  }
  for (final type in ['pdf', 'halfyear-results.txt']) {
    test('reject altered original $type', () {
      final bytes = [
        ...File('${fixture.path}/${m['sha256']}.$type').readAsBytesSync(),
        32,
      ];
      expect(
        () => type == 'pdf'
            ? KbifHalfYearFive.verifyPdf(m, bytes)
            : KbifHalfYearFive.parseRaw(m, bytes),
        throwsFormatException,
      );
    });
  }
  for (final k in [
    'accounts',
    'auditStatus',
    'includeInTtm',
    'periodKind',
    'fullStatementCollected',
  ]) {
    test('feed refuses altered stored contract $k', () {
      final row = jsonDecode(
        jsonEncode(KbifHalfYearFive.profile['expected']),
      ) as Map<String, dynamic>;
      row[k] = k == 'accounts' ? [] : 'wrong';
      expect(() => IssuerFinancialsFeed.validate([row]), throwsFormatException);
    });
  }
}
