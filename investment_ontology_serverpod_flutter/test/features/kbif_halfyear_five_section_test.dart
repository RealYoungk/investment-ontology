import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/kbif_halfyear_five_validator.dart';

void main() {
  testWidgets(
    'own half-year five at320px shows unverified audit, missing statements and no TTM',
    (t) async {
      final row = jsonDecode(jsonEncode(KbifHalfYearFiveValidator.expected));
      final payload = {
        'state': 'ready',
        'provider': 'verified-primary-pdf-text-rule',
        'rows': [row],
        'source': {'kind': 'officialFile', 'url': 'https://kbif.co.kr'},
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
                  corpCode: '01880801',
                  loader: (_, _) async => jsonEncode(payload),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(ShadAccordion), findsOneWidget);
      expect(find.textContaining('상반기 감사상태 미확인 단일 펀드'), findsOneWidget);
      await t.tap(find.byType(ShadAccordion));
      await t.pumpAndSettle();
      expect(find.textContaining('TTM 미포함'), findsOneWidget);
      expect(find.textContaining('현금흐름표 미인쇄'), findsOneWidget);
      expect(find.textContaining('자본변동표 미인쇄'), findsOneWidget);
      expect(find.textContaining('영업이익 항목이 인쇄되지 않음'), findsOneWidget);
      expect(find.text('자산총계'), findsOneWidget);
      expect(find.text('회계적 당기순이익'), findsOneWidget);
      expect(find.textContaining('39,930'), findsOneWidget);
      expect(find.textContaining('1백만원 잔차 미해결'), findsOneWidget);
      expect(find.textContaining('괄호는 분기 비교'), findsOneWidget);
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
        jsonEncode(KbifHalfYearFiveValidator.expected),
      ) as Map<String, dynamic>;
      row[key] = key == 'accounts' ? [] : 'wrong';
      expect(() => validateIssuerFinancialRows([row]), throwsFormatException);
    });
  }
}
