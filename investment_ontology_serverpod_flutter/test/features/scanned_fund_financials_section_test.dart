import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';

void main() {
  final original = jsonDecode(
    File('test/fixtures/scanned-fund-current-categories.json')
        .readAsStringSync(),
  ) as Map;
  testWidgets('all five own MKIF annuals retain dual OCR scopes at320px', (
    t,
  ) async {
    final other = jsonDecode(
      File('test/fixtures/infrastructure-fund-current-categories.json')
          .readAsStringSync(),
    ) as Map;
    final payload = Map<String, dynamic>.from(original);
    payload['rows'] = [
      ...original['rows'],
      ...(other['rows'] as List).where((r) => r['corpCode'] == '00435297'),
    ];
    await t.binding.setSurfaceSize(const Size(320, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IssuerFinancialsSection(
                  corpCode: '00435297',
                  loader: (_, _) async => jsonEncode(payload),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) => widget is ShadAccordion),
      findsNWidgets(5),
    );
    for (var i = 0; i < 5; i++) {
      final tile = find
          .byWidgetPredicate((widget) => widget is ShadAccordion)
          .at(i);
      await t.ensureVisible(tile);
      await t.tap(tile);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    expect(find.text('공식 펀드 PDF 보기'), findsNWidgets(5));
    expect(find.textContaining('두 OCR의 숫자·부호'), findsNWidgets(2));
    expect(find.textContaining('주석과 전체 글꼴'), findsNWidgets(3));
    expect(
      find.byWidgetPredicate(
        (w) => w is SelectableText && (w.data ?? '').endsWith(' (유출)'),
      ),
      findsNWidgets(10),
    );
  });
  test('fund source, period, industrial mapping, quarantine and sign mutations fail closed', () {
    final baseline = (original['rows'] as List)
        .where((r) => r['corpCode'] == '00435297')
        .toList();
    expect(validateIssuerFinancialRows(baseline).length, 2);
    for (final edit in [
      {'corpCode': '00600013'},
      {'basis': 'CFS'},
      {'periodKind': 'halfYear'},
      {'numericState': 'complete'},
      {'sha256': 'fake'},
      {'categorySchema': 'industrial'},
    ]) {
      final mismatch = jsonDecode(jsonEncode(baseline)) as List;
      mismatch.first['accounts'][0]['independentOcrText'] = '53.50g,690,772';
      expect(
        () => validateIssuerFinancialRows(mismatch),
        throwsFormatException,
      );
      final rows = jsonDecode(jsonEncode(baseline)) as List;
      (rows.first as Map).addAll(edit);
      expect(() => validateIssuerFinancialRows(rows), throwsFormatException);
    }
    final coordinates = jsonDecode(jsonEncode(baseline)) as List;
    coordinates.first['accounts'][0]['pageOrdinal'] = 1;
    expect(
      () => validateIssuerFinancialRows(coordinates),
      throwsFormatException,
    );
    final mismatch = jsonDecode(jsonEncode(baseline)) as List;
    mismatch.first['accounts'][0]['independentOcrText'] = '53.50g,690,772';
    expect(() => validateIssuerFinancialRows(mismatch), throwsFormatException);
    final rows = jsonDecode(jsonEncode(baseline)) as List;
    rows.last['accounts'][6]['amountInteger'] = '-1';
    expect(() => validateIssuerFinancialRows(rows), throwsFormatException);
  });
}
