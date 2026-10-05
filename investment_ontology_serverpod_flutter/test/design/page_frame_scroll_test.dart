import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/page_frame.dart';

class _CountingPainter extends CustomPainter {
  int paints = 0;
  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(covariant _CountingPainter oldDelegate) => false;
}

void main() {
  testWidgets(
    'scrolling reuses section paint and preserves controller position',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final painter = _CountingPainter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageFrame(
              controller: controller,
              children: [
                SizedBox(
                  height: 300,
                  child: CustomPaint(painter: painter),
                ),
                for (var i = 0; i < 12; i++)
                  SizedBox(height: 200, child: Text('Section $i')),
              ],
            ),
          ),
        ),
      );
      final initialPaints = painter.paints;
      expect(initialPaints, greaterThan(0));
      controller.jumpTo(80);
      await tester.pump();
      controller.jumpTo(160);
      await tester.pump();
      expect(controller.offset, 160);
      expect(painter.paints, initialPaints);
    },
  );
}
