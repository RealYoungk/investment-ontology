import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/compare_metrics_table.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('$width: fixed labels and synchronized headings', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(researchDeskBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CompareMetricsTable(
                    companies: const [
                      '삼성전자',
                      '아주 긴 이름의 비교 기업',
                      '삼성전기',
                      '네 번째 기업',
                    ],
                    metrics: const [
                      CompareMetricRow(
                        label: '영업이익 성장률',
                        values: ['12.3%', '0.0%', null, '-8.5%'],
                        notes: [null, null, '해당 기간 영업이익 미확보', null],
                      ),
                      CompareMetricRow(
                        label: '재무 기준',
                        values: [
                          '연결 · 연결 재무제표 기준',
                          '별도 · 연결 자료 미확보로 별도 사용',
                          '연결',
                          '연결',
                        ],
                        notes: [null, null, null, null],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labelBefore = tester.getRect(find.text('영업이익 성장률'));
      final headerBefore = tester.getRect(find.text('삼성전자'));
      final valueBefore = tester.getRect(find.text('12.3%'));
      if (width < 900) {
        await tester.drag(
          find.byKey(const ValueKey('compare-values-scroll')),
          const Offset(-360, 0),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(find.text('영업이익 성장률')), labelBefore);
        final headerDelta =
            tester.getRect(find.text('삼성전자')).left - headerBefore.left;
        final valueDelta =
            tester.getRect(find.text('12.3%')).left - valueBefore.left;
        expect(headerDelta, lessThan(width < 600 ? -100 : -20));
        expect(valueDelta, closeTo(headerDelta, 0.01));
      } else {
        expect(find.text('지표는 왼쪽에 고정됩니다 · 기업 열을 좌우로 넘겨 보세요'), findsNothing);
      }
      expect(find.text('—'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('large text preserves aligned rows', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const SingleChildScrollView(
                child: CompareMetricsTable(
                  companies: ['긴 이름의 기업', '다른 기업'],
                  metrics: [
                    CompareMetricRow(
                      label: '잉여현금흐름(TTM)',
                      values: ['123조 4567억원', null],
                      notes: [null, null],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final label = tester.getRect(find.text('잉여현금흐름(TTM)'));
    final value = tester.getRect(find.text('123조 4567억원'));
    expect(label.center.dy, closeTo(value.center.dy, 0.1));
  });
}
