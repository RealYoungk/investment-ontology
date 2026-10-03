import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/split_plan_documents_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/split_plan_source_registry.dart';

void main() {
  Map<String, dynamic> payload(Map<String, dynamic> row) => {
    'state': 'ready',
    'provider': 'verified-delegated-split-plan',
    'source': {
      'kind': 'officialFile',
      'url': 'https://kind.krx.co.kr',
      'reference': 'parent-submitted-split-plan;link-only;no-own-period-or-numeric-assertion',
    },
    'rows': [row],
  };
  test(
    'UI exact pins remain identical to backend compiled source metadata',
    () {
      final backend = File(
        '../investment_ontology_serverpod_server/lib/src/ontology/research/split_plan_documents.dart',
      ).readAsStringSync();
      for (final row in SplitPlanSourceRegistry.rows) {
        for (final field in [
          'sha256',
          'officialUrl',
          'delegationQuote',
          'establishmentProfileUrl',
          'establishmentProfileRetrievedAt',
        ]) {
          expect(backend, contains(row[field] as String), reason: field);
        }
        for (final key in row.keys) {
          final bad = Map<String, dynamic>.from(row)..[key] = 'changed';
          expect(
            () => SplitPlanSourceRegistry.validate(
              row['corpCode'] as String,
              payload(bad),
            ),
            throwsFormatException,
            reason: key,
          );
        }
      }
    },
  );
  for (final row in SplitPlanSourceRegistry.rows) {
    testWidgets(
      '${row['corpCode']} delegated source and planned/actual dates distinguish at320px',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SplitPlanDocumentsSection(
                    corpCode: row['corpCode'] as String,
                    loader: (corp, kind) async {
                      expect(kind, 'splitPlanDocuments');
                      return jsonEncode(payload(row));
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('분할 신설회사 · 대행 제출 원문'), findsOneWidget);
        expect(
          find.textContaining(
            '계획 분할 ${row['plannedSplitDate']} · 등록 설립 ${row['actualEstablishedDate']}',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('신설회사의 자체 감사 실적이나 정기보고서로 집계하지 않습니다'),
          findsOneWidget,
        );
        expect(find.text('KIND 공식 원문 보기'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('unknown company never requests split data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplitPlanDocumentsSection(
          corpCode: '01801026',
          loader: (_, _) async => throw StateError('Must not fetch'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('분할 신설회사 · 대행 제출 원문'), findsNothing);
  });
}
