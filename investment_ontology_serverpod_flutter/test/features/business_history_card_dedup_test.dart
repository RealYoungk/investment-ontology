import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart' as app;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_history.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_insights_panel.dart';

import '../support/shad_test_host.dart';

class _Disclosure implements EndpointDisclosure {
  @override
  Future<BusinessContent?> businessContent(
    String corpCode, {
    int? bsnsYear,
  }) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements Client {
  @override
  final disclosure = _Disclosure();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BusinessTableInsight _table(String label, {String title = '제품 판매가격 변화'}) =>
    BusinessTableInsight(
      topic: 'productPrice',
      title: title,
      columns: ['품목', '가격'],
      rows: [
        BusinessTableRecord(label: label, cells: [label, '100']),
      ],
      measures: [
        BusinessTableMeasure(
          label: label,
          metric: '가격',
          period: '2026 반기',
          value: 100,
          unit: '천원',
        ),
      ],
      evidence: '$label | 100',
      validation: '원문 수치',
    );

void main() {
  testWidgets(
    'one merged history per topic/title retains all subsidiary series',
    (tester) async {
      app.client = _Client();
      final tables = [
        _table('특장차량 · 차량'),
        _table('냉동냉장 · 냉동기'),
        _table('공조 · 에어컨'),
        _table('별도 항목', title: '별도 가격'),
      ];
      final latest = BusinessContent(
        bsnsYear: 2026,
        rceptNo: 'latest',
        title: '사업의 내용',
        sections: [],
        charCount: 0,
        years: [2026],
        tableInsights: tables,
      );
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessTableInsightsPanel(
                  insights: tables,
                  rceptNo: 'latest',
                  corpCode: '00397289',
                  latest: latest,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('제품 판매가격 변화'), findsOneWidget);
      expect(find.text('별도 가격'), findsOneWidget);
      expect(find.byType(BusinessTableHistory), findsNWidgets(2));
      for (final label in ['특장차량 · 차량', '냉동냉장 · 냉동기', '공조 · 에어컨']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
