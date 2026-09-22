import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';

/// 글꼴을 내려받지 않도록 테스트용 브랜드를 쓴다.
AppBrand _brand() => AppBrand(
  colors: const AppColors(
    background: Color(0xFFF2EDE2),
    surface: Color(0xFFFAF7F0),
    surfaceHover: Color(0xFFE8E0D0),
    inverse: Color(0xFF17140F),
    onInverse: Color(0xFFF2EDE2),
    textPrimary: Color(0xFF17140F),
    textSecondary: Color(0xFF5C554A),
    textMuted: Color(0xFF9A9183),
    border: Color(0xFFCFC5B3),
    borderStrong: Color(0xFF17140F),
    accent: Color(0xFFC8401A),
    accentSubtle: Color(0xFFF3D9CC),
    onAccent: Color(0xFFF2EDE2),
    success: Color(0xFF3F6B4E),
    marketUp: Color(0xFFB83232),
    marketDown: Color(0xFF2463AD),
    marketKospi: Color(0xFF17140F),
    marketKosdaq: Color(0xFFC8401A),
    marketKonex: Color(0xFF8A7B5E),
    chartSeries1: Color(0xFF2F6DA8),
    chartSeries2: Color(0xFFC8401A),
    chartGrid: Color(0xFFE3DCCD),
    chartTile: Color(0xFFDCE5EE),
    chartTileHover: Color(0xFFBFD1E3),
  ),
  typography: const AppTypography(
    displayBase: TextStyle(),
    bodyBase: TextStyle(),
    numericBase: TextStyle(),
    labelBase: TextStyle(fontSize: 10),
  ),
  shape: const AppShape(radius: 0, strokeWidth: 1.2),
);

Widget _app(Widget child) => MaterialApp(
  theme: buildAppTheme(_brand()),
  home: Scaffold(body: SizedBox(width: 400, child: child)),
);

void main() {
  testWidgets('막대·꺾은선 차트는 음수와 빈 값이 있어도 그린다', (tester) async {
    const series = [
      ChartSeries(
        label: '매출액',
        color: Color(0xFF2F6DA8),
        values: [100, null, 250],
      ),
      ChartSeries(
        label: '영업이익',
        color: Color(0xFFC8401A),
        values: [-20, 10, 40],
      ),
    ];
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const AppColumnChart(
              categories: ['2023', '2024', '2025'],
              series: series,
              formatValue: _fmt,
            ),
            AppLineChart(
              categories: const ['2023', '2024', '2025'],
              series: series[1],
              formatValue: _fmt,
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(AppColumnChart)));
    await tester.pump();
    expect(find.text('2024'), findsWidgets);
    expect(find.text('—'), findsOneWidget, reason: '빈 값은 툴팁에 —');
  });

  testWidgets('트리맵: 두 단계 타일과 누르기', (tester) async {
    TreemapItem<String>? tapped;
    await tester.pumpWidget(
      _app(
        AppTreemap<String>(
          height: 300,
          onTap: (item) => tapped = item,
          items: const [
            TreemapItem(
              id: 'C',
              label: 'C 제조업',
              value: 70,
              tooltip: 'C',
              children: [
                TreemapItem(
                  id: 'C/26',
                  label: '전자부품',
                  detail: '53.2%',
                  value: 50,
                  tooltip: '26',
                ),
                TreemapItem(id: 'C/21', label: '의약품', value: 20, tooltip: '21'),
                TreemapItem(
                  id: 'C/99',
                  label: '아주 긴 이름의 좁은 세부 업종',
                  detail: '9.9%',
                  value: 1,
                  tooltip: '99',
                ),
              ],
            ),
            TreemapItem(
              id: 'J',
              label: 'J 정보통신업',
              value: 30,
              tooltip: 'J',
              children: [
                TreemapItem(
                  id: 'J/63',
                  label: '정보서비스',
                  value: 30,
                  tooltip: '63',
                ),
                TreemapItem(
                  id: '',
                  label: '그 외',
                  value: 0.001,
                  tooltip: '',
                  tappable: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('전자부품'), findsOneWidget);
    expect(find.text('53.2%'), findsOneWidget);
    expect(
      find.text('9.9%'),
      findsNothing,
      reason: '이름이 안 들어가는 좁은 칸은 비중도 쓰지 않는다',
    );

    await tester.tap(find.text('전자부품'));
    expect(tapped?.id, 'C/26');
  });
}

String _fmt(double v) => v.toStringAsFixed(0);
