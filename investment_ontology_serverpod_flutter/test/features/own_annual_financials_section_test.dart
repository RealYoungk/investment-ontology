import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';

void main() {
  final rows = jsonDecode(
    File('test/fixtures/own-annual-current-core.json').readAsStringSync(),
  ) as List;
  String payload(String corp) => jsonEncode({
    'state': 'ready',
    'provider': 'verified-own-annual-html-rule',
    'source': {
      'kind': 'officialFile',
      'url': 'https://dart.fss.or.kr',
      'reference':
          'source-bound-own-annual-core;no-api-report-or-xbrl-assertion',
    },
    'rows': rows.where((r) => r['corpCode'] == corp).toList(),
  });
  Future<void> pump(WidgetTester t, String corp, String data) async {
    await t.binding.setSurfaceSize(const Size(320, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: IssuerFinancialsSection(
              key: ValueKey(data),
              corpCode: corp,
              ownAnnual: true,
              loader: (c, k) async {
                expect(c, corp);
                expect(k, 'issuerAnnualFinancials');
                return data;
              },
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  test('twenty source-period rows and GAAP/IFRS/opinion pins fail closed', () {
    expect(rows, hasLength(20));
    for (final corp in rows.map((r) => r['corpCode']).toSet()) {
      final own = rows.where((r) => r['corpCode'] == corp).toList();
      expect(
        validateIssuerFinancialRows(own, ownAnnual: true),
        hasLength(own.length),
      );
      for (final key in [
        'sha256',
        'accountingStandard',
        'auditOpinionUrl',
        'auditOpinionSha256',
      ]) {
        final bad = jsonDecode(jsonEncode(own)) as List;
        bad[0][key] = 'unverified';
        expect(
          () => validateIssuerFinancialRows(bad, ownAnnual: true),
          throwsFormatException,
        );
      }
    }
  });
  testWidgets(
    'all five companies render own source annual coverage and accounting basis at 320px',
    (t) async {
      for (final corp in rows.map((r) => r['corpCode']).toSet()) {
        await pump(t, corp, payload(corp));
        expect(find.text('자체 연간 감사 원문 · 핵심 재무'), findsOneWidget);
        expect(find.textContaining('2021:'), findsOneWidget);
        expect(find.textContaining('한국채택국제회계기준'), findsWidgets);
        expect(t.takeException(), isNull);
        final title = find.textContaining('2025-01-01 ~ 2025-12-31').first;
        await t.ensureVisible(title);
        await t.tap(title);
        await t.pumpAndSettle();
        expect(find.text('해당 연도 감사의견 원문 보기'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'counterpart company or unsupported source cannot appear as own annual rows',
    (t) async {
      await pump(t, '01564514', payload('01586923'));
      expect(find.textContaining('다시 시도'), findsWidgets);
      expect(find.textContaining('2025-01-01 ~ 2025-12-31'), findsNothing);
      final bad = jsonDecode(payload('01564514')) as Map;
      bad['source']['reference'] = 'unrelated';
      await pump(t, '01564514', jsonEncode(bad));
      expect(find.textContaining('다시 시도'), findsWidgets);
    },
  );
}
