import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/issuer_financials_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/retrospective_fund_contract.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/widgets/issuer_documents_status.dart';

void main() {
  final original = jsonDecode(
    File('test/fixtures/retrospective-fund-categories.json').readAsStringSync(),
  ) as Map;
  testWidgets(
    'actual KB2024/25 and retrospective own2023/2022H2 display conflict and missing scopes at320px',
    (t) async {
      final infrastructure = jsonDecode(
        File('test/fixtures/infrastructure-fund-current-categories.json')
            .readAsStringSync(),
      ) as Map;
      final payload = Map<String, dynamic>.from(original);
      payload['rows'] = [
        ...original['rows'],
        ...(infrastructure['rows'] as List).where(
          (r) => r['corpCode'] == '01880801',
        ),
      ];
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
                  corpCode: '01880801',
                  loader: (_, _) async => jsonEncode(payload),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNWidgets(4));
      for (final period in [
        '2025-01-01 ~ 2025-12-31 · 단일 펀드',
        '2024-01-01 ~ 2024-12-31 · 단일 펀드',
        '2023-01-01 ~ 2023-12-31 · 단일 펀드',
        '2022-07-01 ~ 2022-12-31 · 단일 펀드',
      ]) {
        final title = find.text(period);
        await t.ensureVisible(title);
        await t.tap(title);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      expect(find.textContaining('당해 감사보고서 원문을 확보한 것으로'), findsNWidgets(2));
      expect(find.textContaining('자본변동표가 없어 미등록'), findsNWidgets(2));
      expect(find.text('공식 정정 투자설명서 PDF 보기'), findsNWidgets(2));
      final conflict = find.text('요약표와 상세표의 원문 충돌 12개').first;
      await t.ensureVisible(conflict);
      await t.tap(conflict);
      await t.pumpAndSettle();
      expect(
        find.textContaining('요약 60,800,000,000원 (265쪽) / 상세 74,665,552,878원'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
  test('exact source date, fiscal basis, coordinate, numeric and quarantined claims fail closed', () {
    final rows = original['rows'] as List;
    expect(validateIssuerFinancialRows(rows).length, 2);
    for (final edit in [
      {'publishedAt': '2023-12-31'},
      {'documentType': 'auditReport'},
      {'standaloneOwnAuditRetrieved': true},
      {'periodKind': 'halfYear'},
      {'ttmEligible': true},
      {'sourceConflicts': []},
      {'excludedFiscalPeriods': []},
      {'fullStatementCollected': true},
      {'corpCode': '00435297'},
    ]) {
      final x = jsonDecode(jsonEncode(rows)) as List;
      (x.first as Map).addAll(edit);
      expect(() => validateIssuerFinancialRows(x), throwsFormatException);
    }
    final x = jsonDecode(jsonEncode(rows)) as List;
    x.first['accounts'][0]['amountInteger'] = '1';
    expect(() => validateIssuerFinancialRows(x), throwsFormatException);
    final y = jsonDecode(jsonEncode(rows)) as List;
    y.first['accounts'][0]['characterSpan'] = [1, 2];
    expect(() => validateIssuerFinancialRows(y), throwsFormatException);
    expect(
      () => validateIssuerFinancialRows([rows.first, rows.first]),
      throwsFormatException,
    );
  });
  test(
    'metadata-only UI admits only the exact corrected officialIR prospectus',
    () {
      final m = RetrospectiveFundContract.data['metadata'] as Map;
      expect(
        issuerDocumentRows(
          jsonEncode({
            'state': 'ready',
            'source': {'kind': 'officialFile', 'url': 'https://kbif.co.kr'},
            'rows': [m],
          }),
          '01880801',
        ).length,
        1,
      );
      final changed = Map<String, dynamic>.from(m)
        ..['officialUrl'] = 'https://kbif.co.kr/upload/2024/11/other.pdf';
      expect(
        () => issuerDocumentRows(
          jsonEncode({
            'state': 'ready',
            'source': {'kind': 'officialFile', 'url': 'https://kbif.co.kr'},
            'rows': [changed],
          }),
          '01880801',
        ),
        throwsFormatException,
      );
    },
  );
}
