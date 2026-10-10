import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hover_builder.dart';
import '../section_label.dart';

import 'package:shad/shad.dart';

import '../../tokens.dart';

/// Presentation-only directed diagram node. The feature supplies units,
/// financial labels, provenance, navigation target and linkage decisions.
class RelationshipDiagramNode<T> {
  const RelationshipDiagramNode({
    required this.value,
    required this.name,
    required this.kind,
    required this.weightLabel,
    required this.tooltip,
    required this.linked,
    this.weight,
    this.estimated = false,
  });
  final T value;
  final String name, kind, weightLabel, tooltip;
  final double? weight;
  final bool linked, estimated;
}

/// 주주 → 이 회사 → 출자 대상. 선 굵기는 지분율, 점선은 추정 연결.
///
/// 상장사·인물 노드를 누르면 [onTap]으로 건너간다. 이름뿐인 노드는 누를 수 없다.
class RelationshipDiagram<T> extends StatelessWidget {
  const RelationshipDiagram({
    super.key,
    required this.center,
    required this.left,
    required this.right,
    required this.onTap,
    this.leftTitle = '주주',
    this.rightTitle = '출자',
    this.maxPerSide,
  });

  final String center;
  final List<RelationshipDiagramNode<T>> left;
  final List<RelationshipDiagramNode<T>> right;
  final ValueChanged<RelationshipDiagramNode<T>> onTap;
  final String leftTitle;
  final String rightTitle;
  final int? maxPerSide;

  static const _nodeHeight = 38.0;
  static const _gap = 8.0;
  static const _headerHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final shownLeft = maxPerSide == null
        ? left
        : left.take(maxPerSide!).toList();
    final shownRight = maxPerSide == null
        ? right
        : right.take(maxPerSide!).toList();
    final rows = math.max(1, math.max(shownLeft.length, shownRight.length));
    final height = _headerHeight + rows * (_nodeHeight + _gap);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final colWidth = math.min(240.0, width * 0.3);
        final centerWidth = math.min(180.0, width * 0.22);
        final centerLeft = (width - centerWidth) / 2;
        final centerTop =
            _headerHeight + (rows * (_nodeHeight + _gap)) / 2 - 30;

        double top(int i, int count) {
          final block = count * (_nodeHeight + _gap);
          final offset = (rows * (_nodeHeight + _gap) - block) / 2;
          return _headerHeight + offset + i * (_nodeHeight + _gap);
        }

        final edges = <_Edge>[
          for (final (i, n) in shownLeft.indexed)
            _Edge(
              from: Offset(
                colWidth,
                top(i, shownLeft.length) + _nodeHeight / 2,
              ),
              to: Offset(centerLeft, centerTop + 30),
              weight: n.weight,
              dashed: n.estimated,
              color: _edgeColor(context, n),
            ),
          for (final (i, n) in shownRight.indexed)
            _Edge(
              from: Offset(centerLeft + centerWidth, centerTop + 30),
              to: Offset(
                width - colWidth,
                top(i, shownRight.length) + _nodeHeight / 2,
              ),
              weight: n.weight,
              dashed: n.estimated,
              color: _edgeColor(context, n),
            ),
        ];

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _EdgePainter(edges)),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: _Header(
                  '$leftTitle${left.length > shownLeft.length ? ' (상위 ${shownLeft.length}/${left.length})' : ''}',
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _Header(
                  '$rightTitle${right.length > shownRight.length ? ' (상위 ${shownRight.length}/${right.length})' : ''}',
                ),
              ),
              for (final (i, n) in shownLeft.indexed)
                Positioned(
                  left: 0,
                  top: top(i, shownLeft.length),
                  width: colWidth,
                  height: _nodeHeight,
                  child: _Node(node: n, onTap: onTap),
                ),
              for (final (i, n) in shownRight.indexed)
                Positioned(
                  right: 0,
                  top: top(i, shownRight.length),
                  width: colWidth,
                  height: _nodeHeight,
                  child: _Node(node: n, onTap: onTap, alignRight: true),
                ),
              Positioned(
                left: centerLeft,
                top: centerTop,
                width: centerWidth,
                height: 60,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: c.inverse,
                    borderRadius: context.shape.borderRadius,
                  ),
                  child: Text(
                    center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: t.body(
                      14,
                      color: c.onInverse,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _edgeColor(BuildContext context, RelationshipDiagramNode n) {
    final c = context.colors;
    if (n.kind == 'company') return c.chartSeries1;
    if (n.kind == 'person') return c.chartSeries2;
    return c.chartGrid;
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionLabel(text);
}

class _Node<T> extends StatelessWidget {
  const _Node({
    required this.node,
    required this.onTap,
    this.alignRight = false,
  });

  final RelationshipDiagramNode<T> node;
  final ValueChanged<RelationshipDiagramNode<T>> onTap;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final tone = node.kind == 'company'
        ? c.chartSeries1
        : node.kind == 'person'
        ? c.chartSeries2
        : c.textMuted;
    final label = Row(
      children: [
        Expanded(
          child: Text(
            node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.body(
              13,
              color: node.linked ? c.textPrimary : c.textSecondary,
              weight: node.linked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Text(
          node.weightLabel,
          style: t.numeric(12, color: c.textSecondary),
        ),
      ],
    );
    return ShadTooltip(
      builder: (_) => Text(node.tooltip),
      child: Semantics(
        label: node.name,
        tooltip: node.tooltip,
        child: HoverBuilder(
          onTap: node.linked ? () => onTap(node) : null,
          builder: (context, hovered) => AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            decoration: BoxDecoration(
              color: hovered ? c.surfaceHover : c.surface,
              border: Border(
                left: alignRight
                    ? BorderSide.none
                    : BorderSide(color: tone, width: 3),
                right: alignRight
                    ? BorderSide(color: tone, width: 3)
                    : BorderSide.none,
                top: BorderSide(color: c.border),
                bottom: BorderSide(color: c.border),
              ),
            ),
            alignment: Alignment.center,
            child: label,
          ),
        ),
      ),
    );
  }
}

class _Edge {
  const _Edge({
    required this.from,
    required this.to,
    required this.weight,
    required this.dashed,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final double? weight;
  final bool dashed;
  final Color color;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.edges);

  final List<_Edge> edges;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final w = e.weight ?? 0;
      final paint = Paint()
        ..color = e.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + (w.clamp(0, 40) / 40) * 5;
      final dx = (e.to.dx - e.from.dx) / 2;
      final path = Path()
        ..moveTo(e.from.dx, e.from.dy)
        ..cubicTo(
          e.from.dx + dx,
          e.from.dy,
          e.to.dx - dx,
          e.to.dy,
          e.to.dx,
          e.to.dy,
        );
      if (!e.dashed) {
        canvas.drawPath(path, paint);
        continue;
      }
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 9) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + 5, metric.length)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => old.edges != edges;
}
