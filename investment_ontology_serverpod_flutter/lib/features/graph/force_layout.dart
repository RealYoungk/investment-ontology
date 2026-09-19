import 'dart:math' as math;
import 'dart:ui';

/// 힘-배치: 모든 노드는 서로 밀고, 간선은 당기고, 중심 노드는 가운데에 고정한다.
///
/// 결정적이다 (같은 입력이면 같은 배치). 처음 자리는 단계(depth)별 동심원이라 흩어져 시작하지 않는다.
Map<String, Offset> forceLayout({
  required List<String> nodes,
  required Map<String, int> depth,
  required List<(String, String)> edges,
  required String center,
  Size size = const Size(1000, 700),
  int iterations = 300,
}) {
  final pos = <String, Offset>{};
  final byDepth = <int, List<String>>{};
  for (final n in nodes) {
    (byDepth[depth[n] ?? 1] ??= []).add(n);
  }
  final mid = Offset(size.width / 2, size.height / 2);
  final ring = math.min(size.width, size.height) / 6;
  for (final MapEntry(key: d, value: list) in byDepth.entries) {
    for (final (i, n) in list.indexed) {
      final angle = 2 * math.pi * i / list.length + d * 0.7;
      pos[n] = mid + Offset(math.cos(angle), math.sin(angle)) * (ring * d);
    }
  }
  pos[center] = mid;
  if (nodes.length < 2) return pos;

  final area = size.width * size.height;
  final k = math.sqrt(area / nodes.length) * 0.85;
  var temperature = size.width / 8;
  for (var step = 0; step < iterations; step++) {
    final disp = {for (final n in nodes) n: Offset.zero};
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final a = nodes[i], b = nodes[j];
        var delta = pos[a]! - pos[b]!;
        var dist = delta.distance;
        if (dist < 0.01) {
          delta = Offset(0.01 * (i + 1), 0.01 * (j + 1));
          dist = delta.distance;
        }
        final force = k * k / dist;
        final push = delta / dist * force;
        disp[a] = disp[a]! + push;
        disp[b] = disp[b]! - push;
      }
    }
    for (final (a, b) in edges) {
      if (!pos.containsKey(a) || !pos.containsKey(b)) continue;
      final delta = pos[a]! - pos[b]!;
      final dist = math.max(delta.distance, 0.01);
      final pull = delta / dist * (dist * dist / k);
      disp[a] = disp[a]! - pull;
      disp[b] = disp[b]! + pull;
    }
    for (final n in nodes) {
      if (n == center) continue;
      // 가운데로 약하게 끌어 흩어지지 않게 한다.
      final toMid = mid - pos[n]!;
      final d = disp[n]! + toMid * 0.01;
      final len = d.distance;
      final moved = len == 0
          ? Offset.zero
          : d / len * math.min(len, temperature);
      final p = pos[n]! + moved;
      pos[n] = Offset(
        p.dx.clamp(40, size.width - 40),
        p.dy.clamp(30, size.height - 30),
      );
    }
    temperature = math.max(1, temperature * 0.97);
  }
  return pos;
}
