import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/today_home_review.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('adaptive home scenarios and preferences at $width', (t) async {
      t.view.physicalSize = Size(width, 1050);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(serviceBrand),
            home: const TodayHomeReview(),
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final label in ['발표 전', '발표 후', '큰 발표 없는 날']) {
        await t.ensureVisible(find.text(label));
        await t.tap(find.text(label));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      await t.tap(find.text('자료 확인 지연'));
      await t.pumpAndSettle();
      expect(find.text('최근 수집 실패 · 이전 관측값 유지'), findsNWidgets(2));
      await t.ensureVisible(find.text('관심사 편집'));
      await t.tap(find.text('관심사 편집'));
      await t.pumpAndSettle();
      await t.tap(find.text('모두 해제'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ShadButton, '취소'));
      await t.pumpAndSettle();
      expect(find.text('반도체'), findsOneWidget);
      await t.tap(find.text('관심사 편집'));
      await t.pumpAndSettle();
      await t.tap(find.text('모두 해제'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ShadButton, '적용'));
      await t.pumpAndSettle();
      expect(find.text('관심사를 고르면 관련 업데이트를 모아드립니다.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
