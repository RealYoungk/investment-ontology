import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/mkif_halfyear_five.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_financials_sync.dart';

void main() {
  final m = MkifHalfYearFive.profile['metadata'] as Map<String, dynamic>;
  final doc = <String, dynamic>{'metadata': m, 'proof': <String, dynamic>{}};
  final fixture = Directory('test/fixtures/issuer_documents/mkif_halfyear');
  test(
    'normal issuer rows extract own current5 from exact PDF and complete text',
    () async {
      final rows = await IssuerFinancialsSync.rows(fixture, [doc]);
      expect(rows, hasLength(1));
      expect(rows.single['auditStatus'], 'unaudited');
      expect(rows.single['includeInTtm'], false);
      expect(rows.single['regularReportCode'], isNull);
      expect(rows.single['fullStatementCollected'], false);
      final a = rows.single['accounts'] as List;
      expect(a, hasLength(5));
      expect(a.map((v) => v['amountInteger']), [
        '5525392000000',
        '475949000000',
        '5049443000000',
        '260021000000',
        '225050000000',
      ]);
      expect(
        a.every(
          (v) => v['currentTokenIndex'] == 0 && v['precisionUnit'] == '1000000',
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
  for (final k in [
    'periodStart',
    'periodEnd',
    'corpCode',
    'sha256',
    'documentType',
  ]) {
    test('reject altered source metadata $k', () {
      final changed = {...m, k: 'wrong'};
      expect(MkifHalfYearFive.supports({'metadata': changed}), false);
      expect(
        () => MkifHalfYearFive.parseRaw(
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
            ? MkifHalfYearFive.verifyPdf(m, bytes)
            : MkifHalfYearFive.parseRaw(m, bytes),
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
        jsonEncode(MkifHalfYearFive.profile['expected']),
      ) as Map<String, dynamic>;
      row[k] = k == 'accounts' ? [] : 'wrong';
      expect(() => IssuerFinancialsFeed.validate([row]), throwsFormatException);
    });
  }
}
