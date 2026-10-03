import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_source_scope_notice.dart';

void main() {
  Future<void> pump(WidgetTester t, String? title) async {
    await t.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FinancialSourceScopeNotice(sourceTitle: title),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('HTML source contract indicates subset and wraps at 320px', (
    t,
  ) async {
    await pump(
      t,
      'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · 사업보고서 (2025.12) · 별도 · SHA256:d9ec1763',
    );
    expect(find.textContaining('검증된 핵심계정 일부'), findsOneWidget);
    expect(find.textContaining('전체 재무제표·주석의 원문 행'), findsOneWidget);
    expect(find.textContaining('API 응답'), findsNothing);
    expect(t.takeException(), isNull);
    final box = t.renderObject<RenderBox>(find.textContaining('핵심계정 일부'));
    expect(box.size.width, lessThanOrEqualTo(288));
    expect(box.size.height, greaterThan(40));
  });
  testWidgets('seven-account provenance explains missing capex at 320px', (
    t,
  ) async {
    await pump(
      t,
      jsonEncode({
        'coreRows': 7,
        'action': 'verified-keyless-annual-source-after-api-noData',
        'corpCode': '01205514',
        'targetReceipt': '20250305000164',
        'fsDiv': 'separate',
        'coreRowProvenance': [
          {
            'html_provenance': {
              'partialCore7': true,
              'detailHierarchyComplete': false,
              'notesVerified': false,
              'missingAccountReasons': {
                'capex': 'No printed whole PPE acquisition total',
              },
            },
          },
        ],
      }),
    );
    expect(find.textContaining('유형자산 취득 총액은 미확보'), findsOneWidget);
    expect(find.textContaining('FCF와 FCF 수익률은 계산하지 않습니다'), findsOneWidget);
    expect(find.textContaining('주석은 검증을 마치지'), findsOneWidget);
    expect(t.takeException(), isNull);
    expect(
      FinancialSourceScopeNotice.messageFor(jsonEncode({'coreRows': 7})),
      isNull,
    );
  });
  testWidgets('API response scope is distinct, no all original rows claim', (
    t,
  ) async {
    await pump(t, 'DART 전체 재무제표 (fnlttSinglAcntAll) · 사업보고서 (2025.12) · 별도');
    expect(find.textContaining('재무 API 응답의 계정과 금액'), findsOneWidget);
    expect(find.textContaining('모든 표·주석 행'), findsOneWidget);
    expect(find.textContaining('핵심계정 일부'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('XBRL subset and unknown title fail closed', (t) async {
    await pump(t, 'DART 원문 XBRL 핵심계정 · 사업보고서 (2025.12)');
    expect(find.textContaining('핵심계정 일부'), findsOneWidget);
    await pump(t, '주석: DART 원문 HTML 부분 핵심계정');
    expect(find.textContaining('핵심계정 일부'), findsNothing);
  });
  test('known half/append/six contracts; no source-count inference', () {
    for (final title in [
      'DART 원문 XBRL 반기 부분 핵심7계정(손익3개월·누적6개월)',
      'DART 원문 XBRL 당기 핵심계정 복구',
      'DART 원문 HTML 부분 핵심6계정(BNK 정확원문)',
    ]) {
      expect(FinancialSourceScopeNotice.messageFor(title), contains('핵심계정 일부'));
    }
    expect(FinancialSourceScopeNotice.messageFor(null), isNull);
  });
}
