import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_financials_feed.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/reviewed_dart_issuer_sources.dart';

void main() {
  final docs = ReviewedDartIssuerSources.documents
      .where(IssuerFinancialsHtml.supports)
      .toList();
  final proof = jsonDecode(
    File('test/fixtures/issuer_documents/dart/brils-direct-current-cells.json')
        .readAsStringSync(),
  ) as List;
  List<int> bytes(Map doc, String kind) {
    final receipt = (doc['metadata'] as Map)['providerReceipt'];
    return File(
      'test/fixtures/issuer_documents/dart/${receipt == '20260403003880' ? 'brils2025' : receipt}-$kind.html',
    ).readAsBytesSync();
  }

  List<Map<String, dynamic>> parse(Map<String, dynamic> doc) =>
      IssuerFinancialsHtml.parse(
        document: doc,
        shellBytes: bytes(doc, 'shell'),
        statementBytes: bytes(doc, 'financial'),
      );
  test(
    'four own sources produce five basis periods and forty direct actual cells',
    () {
      final rows = docs.expand(parse).toList();
      expect(rows.length, 5);
      expect(rows.expand((r) => r['accounts'] as List).length, 40);
      for (final row in IssuerFinancialsFeed.validate(rows)) {
        for (final a in row['accounts'] as List) {
          final expected = proof.singleWhere(
            (p) =>
                p['sourcePeriodEnd'] == row['periodEnd'] &&
                p['basis'] == row['basis'] &&
                p['metric'] == a['metric'],
          );
          expect(a['amountInteger'], expected['decimalIntegerFromPrintedCell']);
          expect(a['printedAmount'], expected['printedAmount']);
        }
        expect(row['numericState'], 'partialCore');
        expect(row['regularReportCode'], isNull);
        expect(row['xbrlAccountId'], isNull);
      }
      final half = rows.where((r) => r['periodKind'] == 'halfYear');
      final cfs = half.singleWhere((r) => r['basis'] == 'CFS'),
          ofs = half.singleWhere((r) => r['basis'] == 'OFS');
      String amount(Map r, String metric) => (r['accounts'] as List)
          .singleWhere((a) => a['metric'] == metric)['amountInteger'];
      expect(amount(cfs, 'operatingProfit'), '841203861');
      expect(amount(ofs, 'operatingProfit'), '986334380');
      expect(
        amount(cfs, 'revenue'),
        '13657091709',
        reason: 'cumulative current half, not 3-month 11121954784',
      );
    },
  );
  for (final doc in docs) {
    test(
      'source binding rejects counterpart bytes and altered URI/issuer/period ${doc['metadata']}',
      () {
        final other = docs.firstWhere((d) => d != doc);
        expect(
          () => IssuerFinancialsHtml.parse(
            document: doc,
            shellBytes: bytes(doc, 'shell'),
            statementBytes: bytes(other, 'financial'),
          ),
          throwsFormatException,
        );
        expect(
          () => IssuerFinancialsHtml.parse(
            document: doc,
            shellBytes: bytes(other, 'shell'),
            statementBytes: bytes(doc, 'financial'),
          ),
          throwsFormatException,
        );
        for (final edit in [
          {'corpCode': '01564514'},
          {'periodStart': '2022-01-01'},
          {'officialUrl': '${(doc['metadata'] as Map)['officialUrl']}&extra=1'},
        ]) {
          final changed = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(doc)),
          );
          changed['metadata'].addAll(edit);
          expect(() => parse(changed), throwsFormatException);
        }
      },
    );
  }
  test('numeric contract rejects same-corp basis, cumulative, source and invented-API mutations', () {
    final original = parse(docs.last).first;
    for (final edit in [
      {'basis': 'OFS'},
      {'periodEnd': '2025-12-31'},
      {'regularReportCode': '11012'},
      {'currency': 'USD'},
      {'precisionUnit': '1000'},
      {'sha256': '0' * 64},
      {'auditStatus': 'audited'},
    ]) {
      expect(
        () => IssuerFinancialsFeed.validate([
          {...original, ...edit},
        ]),
        throwsFormatException,
      );
    }
    for (final edit in [
      {'amountScope': 'threeMonth'},
      {'cashDirection': 'inflow'},
      {'cellOrdinal': 1},
      {'amountInteger': '0'},
      {'accountLabel': '타사 매출'},
    ]) {
      final changed = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(original)),
      );
      (changed['accounts'] as List)[3].addAll(edit);
      expect(
        () => IssuerFinancialsFeed.validate([changed]),
        throwsFormatException,
      );
    }
    final changedLabel = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(original)),
    );
    final changedAccount = (changedLabel['accounts'] as List)[3] as Map;
    changedAccount['accountLabel'] = '타사 매출';
    (changedAccount['rowCells'] as List)[0] = '타사 매출';
    expect(
      () => IssuerFinancialsFeed.validate([changedLabel]),
      throwsFormatException,
    );
    final changedHeader = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(original)),
    );
    ((changedHeader['accounts'] as List)[3]['headerCells'] as List)[1] =
        '2025연도';
    expect(
      () => IssuerFinancialsFeed.validate([changedHeader]),
      throwsFormatException,
    );
    expect(
      () => IssuerFinancialsFeed.validate([original, original]),
      throwsFormatException,
    );
    expect(() => IssuerFinancialsHtml.integer('-'), throwsFormatException);
  });
}
