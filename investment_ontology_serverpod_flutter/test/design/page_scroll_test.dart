import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

import '../support/shad_test_host.dart';

void main() {
  testWidgets(
    'research page scrolls over charts and table with semantics enabled',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(serviceBrand),
            home: Scaffold(
              body: PageFrame(
                children: [
                  const Text('시장 시작'),
                  const SectionLabel(
                    '지수 추이',
                    tooltip: '공식 일별 지수',
                    trailing: Text('1년'),
                  ),
                  AppColumnChart(
                    categories: const ['2024', '2025'],
                    formatValue: (value) => '$value',
                    series: [
                      ChartSeries(
                        label: '합성 지수',
                        color: serviceColors.chartSeries1,
                        values: const [100, 120],
                      ),
                    ],
                  ),
                  AppDataTable(
                    columns: const [
                      AppColumn('기업'),
                      AppColumn('값', numeric: true),
                    ],
                    rows: [
                      for (var i = 0; i < 40; i++)
                        AppRow([Text('합성 기업 $i'), Text('$i')]),
                    ],
                  ),
                  const Text('시장 끝'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: const Offset(300, 200),
          scrollDelta: const Offset(0, 500),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
