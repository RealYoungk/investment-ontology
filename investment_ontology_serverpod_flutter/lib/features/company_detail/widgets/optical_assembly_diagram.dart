import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// Original schematic of optical assembly, not a machine/product photograph.
class OpticalAssemblyDiagram extends StatefulWidget {
  const OpticalAssemblyDiagram({super.key});
  @override
  State<OpticalAssemblyDiagram> createState() => _OpticalAssemblyDiagramState();
}

class _OpticalAssemblyDiagramState extends State<OpticalAssemblyDiagram> {
  int stage = 0;
  static const titles = ['위치 맞추기', '고정하기', '검사하기'];
  static const captions = [
    '렌즈·광섬유를 미세하게 움직여 빛이 잘 들어가는 위치를 찾습니다.',
    '렌즈·광섬유를 받치는 홀더를 바닥에 고정합니다. 강조된 부분이 접합부입니다.',
    '광섬유로 전달되는 빛을 측정해 조립 상태를 확인합니다.',
  ];
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '광통신 부품 안에서 빛이 지나가는 길',
            style: t.body(15, weight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '송신부 개념도 · 아래 단계를 눌러 보세요',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              for (final label in ['빛을 내는 칩', '빛을 모으는 렌즈', '빛을 보내는 광섬유'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: t.body(12, weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 160,
            child: CustomPaint(painter: _OpticalPainter(c, stage)),
          ),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (var i = 0; i < titles.length; i++)
                ChoiceChip(
                  label: Text('${i + 1} ${titles[i]}'),
                  selected: stage == i,
                  onSelected: (_) => setState(() => stage = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(captions[stage], style: t.body(14).copyWith(height: 1.6)),
          const SizedBox(height: AppSpace.sm),
          Text(
            'ADS테크가 파는 것: 이 작업을 수행하는 정밀 장비',
            style: t.body(13, color: c.accent, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OpticalPainter extends CustomPainter {
  _OpticalPainter(this.colors, this.stage);
  final AppColors colors;
  final int stage;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final chip = w / 6, lens = w / 2, fiber = w * 5 / 6;
    const y = 76.0;
    final stroke = Paint()
      ..color = colors.textSecondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final beam = Paint()
      ..color = colors.chartSeries2
      ..strokeWidth = 3;
    // Shared assembly base, with three distinct optical components.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 111, w - 12, 16),
        const Radius.circular(4),
      ),
      Paint()..color = colors.border,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(chip, y), width: 42, height: 34),
        const Radius.circular(4),
      ),
      Paint()..color = colors.chartSeries1,
    );
    canvas.drawRect(
      Rect.fromLTWH(chip - 17, 94, 34, 17),
      Paint()..color = colors.borderStrong,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lens, y), width: 19, height: 57),
      Paint()..color = colors.accentSubtle,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lens, y), width: 19, height: 57),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fiber - 19, y - 9, w - fiber + 13, 18),
        const Radius.circular(6),
      ),
      Paint()..color = colors.chartSeries1,
    );
    for (final dy in [-10.0, 0.0, 10.0]) {
      canvas.drawLine(Offset(chip + 21, y), Offset(lens, y + dy), beam);
      canvas.drawLine(Offset(lens, y + dy), Offset(fiber - 19, y), beam);
    }
    canvas.drawLine(Offset(fiber - 19, y), Offset(w - 6, y), beam);
    // Leader lines connect the normal Flutter labels to the actual components.
    for (final x in [chip, lens, fiber]) {
      canvas.drawLine(Offset(x, 8), Offset(x, 38), stroke);
    }
    // Holders physically connect each optical component to the assembly base.
    final holder = Paint()..color = colors.borderStrong;
    canvas.drawRect(Rect.fromLTWH(lens - 8, 101, 16, 10), holder);
    canvas.drawRect(Rect.fromLTWH(fiber - 8, 85, 16, 26), holder);
    for (final x in [lens, fiber]) {
      canvas.drawRect(Rect.fromLTWH(x - 16, 106, 32, 5), holder);
    }
    if (stage == 0) {
      final move = Paint()
        ..color = colors.marketDown
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(lens, y), 39, move);
      canvas.drawLine(Offset(lens - 27, 22), Offset(lens + 27, 22), move);
      for (final direction in [-1.0, 1.0]) {
        final x = lens + direction * 27;
        canvas.drawLine(Offset(x, 22), Offset(x - direction * 7, 16), move);
        canvas.drawLine(Offset(x, 22), Offset(x - direction * 7, 28), move);
      }
    } else if (stage == 1) {
      for (final x in [lens, fiber]) {
        canvas.drawRect(
          Rect.fromLTWH(x - 17, 106, 34, 5),
          Paint()..color = colors.chartSeries2,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 108), width: 48, height: 22),
          Paint()
            ..color = colors.marketDown
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    } else {
      final meter = Rect.fromLTWH(fiber - 27, 15, 54, 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(meter, const Radius.circular(5)),
        Paint()..color = colors.surface,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(meter, const Radius.circular(5)),
        stroke,
      );
      final path = Path()
        ..moveTo(fiber - 19, 36)
        ..lineTo(fiber - 10, 36)
        ..lineTo(fiber - 4, 24)
        ..lineTo(fiber + 4, 36)
        ..lineTo(fiber + 19, 36);
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.success
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(Offset(fiber, 45), Offset(fiber, y - 9), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _OpticalPainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.colors != colors;
}
