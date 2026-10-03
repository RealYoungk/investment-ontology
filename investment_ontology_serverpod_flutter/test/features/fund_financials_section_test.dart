import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';

void main() {
  final original = jsonDecode(
    File('test/fixtures/fund-current-categories.json').readAsStringSync(),
  ) as Map;
  testWidgets(
    'all six actual fund periods preserve own fiscal scopes and quarantine at320px',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IssuerFinancialsSection(
                  corpCode: '00600013',
                  loader: (_, _) async => jsonEncode(original),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(6));
      expect(find.textContaining('자체 6개월 회계연도'), findsOneWidget);
      expect(find.textContaining('현금 범위 불일치로 격리'), findsNWidgets(2));
      for (var i = 0; i < 6; i++) {
        final tile = find.byType(ExpansionTile).at(i);
        await t.ensureVisible(tile);
        await t.tap(tile);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'period$i');
      }
      expect(find.text('공식 펀드 PDF 보기'), findsNWidgets(6));
      expect(find.textContaining('금액 표시는 격리했습니다'), findsNWidgets(2));
      expect(find.textContaining('(유출)'), findsNWidgets(4));
      expect(
        find.textContaining('원문 PDF'),
        findsNothing,
      ); // Coordinates are tooltip content.
      expect(find.textContaining('산업 매출'), findsNWidgets(6));
    },
  );
  test('fund source, period, industrial mapping, quarantine and sign mutations fail closed', () {
    expect(validateIssuerFinancialRows(original['rows']).length, 6);
    for (final edit in [
      {'corpCode': '00435297'},
      {'basis': 'CFS'},
      {'periodKind': 'halfYear'},
      {'numericState': 'complete'},
      {'sha256': 'fake'},
      {'categorySchema': 'industrial'},
    ]) {
      final rows = jsonDecode(jsonEncode(original['rows'])) as List;
      (rows.first as Map).addAll(edit);
      expect(() => validateIssuerFinancialRows(rows), throwsFormatException);
    }
    final rows = jsonDecode(jsonEncode(original['rows'])) as List;
    rows.last['accounts'][6]['amountInteger'] = '-196438000';
    expect(() => validateIssuerFinancialRows(rows), throwsFormatException);
  });
}
