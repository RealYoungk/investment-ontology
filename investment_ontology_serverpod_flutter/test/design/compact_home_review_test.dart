import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/compact_home_review.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 950.0, 1050.0, 1440.0]) {
    testWidgets('overview fits and key controls work at $width', (t) async {
      t.view.physicalSize = Size(width, 1050);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(serviceBrand),
            home: const CompactHomeReview(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      if (width < 1100) {
        expect(find.text('메뉴'), findsOneWidget);
        await t.tap(find.text('메뉴'));
        await t.pumpAndSettle();
        expect(find.text('홈 · 현재'), findsOneWidget);
        expect(find.text('관계망'), findsOneWidget);
        await t.tap(find.text('메뉴 닫기'));
        await t.pumpAndSettle();
        expect(find.text('홈 · 현재'), findsNothing);
      } else {
        expect(find.text('메뉴'), findsNothing);
        expect(find.text('관계망'), findsOneWidget);
      }

      final calendarRows = [
        '미국 정책금리 결정',
        '미국 소비자물가',
        '국내 수출 통계',
      ].map((title) => find.byKey(ValueKey('overview-row-$title')));
      final rowHeights = calendarRows
          .map((row) => t.getSize(row).height)
          .toSet();
      expect(
        rowHeights.length,
        1,
        reason: 'Calendar rows keep equal height across wrapping',
      );
      final headerPosition = t.getTopLeft(
        find.byKey(const ValueKey('fixed-navigation-header')),
      );
      await t.ensureVisible(find.text('1년'));
      expect(
        t.getTopLeft(find.byKey(const ValueKey('fixed-navigation-header'))),
        headerPosition,
      );
      await t.tap(find.text('1년'));
      await t.pumpAndSettle();
      expect(find.text('선택 기간 시작=100 · 같은 기간의 변화 비교 · 합성'), findsOneWidget);
      await t.ensureVisible(find.byType(ShadInput));
      await t.enterText(find.byType(EditableText), '없는기업');
      await t.pumpAndSettle();
      expect(find.text('일치하는 관심기업이 없습니다.'), findsOneWidget);
      await t.enterText(find.byType(EditableText), '새봄');
      await t.pumpAndSettle();
      expect(find.text('가상기업 새봄'), findsOneWidget);
      expect(find.text('가상기업 한빛'), findsNothing);
      await t.enterText(find.byType(EditableText), '');
      await t.pumpAndSettle();
      await t.ensureVisible(find.widgetWithText(ShadToggle, '정정'));
      await t.tap(find.widgetWithText(ShadToggle, '정정'));
      await t.pumpAndSettle();
      expect(find.text('가상기업 한빛 · 반기보고서'), findsNothing);
      expect(find.text('가상기업 새봄 · 정정 반기보고서'), findsOneWidget);
      await t.ensureVisible(find.text('관심 설정'));
      await t.tap(find.text('관심 설정'));
      await t.pumpAndSettle();
      await t.tap(find.text('관심기업 없는 상태 보기'));
      await t.pumpAndSettle();
      expect(find.text('관심기업을 담으면 시세와 새 공시를 함께 볼 수 있습니다.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
