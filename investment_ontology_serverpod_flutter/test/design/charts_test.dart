import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/charts/app_treemap.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/charts/chart_scale.dart';

void main() {
  group('squarify', () {
    const bounds = Rect.fromLTWH(0, 0, 600, 400);

    test('면적은 값에 비례하고 전체를 빈틈없이 덮는다', () {
      final values = <double>[6, 6, 4, 3, 2, 2, 1];
      final rects = squarify(values, bounds);
      final total = values.reduce((a, b) => a + b);

      var area = 0.0;
      for (final (i, r) in rects.indexed) {
        expect(r.width * r.height, closeTo(values[i] / total * 240000, 1e-6));
        expect(bounds.inflate(1e-6).contains(r.topLeft), isTrue);
        expect(bounds.inflate(1e-6).contains(r.bottomRight), isTrue);
        area += r.width * r.height;
      }
      expect(area, closeTo(240000, 1e-6));
      // 서로 겹치지 않는다.
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          final overlap = rects[i].intersect(rects[j]);
          expect(overlap.width <= 1e-6 || overlap.height <= 1e-6, isTrue);
        }
      }
    });

    test('가로세로비가 나쁜 긴 막대를 만들지 않는다', () {
      final rects = squarify(<double>[6, 6, 4, 3, 2, 2, 1], bounds);
      for (final r in rects) {
        final ratio = r.width > r.height
            ? r.width / r.height
            : r.height / r.width;
        expect(ratio, lessThan(4));
      }
    });

    test('합이 0이거나 0 이하 값은 빈 사각형', () {
      expect(squarify([0, 0], bounds), [Rect.zero, Rect.zero]);
      final rects = squarify([5, 0], bounds);
      expect(rects[1].width * rects[1].height, 0);
    });
  });

  group('ChartScale', () {
    test('0을 포함하고 깔끔한 눈금', () {
      final s = ChartScale.of([12, 87]);
      expect(s.min, 0);
      expect(s.max, 100);
      expect(s.ticks, [0, 20, 40, 60, 80, 100]);
    });

    test('음수 범위', () {
      final s = ChartScale.of([-30, 45]);
      expect(s.min, lessThanOrEqualTo(-30));
      expect(s.max, greaterThanOrEqualTo(45));
      expect(s.ticks, contains(0));
      expect(s.fraction(s.min), 0);
      expect(s.fraction(s.max), 1);
    });
  });

  test('0을 빼면 값 범위만 덮는다 (주가처럼 0에서 먼 값)', () {
    final scale = ChartScale.of(
      const [95000, 245000, 104900],
      includeZero: false,
    );
    expect(scale.min, greaterThan(0));
    expect(scale.min, lessThanOrEqualTo(95000));
    expect(scale.max, greaterThanOrEqualTo(245000));
    expect(scale.ticks.first, scale.min);
  });
}
