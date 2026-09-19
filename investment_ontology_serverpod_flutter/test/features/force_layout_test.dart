import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/graph/force_layout.dart';

void main() {
  test('가운데 노드는 한가운데, 나머지는 화면 안에서 서로 떨어져 있다', () {
    final pos = forceLayout(
      nodes: ['a', 'b', 'c', 'd'],
      depth: {'a': 0, 'b': 1, 'c': 1, 'd': 2},
      edges: [('a', 'b'), ('a', 'c'), ('c', 'd')],
      center: 'a',
      size: const Size(800, 600),
    );
    expect(pos['a'], const Offset(400, 300));
    for (final p in pos.values) {
      expect(p.dx, inInclusiveRange(0, 800));
      expect(p.dy, inInclusiveRange(0, 600));
    }
    expect((pos['b']! - pos['c']!).distance, greaterThan(20));
    // 같은 입력이면 같은 배치.
    final again = forceLayout(
      nodes: ['a', 'b', 'c', 'd'],
      depth: {'a': 0, 'b': 1, 'c': 1, 'd': 2},
      edges: [('a', 'b'), ('a', 'c'), ('c', 'd')],
      center: 'a',
      size: const Size(800, 600),
    );
    expect(again, pos);
  });
}
