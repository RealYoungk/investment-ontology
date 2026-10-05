import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shad/shad.dart';

import '../../design/tokens.dart';

/// Scroll-driven illustration, drawn locally without media or network requests.
/// Nodes describe information categories, never actual company relationships.
class IntroMotionSurface extends StatelessWidget {
  const IntroMotionSurface({
    super.key,
    required this.progress,
    required this.reduced,
  });

  final double progress;
  final bool reduced;
  static const _labels = ['공시', '실적', '사업', '고객', '공급', '경쟁'];
  static const _icons = [
    LucideIcons.fileText,
    LucideIcons.chartLine,
    LucideIcons.store,
    LucideIcons.users,
    LucideIcons.truck,
    LucideIcons.layers,
  ];
  static const _scattered = [
    Offset(.37, .12),
    Offset(.78, .24),
    Offset(.82, .70),
    Offset(.57, .88),
    Offset(.16, .79),
    Offset(.18, .38),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = reduced ? 1.0 : progress.clamp(0.0, 1.0);
    final gather = Curves.easeInOutCubic.transform((p / .62).clamp(0.0, 1.0));
    final reveal = ((p - .12) / .38).clamp(0.0, 1.0);
    return ColoredBox(
      color: c.accentSubtle,
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 600;
          final width = compact ? 76.0 : 116.0;
          final height = compact ? 64.0 : 86.0;
          final size = Size(box.maxWidth, box.maxHeight);
          final center = Offset(size.width / 2, size.height / 2);
          final positions = List.generate(_labels.length, (i) {
            final angle = -math.pi / 2 + i * math.pi / 3;
            final target = Offset(
              .5 + .34 * math.cos(angle),
              .5 + .34 * math.sin(angle),
            );
            final point = Offset.lerp(_scattered[i], target, gather)!;
            return Offset(point.dx * size.width, point.dy * size.height);
          });
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _Connections(
                    positions: positions,
                    center: center,
                    colors: c,
                    progress: p,
                    reveal: reveal,
                  ),
                ),
              ),
              for (var i = 0; i < positions.length; i++)
                Positioned(
                  left: positions[i].dx - width / 2,
                  top: positions[i].dy - height / 2,
                  width: width,
                  height: height,
                  child: Transform.rotate(
                    angle: (1 - gather) * (i.isEven ? -.12 : .10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.surface, c.accentSubtle],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.accent.withValues(alpha: .10),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        borderRadius: context.shape.borderRadius,
                        border: Border.all(color: c.borderStrong),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icons[i],
                            size: compact ? 17 : 22,
                            color: c.accent,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _labels[i],
                            style: context.typo.body(
                              compact ? 12 : 15,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 7),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var j = 0; j < 3; j++)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 3),
                                    child: Container(
                                      width: 9.0 + ((i + j) % 3) * 5,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: c.accent.withValues(alpha: .20),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: center.dx - width / 2,
                top: center.dy - height / 2,
                width: width,
                height: height,
                child: Opacity(
                  opacity: reveal,
                  child: Transform.scale(
                    scale: .8 + .2 * reveal,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: context.shape.borderRadius,
                        border: Border.all(color: c.accent, width: 2),
                      ),
                      child: Text(
                        '기업',
                        style: context.typo.body(
                          compact ? 15 : 20,
                          weight: FontWeight.w700,
                          color: c.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Connections extends CustomPainter {
  const _Connections({
    required this.positions,
    required this.center,
    required this.colors,
    required this.progress,
    required this.reveal,
  });
  final List<Offset> positions;
  final Offset center;
  final AppColors colors;
  final double progress;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) * .34;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.accent.withValues(alpha: .13 * reveal),
          colors.accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, halo);
    // Quiet technical grid, with emphasis around the emerging company.
    for (double x = 12; x < size.width; x += 28) {
      for (double y = 12; y < size.height; y += 28) {
        canvas.drawCircle(
          Offset(x, y),
          .8,
          Paint()..color = colors.accent.withValues(alpha: .07),
        );
      }
    }
    for (var ring = 0; ring < 3; ring++) {
      final r = radius * (.42 + ring * .23);
      final pen = Paint()
        ..color = colors.accent.withValues(alpha: (.14 - ring * .025) * reveal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, r, pen);
      final orbit = Paint()
        ..color = colors.accent.withValues(alpha: .45 * reveal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        progress * math.pi * (ring.isEven ? 2 : -2) + ring * 1.9,
        .35 + .30 * reveal,
        false,
        orbit,
      );
    }
    for (var i = 0; i < positions.length; i++) {
      final direction = center - positions[i];
      final bend =
          Offset(-direction.dy, direction.dx) * (i.isEven ? .16 : -.16);
      final path = Path()
        ..moveTo(positions[i].dx, positions[i].dy)
        ..quadraticBezierTo(
          (positions[i].dx + center.dx) / 2 + bend.dx,
          (positions[i].dy + center.dy) / 2 + bend.dy,
          center.dx,
          center.dy,
        );
      final metric = path.computeMetrics().first;
      final draw = ((progress - .12 - i * .025) / .40).clamp(0.0, 1.0);
      if (draw == 0) continue;
      final line = Paint()
        ..color = colors.accent.withValues(alpha: .35 * reveal)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawPath(metric.extractPath(0, metric.length * draw), line);
      final phase = (progress * 2.5 + i / positions.length) % 1;
      // A short luminous trail moves along each curved source connection.
      final distance = metric.length * phase * draw;
      final trail = Paint()
        ..color = colors.accent.withValues(alpha: .75 * reveal)
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        metric.extractPath(math.max(0, distance - 22), distance),
        trail,
      );
      final point = metric.getTangentForOffset(distance)!.position;
      canvas.drawCircle(
        point,
        7,
        Paint()..color = colors.accent.withValues(alpha: .08 * reveal),
      );
      canvas.drawCircle(
        point,
        2.8,
        Paint()..color = colors.accent.withValues(alpha: reveal),
      );
    }
    final network = ((progress - .65) / .35).clamp(0.0, 1.0);
    if (network > 0) {
      for (var i = 0; i < positions.length; i++) {
        final start = positions[i];
        final end = positions[(i + 1) % positions.length];
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            center.dx + (start.dx + end.dx - center.dx * 2) * .62,
            center.dy + (start.dy + end.dy - center.dy * 2) * .62,
            end.dx,
            end.dy,
          );
        final metric = path.computeMetrics().first;
        canvas.drawPath(
          metric.extractPath(0, metric.length * network),
          Paint()
            ..color = colors.accent.withValues(alpha: .15 * network)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Connections old) =>
      old.progress != progress ||
      old.colors != colors ||
      old.center != center ||
      old.reveal != reveal;
}
