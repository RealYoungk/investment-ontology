import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../../tokens.dart';
import 'chart_scale.dart';

/// 차트 계열 하나. [values]는 [AppColumnChart.categories]와 같은 순서, 없는 값은 null.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.values,
    this.isLine = false,
    this.isDashed = false,
  });

  final String label;
  final Color color;
  final List<double?> values;
  final bool isLine;
  final bool isDashed;
}

/// Categorical colors: keep categories distinct instead of repeating three colors.
List<Color> categoricalChartColors(BuildContext context) => [
  context.colors.chartSeries1,
  context.colors.chartSeries2,
  context.colors.chartSeries3,
  const Color(0xFF007D75),
  const Color(0xFF9B6500),
  const Color(0xFFB23879),
  const Color(0xFF536631),
  const Color(0xFF545D70),
];

/// 계열 범례. 계열이 둘 이상일 때 쓴다 (글자는 본문색, 색은 옆 견본이 나타낸다).
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.series});

  final List<ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return Wrap(
      spacing: AppSpace.lg,
      runSpacing: AppSpace.xs,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.isLine)
                SizedBox(
                  width: 24,
                  height: 10,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (s.isDashed)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 2; i++)
                              Container(width: 9, height: 3, color: s.color),
                          ],
                        )
                      else
                        Container(height: 2, color: s.color),
                      if (!s.isDashed)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 6),
              Text(s.label, style: t.body(12.5, color: c.textSecondary)),
            ],
          ),
      ],
    );
  }
}

/// 공통 뼈대: 왼쪽 눈금, 아래 범주 이름, 마우스 위치의 범주 강조와 툴팁.
abstract class _CategoryChart extends StatefulWidget {
  const _CategoryChart({
    super.key,
    required this.categories,
    required this.series,
    required this.formatValue,
    required this.height,
    this.formatCategory,
    this.maxAxisLabels,
    this.categoryNoun = '기간',
  });

  final List<String> categories;
  final String Function(String)? formatCategory;
  final int? maxAxisLabels;
  final String categoryNoun;
  final List<ChartSeries> series;

  /// 눈금·툴팁 값 표시.
  final String Function(double value) formatValue;
  final double height;

  bool get includeZero;
  List<ChartSeries> get scaleSeries => series;
  ChartSeries? get secondarySeries => null;
  String formatSecondary(double value) => formatValue(value);
  String? tooltipNote(int index) => null;
  List<({String label, Color color, String value})> tooltipRows(int index) => [
    for (final s in series)
      (
        label: s.label,
        color: s.color,
        value: s.values[index] == null ? '—' : formatValue(s.values[index]!),
      ),
  ];

  @override
  State<_CategoryChart> createState() => _CategoryChartState();

  void paintMarks(
    Canvas canvas,
    Rect plot,
    ChartScale scale,
    int? hovered,
    AppColors colors,
  );
}

class _CategoryChartState extends State<_CategoryChart> {
  static const _labelHeight = 22.0;

  int? _hovered;
  Offset? _pointer;
  bool _keyboardFocused = false;

  void _select(int index) => setState(() {
    _hovered = index.clamp(0, widget.categories.length - 1);
    _pointer = Offset.zero;
  });

  String _description(int index) => [
    widget.categories[index],
    for (final row in widget.tooltipRows(index))
      '${row.label}: ${row.value == '—' ? '자료 없음' : row.value}',
    ?widget.tooltipNote(index),
  ].join(', ');

  @override
  void didUpdateWidget(covariant _CategoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      _hovered = null;
      _pointer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final values = [
      for (final s in widget.scaleSeries)
        for (final v in s.values) ?v,
    ];
    final scale = ChartScale.of(values, includeZero: widget.includeZero);
    final n = widget.categories.length;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tickStyle = t.numeric(10.5, color: c.textMuted);
          final leftWidth = chartAxisWidth(
            scale.ticks.map(widget.formatValue),
            tickStyle,
            maxWidth: constraints.maxWidth * .4,
          );
          final secondary = widget.secondarySeries;
          final rightWidth = secondary == null
              ? 0.0
              : chartAxisWidth(
                  ChartScale.of(secondary.values.nonNulls).ticks
                      .map(widget.formatSecondary),
                  tickStyle,
                  maxWidth: constraints.maxWidth * .4,
                );
          final plot = Rect.fromLTWH(
            leftWidth,
            8,
            math.max(
              0,
              constraints.maxWidth - leftWidth - rightWidth,
            ),
            math.max(0, widget.height - _labelHeight - 8),
          );
          int? indexAt(Offset p) {
            if (n == 0 ||
                plot.width <= 0 ||
                p.dx < plot.left ||
                p.dx > plot.right) {
              return null;
            }
            return ((p.dx - plot.left) / plot.width * n).floor().clamp(
              0,
              n - 1,
            );
          }

          final hovered = _hovered;
          return Focus(
            onFocusChange: (focused) => setState(() {
              _keyboardFocused = focused;
              if (focused && n > 0) {
                _hovered ??= n - 1;
                _pointer = Offset.zero;
              } else if (!focused) {
                _hovered = null;
                _pointer = null;
              }
            }),
            onKeyEvent: (_, event) {
              if (n == 0 || event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.arrowLeft) {
                _select((_hovered ?? n - 1) - 1);
              } else if (key == LogicalKeyboardKey.arrowRight) {
                _select((_hovered ?? 0) + 1);
              } else if (key == LogicalKeyboardKey.home) {
                _select(0);
              } else if (key == LogicalKeyboardKey.end) {
                _select(n - 1);
              } else if (key == LogicalKeyboardKey.escape) {
                setState(() {
                  _hovered = null;
                  _pointer = null;
                });
              } else {
                return KeyEventResult.ignored;
              }
              return KeyEventResult.handled;
            },
            child: Semantics(
              container: true,
              label: '${widget.series.map((s) => s.label).join(' · ')} 차트',
              hint: '눌러 상세 보기, 다시 누르거나 바깥을 눌러 닫기, 가로 드래그 또는 좌우 방향키로 기간 이동, Home 첫 기간, End 마지막 기간',
              value: hovered == null
                  ? '$n개 ${widget.categoryNoun}'
                  : _description(hovered),
              // The chart exposes period actions rather than a synthetic
              // numeric slider (Flutter Web otherwise displays values 0/1/2).
              customSemanticsActions: n == 0
                  ? null
                  : {
                      const CustomSemanticsAction(label: '다음 기간'): () =>
                          _select((_hovered ?? 0) + 1),
                      const CustomSemanticsAction(label: '이전 기간'): () =>
                          _select((_hovered ?? n - 1) - 1),
                    },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _keyboardFocused
                        ? c.accent
                        : c.background.withValues(alpha: 0),
                  ),
                  borderRadius: context.shape.borderRadius,
                ),
                child: TapRegion(
                  onTapOutside: (_) => setState(() {
                    _hovered = null;
                    _pointer = null;
                  }),
                  child: MouseRegion(
                    onHover: (e) => setState(() {
                      _hovered = indexAt(e.localPosition);
                      _pointer = e.localPosition;
                    }),
                    onExit: (_) {
                      if (!_keyboardFocused) setState(() => _hovered = null);
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Select only after a completed tap, so vertical scrolling
                      // does not open a detail. Horizontal drag owns scrubbing.
                      onTapUp: (d) => setState(() {
                        final index = indexAt(d.localPosition);
                        _hovered = index == _hovered ? null : index;
                        _pointer = _hovered == null ? null : d.localPosition;
                      }),
                      onHorizontalDragStart: (d) => setState(() {
                        _hovered = indexAt(d.localPosition);
                        _pointer = d.localPosition;
                      }),
                      onHorizontalDragUpdate: (d) => setState(() {
                        _hovered = indexAt(
                          Offset(
                            d.localPosition.dx.clamp(plot.left, plot.right),
                            d.localPosition.dy,
                          ),
                        );
                        _pointer = d.localPosition;
                      }),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ChartPainter(
                                chart: widget,
                                plot: plot,
                                scale: scale,
                                hovered: hovered,
                                colors: c,
                                tickStyle: tickStyle,
                                labelStyle: t.body(
                                  11.5,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          if (hovered != null && _pointer != null)
                            _tooltip(
                              context,
                              constraints.maxWidth,
                              plot,
                              hovered,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tooltip(BuildContext context, double width, Rect plot, int index) {
    final c = context.colors;
    final t = context.typo;
    const tipWidth = 190.0;
    final band = plot.width / widget.categories.length;
    final center = plot.left + band * (index + 0.5);
    final left = (center + band / 2 + 6 + tipWidth > width)
        ? center - band / 2 - 6 - tipWidth
        : center + band / 2 + 6;
    return Positioned(
      left: left.clamp(0, math.max(0, width - tipWidth)),
      top: 0,
      width: tipWidth,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.inverse,
              borderRadius: context.shape.borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.categories[index],
                  style: t.body(
                    12,
                    color: c.onInverse,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                for (final row in widget.tooltipRows(index))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: row.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            row.label,
                            style: t.body(11.5, color: c.onInverse),
                          ),
                        ),
                        Text(
                          row.value,
                          style: t.numeric(11.5, color: c.onInverse),
                        ),
                      ],
                    ),
                  ),
                if (widget.tooltipNote(index) case final note?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text(note, style: t.body(11.5, color: c.onInverse)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.chart,
    required this.plot,
    required this.scale,
    required this.hovered,
    required this.colors,
    required this.tickStyle,
    required this.labelStyle,
  });

  final _CategoryChart chart;
  final Rect plot;
  final ChartScale scale;
  final int? hovered;
  final AppColors colors;
  final TextStyle tickStyle;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = chart.categories.length;
    if (n == 0 || plot.width <= 0 || plot.height <= 0) return;
    final band = plot.width / n;

    if (hovered != null) {
      canvas.drawRect(
        Rect.fromLTWH(plot.left + band * hovered!, plot.top, band, plot.height),
        Paint()..color = colors.surfaceHover.withValues(alpha: 0.6),
      );
    }

    final grid = Paint()
      ..color = colors.chartGrid
      ..strokeWidth = 1;
    for (final tick in scale.ticks) {
      final y = plot.bottom - scale.fraction(tick) * plot.height;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        tick == 0
            ? (Paint()
                ..color = colors.textMuted
                ..strokeWidth = 1)
            : grid,
      );
      final tp = _text(
        chart.formatValue(tick),
        tickStyle,
        maxWidth: math.max(0, plot.left - 8),
      );
      tp.paint(canvas, Offset(plot.left - 8 - tp.width, y - tp.height / 2));
    }

    final secondary = chart.secondarySeries;
    if (secondary != null) {
      final rightScale = ChartScale.of(secondary.values.nonNulls);
      for (final tick in rightScale.ticks) {
        final y = plot.bottom - rightScale.fraction(tick) * plot.height;
        final tp = _text(
          chart.formatSecondary(tick),
          tickStyle.copyWith(color: secondary.color),
          maxWidth: math.max(0, size.width - plot.right - 8),
        );
        tp.paint(canvas, Offset(plot.right + 8, y - tp.height / 2));
      }
    }

    // 범주 이름: 겹치면 건너뛰며 쓴다.
    final painters = [
      for (final c in chart.categories)
        _text(chart.formatCategory?.call(c) ?? c, labelStyle),
    ];
    final visible = categoryAxisLabelIndices(
      widths: [for (final p in painters) p.width],
      plotWidth: plot.width,
      maxLabels: chart.maxAxisLabels,
    );
    for (final i in visible) {
      final p = painters[i];
      p.paint(
        canvas,
        Offset(
          (plot.left + band * (i + 0.5) - p.width / 2).clamp(
            plot.left,
            math.max(plot.left, plot.right - p.width),
          ),
          plot.bottom + 6,
        ),
      );
    }

    chart.paintMarks(canvas, plot, scale, hovered, colors);
  }

  static TextPainter _text(
    String s,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.chart != chart ||
      old.plot != plot ||
      old.hovered != hovered ||
      old.colors != colors;
}

/// Pick labels by their actual bounds, so one long label does not hide
/// otherwise readable years across the entire axis. Keep the latest label.
List<int> categoryAxisLabelIndices({
  required List<double> widths,
  required double plotWidth,
  int? maxLabels,
}) {
  if (widths.isEmpty || plotWidth <= 0) return const [];
  final n = widths.length;
  final band = plotWidth / n;
  final every = maxLabels == null ? 1 : (n / math.max(1, maxLabels)).ceil();
  final selected = <int>[];
  var nextLeft = double.infinity;
  for (var i = n - 1; i >= 0; i--) {
    if ((n - 1 - i) % every != 0) continue;
    final left = (band * (i + .5) - widths[i] / 2)
        .clamp(0.0, math.max(0.0, plotWidth - widths[i]))
        .toDouble();
    if (left + widths[i] + 4 > nextLeft) continue;
    selected.add(i);
    nextLeft = left;
  }
  return selected.reversed.toList();
}

/// 범주별 세로 막대. 계열이 여러 개면 나란히 놓는다. 음수는 기준선 아래로 그린다.
class AppColumnChart extends _CategoryChart {
  const AppColumnChart({
    super.key,
    required super.categories,
    required super.series,
    required super.formatValue,
    this.extraTooltipSeries = const [],
    this.categoryNotes = const [],
    this.showMissingMarkers = false,
    super.formatCategory,
    super.maxAxisLabels,
    super.categoryNoun,
    super.height = 200,
  });

  /// Additional same-unit values in the tooltip, without drawing extra bars.
  final List<ChartSeries> extraTooltipSeries;

  /// 기간별 결측 사유. 차트 하단에 반복하지 않고 해당 기간 상세에 표시한다.
  final List<String?> categoryNotes;
  final bool showMissingMarkers;

  @override
  String? tooltipNote(int index) =>
      index < categoryNotes.length ? categoryNotes[index] : null;

  @override
  List<({String label, Color color, String value})> tooltipRows(int index) => [
    ...super.tooltipRows(index),
    for (final s in extraTooltipSeries)
      (
        label: s.label,
        color: s.color,
        value: s.values[index] == null ? '—' : formatValue(s.values[index]!),
      ),
  ];

  static const _maxBar = 24.0;
  static const _gap = 2.0;
  static const _radius = Radius.circular(4);

  @override
  bool get includeZero => true;

  @override
  void paintMarks(
    Canvas canvas,
    Rect plot,
    ChartScale scale,
    int? hovered,
    AppColors colors,
  ) {
    final n = categories.length;
    final band = plot.width / n;
    final k = series.length;
    final bar = math.min(_maxBar, (band * 0.7 - _gap * (k - 1)) / k);
    if (bar <= 0) return;
    final group = bar * k + _gap * (k - 1);
    final zeroY = plot.bottom - scale.fraction(0) * plot.height;

    for (var i = 0; i < n; i++) {
      final left = plot.left + band * i + (band - group) / 2;
      if (showMissingMarkers && series.every((s) => s.values[i] == null)) {
        final marker = TextPainter(
          text: TextSpan(
            text: '—',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        marker.paint(
          canvas,
          Offset(
            plot.left + band * (i + .5) - marker.width / 2,
            zeroY - marker.height - 3,
          ),
        );
      }
      for (var s = 0; s < k; s++) {
        final v = series[s].values[i];
        if (v == null) continue;
        final y = plot.bottom - scale.fraction(v) * plot.height;
        final x = left + s * (bar + _gap);
        final rect = Rect.fromLTRB(
          x,
          math.min(y, zeroY),
          x + bar,
          math.max(y, zeroY),
        );
        // 값 쪽 끝만 둥글게, 기준선 쪽은 각지게.
        final rrect = v >= 0
            ? RRect.fromRectAndCorners(
                rect,
                topLeft: _radius,
                topRight: _radius,
              )
            : RRect.fromRectAndCorners(
                rect,
                bottomLeft: _radius,
                bottomRight: _radius,
              );
        canvas.drawRRect(rrect, Paint()..color = series[s].color);
      }
    }
  }
}

/// One column series on the left axis and lines sharing one right axis.
/// Extra monetary series are shown only in the shared period tooltip.
class AppComboChart extends _CategoryChart {
  AppComboChart({
    super.key,
    required super.categories,
    required this.columnSeries,
    required this.lineSeries,
    this.additionalLineSeries = const [],
    required super.formatValue,
    required this.formatLineValue,
    this.extraTooltipSeries = const [],
    super.height = 260,
  }) : super(series: [columnSeries, lineSeries, ...additionalLineSeries]);

  final ChartSeries columnSeries;
  final ChartSeries lineSeries;
  final List<ChartSeries> additionalLineSeries;
  List<ChartSeries> get lineSeriesList => [lineSeries, ...additionalLineSeries];
  final List<ChartSeries> extraTooltipSeries;
  final String Function(double value) formatLineValue;

  @override
  bool get includeZero => true;

  @override
  List<ChartSeries> get scaleSeries => [columnSeries];

  @override
  ChartSeries? get secondarySeries =>
      lineSeriesList.any((s) => s.values.any((v) => v != null && v.isFinite))
      ? ChartSeries(
          label: lineSeries.label,
          color: lineSeries.color,
          values: [for (final s in lineSeriesList) ...s.values],
        )
      : null;

  @override
  String formatSecondary(double value) => formatLineValue(value);

  @override
  List<({String label, Color color, String value})> tooltipRows(int index) => [
    for (final s in [columnSeries, ...extraTooltipSeries, ...lineSeriesList])
      (
        label: s.label,
        color: s.color,
        value: s.values[index] == null
            ? '—'
            : lineSeriesList.contains(s)
            ? formatLineValue(s.values[index]!)
            : formatValue(s.values[index]!),
      ),
  ];

  @override
  void paintMarks(
    Canvas canvas,
    Rect plot,
    ChartScale scale,
    int? hovered,
    AppColors colors,
  ) {
    AppColumnChart(
      categories: categories,
      series: [columnSeries],
      formatValue: formatValue,
    ).paintMarks(canvas, plot, scale, hovered, colors);
    final line = secondarySeries;
    if (line != null) {
      AppLineChart.many(
        categories: categories,
        series: lineSeriesList,
        formatValue: formatLineValue,
      ).paintMarks(
        canvas,
        plot,
        ChartScale.of(line.values.nonNulls),
        hovered,
        colors,
      );
    }
  }
}

/// 범주별 꺾은선 (계열 하나). 없는 값에서는 선을 끊는다.
class AppLineChart extends _CategoryChart {
  AppLineChart({
    super.key,
    required super.categories,
    super.formatCategory,
    super.maxAxisLabels,
    required ChartSeries series,
    required super.formatValue,
    super.height = 140,
    this.includeZeroBaseline = true,
  }) : super(series: [series]);

  /// 선을 여러 개 (이익률·순이익률·ROE처럼 단위가 같은 것끼리).
  const AppLineChart.many({
    super.key,
    required super.categories,
    super.formatCategory,
    super.maxAxisLabels,
    required super.series,
    required super.formatValue,
    super.height = 140,
    this.includeZeroBaseline = true,
  });

  final bool includeZeroBaseline;

  /// 이보다 점이 많으면 점을 찍지 않는다.
  static const _maxDots = 60;

  @override
  bool get includeZero => includeZeroBaseline;

  @override
  void paintMarks(
    Canvas canvas,
    Rect plot,
    ChartScale scale,
    int? hovered,
    AppColors colors,
  ) {
    final n = categories.length;
    final band = plot.width / n;
    Offset? pointOf(ChartSeries s, int i) {
      final v = s.values[i];
      if (v == null) return null;
      return Offset(
        plot.left + band * (i + 0.5),
        plot.bottom - scale.fraction(v) * plot.height,
      );
    }

    for (final s in series) {
      final line = Paint()
        ..color = s.color
        ..strokeWidth = s.isDashed ? 3 : 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      var open = false;
      for (var i = 0; i < n; i++) {
        final p = pointOf(s, i);
        if (p == null) {
          open = false;
          continue;
        }
        open ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
        open = true;
      }
      if (s.isDashed) {
        final halo = Paint()
          ..color = colors.background
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
        for (final metric in path.computeMetrics()) {
          for (var start = 0.0; start < metric.length; start += 16) {
            final dash = metric.extractPath(
              start,
              math.min(start + 10, metric.length),
            );
            canvas.drawPath(dash, halo);
            canvas.drawPath(dash, line);
          }
        }
      } else {
        canvas.drawPath(path, line);
      }
    }

    if (hovered != null) {
      final x = plot.left + band * (hovered + 0.5);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = colors.textMuted
          ..strokeWidth = 1,
      );
    }
    // 점은 선이 하나이고 범주가 적을 때만 (주가처럼 촘촘하면 선만 그린다).
    if (series.length == 1 && n <= _maxDots) {
      for (var i = 0; i < n; i++) {
        final p = pointOf(series.first, i);
        if (p == null) continue;
        final r = i == hovered ? 5.0 : 4.0;
        canvas.drawCircle(p, r + 2, Paint()..color = colors.surface);
        canvas.drawCircle(p, r, Paint()..color = series.first.color);
      }
    }
  }
}

/// Reserve the rendered tick width, including sign, separators and unit.
/// Extremely long labels are ellipsized within this gutter by the painter.
double chartAxisWidth(
  Iterable<String> labels,
  TextStyle style, {
  required double maxWidth,
}) {
  var width = 56.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    width = math.max(width, painter.width);
    painter.dispose();
  }
  return math.min(width.ceilToDouble() + 8, math.max(0, maxWidth));
}
