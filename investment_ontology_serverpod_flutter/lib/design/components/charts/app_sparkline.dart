import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact shape overview. Per-series scale; gaps stay disconnected.
/// Provide the period and unit in [description] beside the full chart entry.
class AppSparkline extends StatelessWidget {
  const AppSparkline({
    super.key,
    required this.values,
    required this.color,
    required this.description,
    this.height = 42,
    this.fill = false,
  });
  final List<double?> values;
  final Color color;
  final String description;
  final double height;
  final bool fill;
  @override
  Widget build(BuildContext context) => Semantics(
    label: description,
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values, color, fill)),
      ),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.fill);
  final List<double?> values;
  final Color color;
  final bool fill;
  @override
  void paint(Canvas canvas, Size size) {
    final valid = values.whereType<double>().where((v) => v.isFinite).toList();
    if (valid.isEmpty || size.width <= 0 || size.height <= 0) return;
    final lo = valid.reduce(math.min), hi = valid.reduce(math.max);
    final span = hi - lo;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final segments = <List<Offset>>[];
    var segment = <Offset>[];
    Offset? previous;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null || !value.isFinite) {
        if (segment.isNotEmpty) segments.add(segment);
        segment = <Offset>[];
        previous = null;
        continue;
      }
      final x = values.length < 2
          ? size.width / 2
          : 2 + (size.width - 4) * i / (values.length - 1);
      final y = span == 0
          ? size.height / 2
          : 4 + (size.height - 8) * (hi - value) / span;
      final point = Offset(x, y);
      segment.add(point);
      if (previous != null) canvas.drawLine(previous, point, paint);
      // Isolated observations remain visible, without inventing a segment.
      canvas.drawCircle(point, 1, Paint()..color = color);
      previous = point;
    }
    if (segment.isNotEmpty) segments.add(segment);
    if (fill) {
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .14), color.withValues(alpha: .01)],
        ).createShader(Offset.zero & size);
      for (final points in segments.where((s) => s.length > 1)) {
        final path = Path()..moveTo(points.first.dx, size.height);
        for (final point in points) {
          path.lineTo(point.dx, point.dy);
        }
        path.lineTo(points.last.dx, size.height);
        path.close();
        canvas.drawPath(path, areaPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color || old.fill != fill;
}
