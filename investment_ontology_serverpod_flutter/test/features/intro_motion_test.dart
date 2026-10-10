import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/intro_motion_surface.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/intro_film.dart';

import '../support/shad_test_host.dart';
import 'home_page_test.dart' show theme;

void main() {
  test('completed scenes hold before the next transition', () {
    expect(introMotionProgress(.05), 0);
    expect(introMotionProgress(.14), 0);
    expect(introMotionProgress(.40), closeTo(.62, 1e-9));
    expect(introMotionProgress(.50), .62);
    expect(introMotionProgress(.60), .62);
    expect(introMotionProgress(.84), 1);
    expect(introMotionProgress(.95), 1);
    for (var i = 1; i <= 100; i++) {
      expect(
        introMotionProgress(i / 100),
        greaterThanOrEqualTo(introMotionProgress((i - 1) / 100)),
      );
    }
  });
  testWidgets('motion paints immediately at each stage without media widgets', (
    tester,
  ) async {
    for (final width in [280.0, 720.0, 1200.0]) {
      for (final progress in [0.0, .45, 1.0]) {
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    height: 300,
                    child: IntroMotionSurface(
                      progress: progress,
                      reduced: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('공시'), findsOneWidget);
        expect(find.text('경쟁'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(find.byType(HtmlElementView), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('reduced motion presents the connected state without waiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: SizedBox(
              height: 300,
              child: IntroMotionSurface(progress: 0, reduced: true),
            ),
          ),
        ),
      ),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('scroll advances chapters and keeps one scroll owner', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: IntroFilm(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('흩어진 정보.'), findsOneWidget);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('연결된 이해.'), findsOneWidget);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.byType(HtmlElementView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
