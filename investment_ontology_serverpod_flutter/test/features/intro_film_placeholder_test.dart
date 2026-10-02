import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/home/intro_film_placeholder.dart';

import 'home_page_test.dart' show theme;

void main() {
  testWidgets('영상 대기는 영역 안에 표시하고 탐색 버튼은 사용할 수 있다', (tester) async {
    var navigated = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => navigated = true,
                child: const Text('시작하기'),
              ),
              const Expanded(child: IntroFilmPlaceholder(failed: false)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('소개 영상을 준비하고 있어요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    expect(navigated, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('영상 실패 시 무한 로딩 대신 미리보기와 안내를 유지한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: IntroFilmPlaceholder(failed: true)),
      ),
    );
    expect(find.text('영상 대신 미리보기를 표시하고 있어요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
