import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';

void main() {
  final fixture = File('test/fixtures/brils-current-core.json')
      .readAsStringSync();
  Future<void> pump(
    WidgetTester t, {
    String code = '01801026',
    String? payload,
  }) async {
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
                key: ValueKey(payload ?? code),
                corpCode: code,
                loader: (corp, kind) async {
                  expect(corp, code);
                  expect(kind, 'issuerFinancials');
                  return payload ?? fixture;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'actual 40 cells show five honest source periods, both half bases and source links at 320px',
    (t) async {
      await pump(t);
      expect(find.byType(ExpansionTile), findsNWidgets(5));
      expect(find.textContaining('누적 6개월'), findsNWidgets(2));
      expect(
        find.textContaining('2026-01-01 ~ 2026-06-30 · 연결'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2026-01-01 ~ 2026-06-30 · 별도'),
        findsOneWidget,
      );
      expect(find.textContaining('정기보고서 집계·TTM에 포함하지 않습니다'), findsOneWidget);
      await t.tap(find.byType(ExpansionTile).first);
      await t.pumpAndSettle();
      expect(find.text('DART 원문 재무 절 보기'), findsWidgets);
      expect(find.byType(Tooltip), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'not collected stays distinct from source failure; other companies do not fetch',
    (t) async {
      await pump(t, payload: jsonEncode({'state': 'notCollected', 'rows': []}));
      expect(find.text('별도 원문 핵심 재무 수집 전입니다.'), findsOneWidget);
      await pump(
        t,
        payload: jsonEncode({
          'state': 'ready',
          'provider': 'forged',
          'source': {},
          'rows': [],
        }),
      );
      expect(find.text('별도 원문 핵심 재무 수집 전입니다.'), findsNothing);
      expect(find.textContaining('불러오지 못했어요'), findsWidgets);
      await pump(t, code: '00139214');
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('별도 공식 원문 핵심 재무'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'all eight IPO issuers render their source-bound current basis and incorporation scope at 320px',
    (t) async {
      final companies = jsonDecode(
        File('test/fixtures/ipo-eight-current-core.json').readAsStringSync(),
      ) as List;
      for (final company in companies) {
        final snapshot = company['snapshot'] as Map;
        await pump(t, code: company['corpCode'], payload: jsonEncode(snapshot));
        expect(
          find.byType(ExpansionTile),
          findsNWidgets((snapshot['rows'] as List).length),
        );
        if (company['corpCode'].startsWith('020')) {
          expect(find.textContaining('설립일부터 누적'), findsOneWidget);
          expect(find.textContaining('반기 누적 6개월'), findsNothing);
        }
        if (company['corpCode'] == '01564514' ||
            company['corpCode'] == '02029258') {
          expect(find.textContaining('원문 의견 미표기'), findsOneWidget);
        }
        await t.tap(find.byType(ExpansionTile).first);
        await t.pumpAndSettle();
        if (company['corpCode'] == '02029258') {
          expect(find.textContaining('(손실)'), findsWidgets);
          expect(find.textContaining('0으로 채우지 않았습니다'), findsOneWidget);
        }
        expect(t.takeException(), isNull, reason: company['corpCode']);
      }
    },
  );
  test('counterpart, source, basis, year and fake regular-report metadata fail closed', () {
    final original = (jsonDecode(fixture) as Map)['rows'];
    expect(validateIssuerFinancialRows(original).length, 5);
    for (final edit in [
      {'corpCode': '00139214'},
      {'numericState': 'complete'},
      {'officialUrl': 'https://example.com/report'},
      {'currency': 'USD'},
      {'periodEnd': '2024-12-31'},
      {'regularReportCode': '11011'},
      {'auditStatus': 'unaudited'},
      {'sha256': 'invalid'},
    ]) {
      final changed = jsonDecode(jsonEncode(original)) as List;
      (changed.first as Map).addAll(edit);
      expect(() => validateIssuerFinancialRows(changed), throwsFormatException);
    }
  });
}
