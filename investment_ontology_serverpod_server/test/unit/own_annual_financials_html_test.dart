import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/own_annual_financials_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/own_annual_financials_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/reviewed_dart_issuer_sources.dart';

void main() {
  final docs = ReviewedDartIssuerSources.documents
      .where(OwnAnnualFinancialsHtml.supports)
      .toList();
  final proof = jsonDecode(
    File(
      'test/fixtures/issuer_documents/dart/own-annual-direct-current-cells.json',
    ).readAsStringSync(),
  ) as List;
  List<int> bytes(Map d, String part) => File(
    'test/fixtures/issuer_documents/dart/${d['metadata']['providerReceipt']}-own-$part.html',
  ).readAsBytesSync();
  List<Map<String, dynamic>> parse(Map<String, dynamic> d) =>
      OwnAnnualFinancialsHtml.parse(
        document: d,
        shellBytes: bytes(d, 'shell'),
        statementBytes: bytes(d, 'statement'),
      );
  test(
    '20 own annual sources and 156 directly printed current cells balance',
    () {
      expect(docs, hasLength(20));
      var count = 0;
      final all = <Map<String, dynamic>>[];
      for (final d in docs) {
        final rows = parse(d);
        expect(rows, hasLength(1));
        final row = rows.single;
        all.add(row);
        final own = proof
            .where((p) => p['providerReceipt'] == row['providerReceipt'])
            .toList();
        expect(row['accounts'], hasLength(own.length));
        for (final a in row['accounts']) {
          final expected = own.singleWhere((p) => p['metric'] == a['metric']);
          for (final k in [
            'accountLabel',
            'printedAmount',
            'amountInteger',
            'tableOrdinal',
            'rowOrdinal',
            'cellOrdinal',
            'headerCells',
            'rowCells',
            'printedSignConvention',
          ]) {
            expect(
              a[k],
              expected[k],
              reason: '${row['providerReceipt']} $k ${a['metric']}',
            );
          }
          count++;
        }
        expect(row['accountingStandard'], own.first['accountingStandard']);
        expect(row['observationRole'], 'currentOwn');
        expect(row['periodKind'], 'ownAnnual');
        expect(row['regularReportCode'], isNull);
        expect(row['xbrlAccountId'], isNull);
      }
      expect(count, 156);
      for (final corp in all.map((r) => r['corpCode']).toSet()) {
        OwnAnnualFinancialsHtml.validateRows(
          all.where((r) => r['corpCode'] == corp).toList(),
        );
      }
    },
  );
  for (final d in docs) {
    final receipt = d['metadata']['providerReceipt'];
    test(
      '$receipt rejects swapped actor/source and changed standard/current proof',
      () {
        final other = docs.firstWhere(
          (x) => x['metadata']['corpCode'] != d['metadata']['corpCode'],
        );
        expect(
          () => OwnAnnualFinancialsHtml.parse(
            document: d,
            shellBytes: bytes(other, 'shell'),
            statementBytes: bytes(d, 'statement'),
          ),
          throwsFormatException,
        );
        expect(
          () => OwnAnnualFinancialsHtml.parse(
            document: d,
            shellBytes: bytes(d, 'shell'),
            statementBytes: bytes(other, 'statement'),
          ),
          throwsFormatException,
        );
        for (final change in [
          {'accountingStandard': 'inferred'},
          {'auditOpinionSha256': '0' * 64},
          {'periodEnd': '2026-12-31'},
          {'observationRole': 'priorComparative'},
        ]) {
          final rows = parse(d);
          rows.single.addAll(change);
          expect(
            () => OwnAnnualFinancialsHtml.validateRows(rows),
            throwsFormatException,
          );
        }
        final rows = parse(d);
        rows.single['accounts'][0]['cellOrdinal'] = 99;
        expect(
          () => OwnAnnualFinancialsHtml.validateRows(rows),
          throwsFormatException,
        );
      },
    );
  }
  test('positive printed outflow magnitude remains positive, component capex not synthesized', () {
    for (final receipt in ['20230404002934', '20220404002339']) {
      final row = parse(
        docs.singleWhere((d) => d['metadata']['providerReceipt'] == receipt),
      ).single;
      final a = (row['accounts'] as List).singleWhere(
        (a) => a['metric'] == 'propertyPlantEquipmentAcquisitions',
      );
      expect(BigInt.parse(a['amountInteger']).isNegative, isFalse);
      expect(a['cashDirection'], 'outflow');
      expect(row['cashDirectionProof'][0]['printedText'], '2. 투자활동으로 인한 현금유출액');
      final bad = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
      bad['cashDirectionProof'][0]['printedText'] = '투자활동 현금유입액';
      expect(
        () => OwnAnnualFinancialsHtml.validateRows([bad]),
        throwsFormatException,
      );
      expect(a['printedSignConvention'], 'positiveOutflowMagnitude');
    }
    for (final p in OwnAnnualFinancialsProfiles.rows.where(
      (p) => p['accountingStandard'] == 'Korean-GAAP',
    )) {
      expect(p['accounts'], hasLength(7));
      expect(
        p['unextractedMetrics'][0]['metric'],
        'propertyPlantEquipmentAcquisitions',
      );
    }
  });
}
