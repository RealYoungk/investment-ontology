import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// Original schematic, drawn from component relationships, not traced artwork.
/// Labels are real Flutter text, so they remain readable on narrow screens.
class PackageStructureDiagram extends StatelessWidget {
  const PackageStructureDiagram({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;
        final labelWidth = narrow ? 145.0 : 230.0;
        final drawingWidth = constraints.maxWidth - labelWidth;
        return Semantics(
          label: '자체 제작 구조 개념도. 위에서부터 IC 반도체 칩, 패키지 기판의 구리 배선, 솔더볼 접점, 메인보드가 연결됩니다. 빨간 안내선이 각 부품을 가리킵니다.',
          child: SizedBox(
            height: 332,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _PackagePainter(c, drawingWidth)),
                ),
                for (final item in [
                  (
                    22.0,
                    'IC = 반도체 칩',
                    '집적회로(Integrated Circuit)\nCPU처럼 연산 등을 담당',
                  ),
                  (111.0, '패키지 기판', '칩과 보드를 잇는 회로판\n안쪽 선 = 구리 배선'),
                  (207.0, '솔더볼 = 연결 접점', '기판 아래 둥근 금속\n메인보드와 전기적으로 연결'),
                  (279.0, '메인보드', '여러 부품을 연결하는 큰 판'),
                ])
                  Positioned(
                    left: drawingWidth + 8,
                    top: item.$1,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: t.body(
                            narrow ? 12 : 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: t
                              .body(narrow ? 11 : 13, color: c.textSecondary)
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackagePainter extends CustomPainter {
  _PackagePainter(this.c, this.w);
  final AppColors c;
  final double w;
  @override
  void paint(Canvas canvas, Size size) {
    final left = w * .07, right = w * .82;
    void box(Rect rect, Color color) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = color,
    );
    void line(Offset a, Offset b, Color color, double width) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
    // Chip and small chip-to-substrate bumps.
    box(Rect.fromLTRB(w * .25, 38, w * .65, 75), c.inverse);
    for (var i = 0; i < 4; i++) {
      final x = w * (.3 + i * .1);
      line(Offset(x, 75), Offset(x, 100), c.borderStrong, 4);
    }
    box(Rect.fromLTRB(left, 100, right, 183), c.accentSubtle);
    // Staggered routing is symbolic; not a manufacturer's stack-up/layout.
    for (var i = 0; i < 3; i++) {
      final y = 116.0 + i * 25;
      line(Offset(left + 5, y), Offset(right - 5, y), c.chartSeries2, 3);
      final x = w * (.25 + i * .16);
      line(Offset(x, y), Offset(x, y + 25), c.chartSeries2, 3);
    }
    for (var i = 0; i < 4; i++) {
      final x = w * (.17 + i * .19);
      line(Offset(x, 183), Offset(x, 224), c.borderStrong, 2);
      canvas.drawCircle(Offset(x, 214), 7, Paint()..color = c.borderStrong);
      line(Offset(x, 224), Offset(x, 284), c.borderStrong, 1);
    }
    box(Rect.fromLTRB(left, 284, right, 308), c.chartSeries1);
    // Red leader lines end at exact components, rather than referring to colors.
    for (final pair in [
      (Offset(w * .48, 55), 32.0),
      (Offset(w * .48, 145), 121.0),
      (Offset(w * .55, 214), 218.0),
      (Offset(w * .48, 295), 289.0),
    ]) {
      final p = Paint()
        ..color = c.marketUp
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(pair.$1.dx, pair.$1.dy)
          ..lineTo(w * .9, pair.$1.dy)
          ..lineTo(w * .96, pair.$2)
          ..lineTo(w + 3, pair.$2),
        p,
      );
      canvas.drawCircle(pair.$1, 3, Paint()..color = c.marketUp);
    }
  }

  @override
  bool shouldRepaint(covariant _PackagePainter old) => old.c != c || old.w != w;
}

class RepairPrincipleDiagram extends StatelessWidget {
  const RepairPrincipleDiagram({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: CustomPaint(
      painter: _RepairPainter(context.colors),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final label in ['수리 전 · 구리 돌출', '수리 후 · 돌출 제거'])
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.typo.body(12, weight: FontWeight.w600),
              ),
            ),
        ],
      ),
    ),
  );
}

class _RepairPainter extends CustomPainter {
  _RepairPainter(this.c);
  final AppColors c;
  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    for (var side = 0; side < 2; side++) {
      final x = side * half;
      final p = Paint()
        ..color = c.chartSeries2
        ..strokeWidth = 12;
      for (var i = 0; i < 3; i++) {
        final y = 62.0 + i * 40;
        canvas.drawLine(Offset(x + 16, y), Offset(x + half - 16, y), p);
      }
      if (side == 0) {
        canvas.drawPath(
          Path()
            ..moveTo(x + half * .43, 102)
            ..lineTo(x + half * .6, 123)
            ..lineTo(x + half * .67, 102)
            ..close(),
          Paint()..color = c.marketUp,
        );
      }
      canvas.drawCircle(
        Offset(x + half * .55, 110),
        24,
        Paint()
          ..color = c.marketUp
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RepairPainter old) => old.c != c;
}
