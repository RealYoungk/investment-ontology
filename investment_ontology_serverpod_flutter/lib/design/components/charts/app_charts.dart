import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens.dart';
import 'chart_scale.dart';

/// 차트 계열 하나. [values]는 [AppColumnChart.categories]와 같은 순서, 없는 값은 null.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double?> values;
}

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
  });

  final List<String> categories;
  final String Function(String)? formatCategory;
  final int? maxAxisLabels;
  final List<ChartSeries> series;

  /// 눈금·툴팁 값 표시.
  final String Function(double value) formatValue;
  final double height;

  bool get includeZero;

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
  static const _axisWidth = 64.0;
  static const _labelHeight = 22.0;

  int? _hovered;
  Offset? _pointer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final values = [
      for (final s in widget.series)
        for (final v in s.values) ?v,
    ];
    final scale = ChartScale.of(values, includeZero: widget.includeZero);
    final n = widget.categories.length;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plot = Rect.fromLTWH(
            _axisWidth,
            8,
            math.max(0, constraints.maxWidth - _axisWidth),
            math.max(0, widget.height - _labelHeight - 8),
          );
          int? indexAt(Offset p) {
            if (n == 0 || p.dx < plot.left || p.dx > plot.right) return null;
            return ((p.dx - plot.left) / plot.width * n).floor().clamp(
              0,
              n - 1,
            );
          }

          final hovered = _hovered;
          return MouseRegion(
            onHover: (e) => setState(() {
              _hovered = indexAt(e.localPosition);
              _pointer = e.localPosition;
            }),
            onExit: (_) => setState(() => _hovered = null),
            child: GestureDetector(
              // 터치에서는 누른 범주를 보여준다.
              onTapDown: (d) => setState(() {
                _hovered = indexAt(d.localPosition);
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
                        tickStyle: t.numeric(10.5, color: c.textMuted),
                        labelStyle: t.body(11.5, color: c.textSecondary),
                      ),
                    ),
                  ),
                  if (hovered != null && _pointer != null)
                    _tooltip(context, constraints.maxWidth, plot, hovered),
                ],
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
                style: t.body(12, color: c.onInverse, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              for (final s in widget.series)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.label,
                          style: t.body(11.5, color: c.onInverse),
                        ),
                      ),
                      Text(
                        s.values[index] == null
                            ? '—'
                            : widget.formatValue(s.values[index]!),
                        style: t.numeric(11.5, color: c.onInverse),
                      ),
                    ],
                  ),
                ),
            ],
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
      final tp = _text(chart.formatValue(tick), tickStyle);
      tp.paint(canvas, Offset(plot.left - 8 - tp.width, y - tp.height / 2));
    }

    // 범주 이름: 겹치면 건너뛰며 쓴다.
    final painters = [
      for (final c in chart.categories)
        _text(chart.formatCategory?.call(c) ?? c, labelStyle),
    ];
    final widest = painters.fold(0.0, (w, p) => math.max(w, p.width));
    final every = math.max(
      chart.maxAxisLabels == null ? 1 : (n / chart.maxAxisLabels!).ceil(),
      ((widest + 16) / band).ceil(),
    );
    for (var i = 0; i < n; i++) {
      if ((n - 1 - i) % every != 0) continue;
      final p = painters[i];
      p.paint(
        canvas,
        Offset(
          (plot.left + band * (i + 0.5) - p.width / 2).clamp(
            plot.left,
            plot.right - p.width,
          ),
          plot.bottom + 6,
        ),
      );
    }

    chart.paintMarks(canvas, plot, scale, hovered, colors);
  }

  static TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.chart != chart ||
      old.plot != plot ||
      old.hovered != hovered ||
      old.colors != colors;
}

/// 범주별 세로 막대. 계열이 여러 개면 나란히 놓는다. 음수는 기준선 아래로 그린다.
class AppColumnChart extends _CategoryChart {
  const AppColumnChart({
    super.key,
    required super.categories,
    required super.series,
    required super.formatValue,
    super.height = 200,
  });

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
        ..strokeWidth = 2
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
      canvas.drawPath(path, line);
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
