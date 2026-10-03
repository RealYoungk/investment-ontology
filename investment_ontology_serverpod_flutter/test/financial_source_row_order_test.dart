import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_report_page.dart';

void main() {
  Source source(String title) => Source(
    id: 7,
    kind: SourceKind.dartReport,
    title: title,
    retrievedAt: DateTime.utc(2026),
  );
  test(
    'original core presentation order follows actual enrichment coordinates',
    () {
      final s = source(
        'DART 원문 HTML 당기 추가행 · ${jsonEncode({
          'originalCoreCoordinates': [
            {
              'factId': 11,
              'tableIndex': 3,
              'rowIndex': 15,
              'columns': [2],
            },
            {
              'factId': 12,
              'tableIndex': 7,
              'rowIndex': 1,
              'columns': [2],
            },
          ],
        })}',
      );
      expect(financialSourceRowOrder([s]), {11: 301502, 12: 700102});
      expect(s.id, 7);
    },
  );
  test('legacy and malformed source records retain default order', () {
    expect(
      financialSourceRowOrder([
        source('DART 원문 HTML 부분 핵심계정'),
        source('DART 원문 HTML 당기 추가행 · invalid'),
        source('DART 원문 HTML 당기 추가행 · {"originalCoreCoordinates":[{}]}'),
      ]),
      isEmpty,
    );
  });
}
