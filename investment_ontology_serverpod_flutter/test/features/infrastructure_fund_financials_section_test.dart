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
    File('test/fixtures/infrastructure-fund-current-categories.json')
        .readAsStringSync(),
  ) as Map;
  for (final corp in ['00435297', '01880801']) {
    testWidgets('all exact $corp fund periods at320px', (t) async {
      final payload = Map<String, dynamic>.from(original);
      payload['rows'] = (original['rows'] as List)
          .where((r) => r['corpCode'] == corp)
          .toList();
      payload['source'] = {
        'kind': 'officialFile',
        'url': corp == '00435297'
            ? 'https://www.mkif.com'
            : 'https://kbif.co.kr',
      };
      final n = (payload['rows'] as List).length;
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
                    corpCode: corp,
                    loader: (_, _) async => jsonEncode(payload),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(ShadAccordion), findsNWidgets(n));
      for (var i = 0; i < n; i++) {
        final tile = find.byType(ShadAccordion).at(i);
        await t.ensureVisible(tile);
        await t.tap(tile);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      expect(find.text('공식 펀드 PDF 보기'), findsNWidgets(n));
      expect(find.textContaining('주석과 전체 글꼴은 검증하지 않았습니다'), findsNWidgets(n));
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && (w.data ?? '').endsWith(' (유출)'),
        ),
        findsNWidgets(n * 2),
      );
    });
  }
  test('fund source, period, industrial mapping, quarantine and sign mutations fail closed', () {
    final baseline = (original['rows'] as List)
        .where((r) => r['corpCode'] == '00435297')
        .toList();
    expect(validateIssuerFinancialRows(baseline).length, 3);
    for (final edit in [
      {'corpCode': '00600013'},
      {'basis': 'CFS'},
      {'periodKind': 'halfYear'},
      {'numericState': 'complete'},
      {'sha256': 'fake'},
      {'categorySchema': 'industrial'},
    ]) {
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
    final rows = jsonDecode(jsonEncode(baseline)) as List;
    rows.last['accounts'][6]['amountInteger'] = '-1';
    expect(() => validateIssuerFinancialRows(rows), throwsFormatException);
  });
}
