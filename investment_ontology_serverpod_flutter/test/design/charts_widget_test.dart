import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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

Widget _app(Widget child, {double width = 400}) => MaterialApp(
  theme: buildAppTheme(_brand()),
  home: Scaffold(
    body: SizedBox(width: width, child: child),
  ),
);

void main() {
  test('compact annual and interim labels all fit a mobile axis', () {
    final widths = [14.0, 14.0, 14.0, 14.0, 14.0, 14.0, 35.0];
    expect(categoryAxisLabelIndices(widths: widths, plotWidth: 258), [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    ]);
    expect(
      categoryAxisLabelIndices(widths: [...widths.take(6), 26], plotWidth: 192),
      [0, 1, 2, 3, 4, 5, 6],
    );
  });
  test('one long final label does not thin all annual labels', () {
    final widths = [28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 90.0];
    final selected = categoryAxisLabelIndices(widths: widths, plotWidth: 258);
    expect(selected, containsAll([0, 1, 2, 3, 6]));
    var previousRight = double.negativeInfinity;
    for (final i in selected) {
      final left = (258 / widths.length * (i + .5) - widths[i] / 2).clamp(
        0,
        258 - widths[i],
      );
      expect(left, greaterThanOrEqualTo(previousRight + 4));
      expect(left + widths[i], lessThanOrEqualTo(258));
      previousRight = left + widths[i];
    }
    expect(categoryAxisLabelIndices(widths: widths, plotWidth: 0), isEmpty);
    expect(categoryAxisLabelIndices(widths: [], plotWidth: 258), isEmpty);
    expect(
      categoryAxisLabelIndices(
        widths: List.filled(7, 14),
        plotWidth: 258,
        maxLabels: 4,
      ),
      [0, 2, 4, 6],
    );
  });
  AppComboChart combo({bool short = false, bool empty = false}) =>
      AppComboChart(
        categories: short ? ['2025'] : ['2023', '2024', '2025'],
        columnSeries: ChartSeries(
          label: '매출액',
          color: const Color(0xFF2F6DA8),
          values: short ? [250] : [100, 0, 250],
        ),
        lineSeries: ChartSeries(
          label: '영업이익률',
          color: const Color(0xFFC8401A),
          values: short ? [empty ? null : .4] : [-12.3, null, .4],
        ),
        extraTooltipSeries: [
          ChartSeries(
            label: '영업이익',
            color: const Color(0xFF5C554A),
            values: short ? [100] : [-1230, null, 100],
          ),
        ],
        formatValue: (v) => '${v.toStringAsFixed(0)}원',
        formatLineValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
      );

  testWidgets('혼합 차트: 좁은 화면 터치 상세의 금액·비율과 적자', (tester) async {
    await tester.pumpWidget(_app(combo(), width: 320));
    final origin = tester.getTopLeft(find.byType(AppComboChart));
    await tester.tapAt(origin + const Offset(96, 120));
    await tester.pump();
    expect(find.text('100원'), findsOneWidget);
    expect(find.text('-1230원'), findsOneWidget);
    expect(find.text('-1230.0%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(origin + const Offset(160, 120));
    await tester.pump();
    expect(find.text('0원'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('-1230.0%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('혼합 차트: hover 후 기간을 바꿔도 이전 상세가 남지 않는다', (tester) async {
    await tester.pumpWidget(_app(combo()));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(
      tester.getTopLeft(find.byType(AppComboChart)) + const Offset(280, 120),
    );
    await tester.pump();
    expect(find.text('250원'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);
    await gesture.removePointer();

    await tester.pumpWidget(_app(combo(short: true, empty: true)));
    await tester.pump();
    expect(find.text('40.0%'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(AppComboChart));
    await tester.pump();
    expect(find.text('250원'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('두 이익률은 공통 축을 쓰며 누락된 영업이익률에도 순이익률을 표시한다', (tester) async {
    final chart = AppComboChart(
      categories: ['2025', '2026'],
      columnSeries: const ChartSeries(
        label: '매출액',
        color: Color(0xFF2F6DA8),
        values: [100, 100],
      ),
      lineSeries: const ChartSeries(
        label: '영업이익률',
        color: Color(0xFFC8401A),
        values: [null, null],
      ),
      additionalLineSeries: const [
        ChartSeries(
          label: '순이익률',
          color: Color(0xFF5C554A),
          values: [-4, .5],
          isLine: true,
          isDashed: true,
        ),
      ],
      formatValue: (v) => '${v.toStringAsFixed(0)}원',
      formatLineValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
    );
    expect(chart.secondarySeries!.values, [null, null, -4, .5]);
    await tester.pumpWidget(_app(chart, width: 320));
    final origin = tester.getTopLeft(find.byType(AppComboChart));
    await tester.tapAt(origin + const Offset(100, 120));
    await tester.pump();
    expect(find.text('-400.0%'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('100원'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('트리맵: 세로 공간이 있으면 긴 이름을 여러 줄로 모두 표시한다', (tester) async {
    const label = '전자부품 컴퓨터 영상 음향 및 통신장비 제조업';
    await tester.pumpWidget(
      _app(
        AppTreemap<String>(
          height: 180,
          items: const [
            TreemapItem(
              id: '26',
              label: label,
              value: 1,
              tooltip: '공식 중분류',
              detail: '100조',
            ),
          ],
          onTap: (_) {},
        ),
        width: 120,
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: label.length),
    );
    expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(find.text('100조'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('트리맵: 낮은 타일과 확대 글꼴에서도 이름을 우선하며 넘치지 않는다', (tester) async {
    const label = '전자부품 컴퓨터 영상 음향 및 통신장비 제조업';
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: AppTreemap<String>(
              height: 45 * scale,
              items: const [
                TreemapItem(
                  id: '26',
                  label: label,
                  value: 1,
                  tooltip: '공식 중분류',
                  detail: '100조',
                ),
              ],
              onTap: (_) {},
            ),
          ),
          width: 120,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100조'), findsNothing);
      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(
        tester.getSize(find.text(label)).height,
        lessThanOrEqualTo(45 * scale - 12),
      );
    }
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
