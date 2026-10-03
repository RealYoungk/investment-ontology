import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/ipo_issuer_financials_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/reviewed_dart_issuer_sources.dart';

void main() {
  final docs = ReviewedDartIssuerSources.documents
      .where(IpoIssuerFinancialsHtml.supports)
      .toList();
  List<int> bytes(Map d, String part) => File(
    'test/fixtures/issuer_documents/dart/${(d['metadata'] as Map)['providerReceipt']}-$part.html',
  ).readAsBytesSync();
  List<Map<String, dynamic>> parse(Map<String, dynamic> d) =>
      IpoIssuerFinancialsHtml.parse(
        document: d,
        shellBytes: bytes(d, 'shell'),
        statementBytes: bytes(d, 'financial'),
      );
  final proof = jsonDecode(
    File(
      'test/fixtures/issuer_documents/dart/ipo-eight-direct-current-cells.json',
    ).readAsStringSync(),
  ) as List;
  test('eight own IPO chapters produce 11 current basis groups and 82 actual detailed cells', () {
    expect(docs.length, 8);
    final rows = docs.expand(parse).toList();
    expect(rows.length, 11);
    expect(rows.expand((r) => r['accounts'] as List).length, 82);
    for (final row in rows) {
      for (final a in row['accounts'] as List) {
        final p = proof.singleWhere(
          (p) =>
              p['corpCode'] == row['corpCode'] &&
              p['basis'] == row['basis'] &&
              p['metric'] == a['metric'],
        );
        for (final key in [
          'printedAmount',
          'amountInteger',
          'accountLabel',
          'tableOrdinal',
          'rowOrdinal',
          'cellOrdinal',
          'rowCells',
          'incomeDirection',
        ]) {
          expect(
            a[key],
            p[key],
            reason: '${row['corpCode']}/${row['basis']}/${a['metric']}/$key',
          );
        }
      }
    }
    final big = rows.firstWhere(
      (r) => r['corpCode'] == '01722066' && r['basis'] == 'CFS',
    );
    expect(
      (big['accounts'] as List).first['amountInteger'],
      '16871596746',
    ); // Detailed won, not rounded summary thousand-won.
    final korean = rows.singleWhere((r) => r['corpCode'] == '02029258');
    expect(korean['periodKind'], 'sinceIncorporation');
    expect(korean['periodStart'], '2026-05-08');
    expect(korean['auditStatus'], 'notStated');
    final loss = (korean['accounts'] as List).singleWhere(
      (a) => a['metric'] == 'operatingProfit',
    );
    expect(loss['printedAmount'], '10,124,400');
    expect(loss['amountInteger'], '10124400');
    expect(loss['incomeDirection'], 'lossMagnitude');
    expect(
      (korean['unextractedMetrics'] as List).map((r) => r['metric']).toSet(),
      {'revenue', 'propertyPlantEquipmentAcquisitions'},
    );
    for (final code in ['02029258', '02030166', '02032155']) {
      final row = rows.singleWhere((r) => r['corpCode'] == code);
      expect((row['accounts'] as List).length, 6);
      expect(
        (row['accounts'] as List).any((a) => a['metric'] == 'revenue'),
        isFalse,
      );
    }
  });
  for (var i = 0; i < docs.length; i++) {
    final d = docs[i], code = (d['metadata'] as Map)['corpCode'];
    test(
      '$code rejects counterpart source body/shell and numeric metadata/period/direction mutations',
      () {
        final other = docs[(i + 1) % docs.length];
        expect(
          () => IpoIssuerFinancialsHtml.parse(
            document: d,
            shellBytes: bytes(d, 'shell'),
            statementBytes: bytes(other, 'financial'),
          ),
          throwsFormatException,
        );
        expect(
          () => IpoIssuerFinancialsHtml.parse(
            document: d,
            shellBytes: bytes(other, 'shell'),
            statementBytes: bytes(d, 'financial'),
          ),
          throwsFormatException,
        );
        final rows = parse(d);
        for (final edit in [
          {'corpCode': '01801026'},
          {'periodStart': '2026-01-02'},
          {'currency': 'USD'},
          {'regularReportCode': '11012'},
          {'numericState': 'complete'},
          {'auditStatus': 'inferred'},
        ]) {
          final changed = jsonDecode(jsonEncode(rows)) as List;
          (changed.first as Map).addAll(edit);
          expect(
            () => IssuerFinancialsFeed.validate(changed),
            throwsFormatException,
          );
        }
        final changedDirection = jsonDecode(jsonEncode(rows)) as List;
        (changedDirection.first['accounts'] as List)[4]['incomeDirection'] =
            'inferredProfit';
        expect(
          () => IssuerFinancialsFeed.validate(changedDirection),
          throwsFormatException,
        );
        final changedScope = jsonDecode(jsonEncode(rows)) as List;
        (changedScope.first['accounts'] as List)[4]['amountScope'] =
            'threeMonth';
        expect(
          () => IssuerFinancialsFeed.validate(changedScope),
          throwsFormatException,
        );
        final changed = jsonDecode(jsonEncode(rows)) as List;
        (changed.first['accounts'] as List).first['cellOrdinal'] = 0;
        expect(
          () => IssuerFinancialsFeed.validate(changed),
          throwsFormatException,
        );
        expect(
          () => IssuerFinancialsFeed.validate([rows.first, rows.first]),
          throwsFormatException,
        );
      },
    );
  }
}
