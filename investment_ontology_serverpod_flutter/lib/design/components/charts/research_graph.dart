import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shad/shad.dart';

import '../../tokens.dart';
import '../hover_builder.dart';
import 'force_layout.dart';

/// Immutable presentation data. No Serverpod DTO, URL, request or financial formatting.
class ResearchGraph {
  const ResearchGraph({
    required this.centerKey,
    required this.nodes,
    required this.edges,
  });
  final String centerKey;
  final List<ResearchGraphNode> nodes;
  final List<ResearchGraphEdge> edges;
}

class ResearchGraphNode {
  const ResearchGraphNode({
    required this.key,
    required this.kind,
    required this.label,
    required this.tooltip,
    required this.depth,
    this.marketCap,
  });
  final String key, kind, label, tooltip;
  final int depth;
  final double? marketCap;
}

enum ResearchLinkKind { ownership, executive, business }

class ResearchGraphEdge {
  const ResearchGraphEdge({
    required this.from,
    required this.to,
    required this.kind,
    this.weight,
    this.estimated = false,
  });
  final String from, to;
  final ResearchLinkKind kind;
  final double? weight;
  final bool estimated;
}

class ResearchGraphCanvas extends StatefulWidget {
  const ResearchGraphCanvas({
    super.key,
    required this.graph,
    required this.selected,
    required this.onTap,
  });

  final ResearchGraph graph;
  final String? selected;
  final ValueChanged<ResearchGraphNode> onTap;

  @override
  State<ResearchGraphCanvas> createState() => _ResearchGraphCanvasState();
}

class _ResearchGraphCanvasState extends State<ResearchGraphCanvas> {
  static const _height = 680.0;
  Map<String, Offset>? _pos;
  double? _width;

  @override
  void didUpdateWidget(covariant ResearchGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
          oldWidget.graph.nodes.map((n) => n.key).toList(),
          widget.graph.nodes.map((n) => n.key).toList(),
        ) ||
        !listEquals(
          oldWidget.graph.edges.map((e) => (e.from, e.to)).toList(),
          widget.graph.edges.map((e) => (e.from, e.to)).toList(),
        ) ||
        oldWidget.graph.centerKey != widget.graph.centerKey) {
      _pos = null;
    }
  }

  void _layout(double width) {
    if (_pos != null && _width == width) return;
    final g = widget.graph;
    _width = width;
    _pos = forceLayout(
      nodes: [for (final n in g.nodes) n.key],
      depth: {for (final n in g.nodes) n.key: n.depth},
      edges: [for (final e in g.edges) (e.from, e.to)],
      center: g.centerKey,
      size: Size(width, _height),
    );
  }

  /// 겹치지 않게 놓을 수 있는 이름의 노드 키. 큰 노드(가운데 먼저)부터 차례로
  /// 이름 상자를 놓고, 앞서 놓인 상자나 다른 원과 겹치면 그 이름은 뺀다.
  static Set<String> _placeLabels(
    ResearchGraph g,
    Map<String, Offset> pos, {
    int? limit,
  }) {
    final order = [...g.nodes]
      ..sort((a, b) {
        if (a.key == g.centerKey) return -1;
        if (b.key == g.centerKey) return 1;
        return _radius(b).compareTo(_radius(a));
      });
    final circles = [
      for (final n in g.nodes)
        if (pos[n.key] case final p?)
          Rect.fromCircle(center: p, radius: _radius(n)),
    ];
    final taken = <Rect>[];
    final out = <String>{};
    for (final n in order) {
      final p = pos[n.key];
      if (p == null) continue;
      if (limit != null && out.length >= limit) break;
      final fontSize = n.kind == 'name' ? 10.0 : 11.5;
      // 글자 폭 어림: 한글은 글자 크기만큼, 로마자·숫자는 그 절반쯤.
      var w = 8.0;
      for (final ch in n.label.runes) {
        w += ch > 0x2E80 ? fontSize : fontSize * 0.55;
      }
      w = math.min(w, 140);
      final box = Rect.fromLTWH(
        p.dx - w / 2,
        p.dy + _radius(n) + 2,
        w,
        fontSize + 5,
      );
      final isCenter = n.key == g.centerKey;
      final clash =
          taken.any((r) => r.overlaps(box)) ||
          (!isCenter &&
              circles.any(
                (c) => c.overlaps(box) && c.center != p,
              ));
      if (clash) continue;
      taken.add(box);
      out.add(n.key);
    }
    return out;
  }

  /// 시가총액으로 기업 노드 크기를 정한다 (로그 비율).
  static double _radius(ResearchGraphNode n) {
    if (n.kind == 'name') return 5;
    if (n.kind == 'person') return 8;
    final cap = n.marketCap?.toDouble() ?? 0;
    if (cap <= 0) return 10;
    return (6 + (math.log(cap) / math.ln10 - 10) * 5).clamp(9, 30);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return LayoutBuilder(
      builder: (context, constraints) {
        _layout(constraints.maxWidth);
        final pos = _pos!;
        final g = widget.graph;
        // 이름이 서로 겹치면 못 읽는다. 큰 노드부터 이름을 놓고, 이미 놓인 이름이나
        // 다른 원과 겹치는 이름은 숨긴다 (눌렀을 때 툴팁·아래 목록에서 본다).
        // 좁은 화면에서는 그래도 많으니 열 개까지만.
        final labelled = _placeLabels(
          g,
          pos,
          limit: constraints.maxWidth >= 600 ? null : 10,
        );
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: context.shape.borderRadius,
            border: Border.all(color: c.border),
          ),
          child: ClipRect(
            child: InteractiveViewer(
              minScale: 0.4,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox(
                width: constraints.maxWidth,
                height: _height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EdgePainter(
                          edges: g.edges,
                          pos: pos,
                          colors: c,
                        ),
                      ),
                    ),
                    for (final n in g.nodes)
                      if (pos[n.key] case final p?)
                        () {
                          final r = _radius(n);
                          final isCenter = n.key == g.centerKey;
                          final selected = n.key == widget.selected;
                          final fill = isCenter
                              ? c.inverse
                              : switch (n.kind) {
                                  'company' => c.chartSeries1,
                                  'person' => c.chartSeries2,
                                  _ => c.chartGrid,
                                };
                          return Positioned(
                            left: p.dx - 70,
                            top: p.dy - r,
                            width: 140,
                            child: ShadTooltip(
                              builder: (_) => Text(n.tooltip),
                              child: Semantics(
                                excludeSemantics: true,
                                label: n.label,
                                tooltip: n.tooltip,
                                selected: selected,
                                button: n.kind != 'name',
                                enabled: n.kind != 'name',
                                onTap: n.kind == 'name'
                                    ? null
                                    : () => widget.onTap(n),
                                child: HoverBuilder(
                                  onTap: n.kind == 'name'
                                      ? null
                                      : () => widget.onTap(n),
                                  builder: (context, hovered) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: r * 2,
                                        height: r * 2,
                                        decoration: BoxDecoration(
                                          color: fill,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected || hovered
                                                ? c.textPrimary
                                                : c.surface,
                                            width: selected ? 3 : 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (labelled.contains(n.key))
                                        Text(
                                          n.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: t.body(
                                            n.kind == 'name' ? 10 : 11.5,
                                            color: n.kind == 'name'
                                                ? c.textMuted
                                                : c.textPrimary,
                                            weight: isCenter
                                                ? FontWeight.w700
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.edges, required this.pos, required this.colors});

  final List<ResearchGraphEdge> edges;
  final Map<String, Offset> pos;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final a = pos[e.from], b = pos[e.to];
      if (a == null || b == null) continue;
      final color = switch (e.kind) {
        ResearchLinkKind.ownership => colors.chartSeries1,
        ResearchLinkKind.executive => colors.chartSeries2,
        _ => colors.success,
      };
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1 + ((e.weight ?? 0).clamp(0, 50) / 50) * 4
        ..style = PaintingStyle.stroke;
      if (e.estimated) {
        final total = (b - a).distance;
        if (total == 0) continue;
        final dir = (b - a) / total;
        for (var d = 0.0; d < total; d += 9) {
          canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
        }
      } else {
        canvas.drawLine(a, b, paint);
      }
      // 방향: 목적어 쪽 가까이에 작은 점.
      final tip = Offset.lerp(a, b, 0.8)!;
      canvas.drawCircle(tip, 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.edges != edges || old.pos != pos || old.colors != colors;
}
