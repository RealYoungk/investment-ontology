import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/mkif_halfyear_five_validator.dart';

void main() {
  testWidgets(
    'own half-year five at320px shows unaudited, missing statements and no TTM',
    (t) async {
      final row = jsonDecode(jsonEncode(MkifHalfYearFiveValidator.expected));
      final payload = {
        'state': 'ready',
        'provider': 'verified-primary-pdf-text-rule',
        'rows': [row],
        'source': {'kind': 'officialFile', 'url': 'https://www.mkif.com'},
      };
      expect(validateIssuerFinancialRows([row]), hasLength(1));
      await t.binding.setSurfaceSize(const Size(320, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: IssuerFinancialsSection(
                  corpCode: '00435297',
                  loader: (_, _) async => jsonEncode(payload),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byWidgetPredicate((widget) => widget is ShadAccordion),
        findsOneWidget,
      );
      expect(find.textContaining('상반기 비감사 별도'), findsOneWidget);
      await t.tap(find.byWidgetPredicate((widget) => widget is ShadAccordion));
      await t.pumpAndSettle();
      expect(find.textContaining('TTM 미포함'), findsOneWidget);
      expect(find.textContaining('현금흐름표 미인쇄'), findsOneWidget);
      expect(find.textContaining('자본변동표 미인쇄'), findsOneWidget);
      expect(find.textContaining('영업이익 항목이 인쇄되지 않음'), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);
      expect(find.text('Net Income'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  for (final key in [
    'auditStatus',
    'includeInTtm',
    'fullStatementCollected',
    'periodEnd',
    'accounts',
  ]) {
    test('reject altered partial half-year $key', () {
      final row = jsonDecode(
        jsonEncode(MkifHalfYearFiveValidator.expected),
      ) as Map<String, dynamic>;
      row[key] = key == 'accounts' ? [] : 'wrong';
      expect(() => validateIssuerFinancialRows([row]), throwsFormatException);
    });
  }
}
