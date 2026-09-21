import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens.dart';
import '../hover_builder.dart';

/// 트리맵 항목. 면적이 [value]에 비례한다. [children]이 있으면 그 안을 다시 나눈다.
class TreemapItem<T> {
  const TreemapItem({
    required this.id,
    required this.label,
    required this.value,
    required this.tooltip,
    this.detail,
    this.children = const [],
    this.tappable = true,
  });

  final T id;
  final String label;

  /// 이름 아래 작은 글자 (예: 비중).
  final String? detail;
  final double value;
  final String tooltip;
  final List<TreemapItem<T>> children;

  /// 묶음("그 외 n개") 같은 항목은 누를 수 없다.
  final bool tappable;
}

/// Squarified 트리맵 배치 (Bruls et al.). [values]는 큰 것부터 정렬되어 있어야 한다.
///
/// 반환하는 사각형은 [values]와 같은 순서다. 0 이하 값은 빈 사각형.
List<Rect> squarify(List<double> values, Rect bounds) {
  final result = List<Rect>.filled(values.length, Rect.zero);
  final total = values.fold(0.0, (s, v) => s + math.max(0, v));
  if (total <= 0 || bounds.isEmpty) return result;
  final scale = bounds.width * bounds.height / total;
  final areas = [for (final v in values) math.max(0.0, v) * scale];

  var rect = bounds;
  var start = 0;
  while (start < areas.length) {
    final side = math.min(rect.width, rect.height);
    var end = start + 1;
    var rowSum = areas[start];
    var worst = _worst(areas, start, end, rowSum, side);
    while (end < areas.length) {
      final nextSum = rowSum + areas[end];
      final next = _worst(areas, start, end + 1, nextSum, side);
      if (next > worst) break;
      worst = next;
      rowSum = nextSum;
      end++;
    }

    // 짧은 변을 따라 한 줄을 놓고 남은 사각형을 줄인다.
    final horizontal = rect.width >= rect.height;
    final thickness = side == 0 ? 0.0 : rowSum / side;
    var offset = 0.0;
    for (var i = start; i < end; i++) {
      final length = thickness == 0 ? 0.0 : areas[i] / thickness;
      result[i] = horizontal
          ? Rect.fromLTWH(rect.left, rect.top + offset, thickness, length)
          : Rect.fromLTWH(rect.left + offset, rect.top, length, thickness);
      offset += length;
    }
    rect = horizontal
        ? Rect.fromLTRB(
            rect.left + thickness,
            rect.top,
            rect.right,
            rect.bottom,
          )
        : Rect.fromLTRB(
            rect.left,
            rect.top + thickness,
            rect.right,
            rect.bottom,
          );
    start = end;
  }
  return result;
}

double _worst(List<double> areas, int start, int end, double sum, double side) {
  if (sum <= 0 || side <= 0) return double.infinity;
  var maxA = 0.0, minA = double.infinity;
  for (var i = start; i < end; i++) {
    maxA = math.max(maxA, areas[i]);
    minA = math.min(minA, areas[i]);
  }
  if (minA <= 0) return double.infinity;
  final s2 = side * side;
  final sum2 = sum * sum;
  return math.max(s2 * maxA / sum2, sum2 / (s2 * minA));
}

/// 두 단계 트리맵. 바깥 타일은 머리글 줄에 이름을 쓰고, 안쪽을 [TreemapItem.children]로 나눈다.
///
/// 타일 사이는 표면색 2px 간격으로 떨어뜨린다. 이름은 타일 안에 들어갈 때만 쓰고,
/// 들어가지 않으면 툴팁으로만 보여준다.
class AppTreemap<T> extends StatelessWidget {
  const AppTreemap({
    super.key,
    required this.items,
    required this.onTap,
    this.height = 420,
  });

  final List<TreemapItem<T>> items;
  final ValueChanged<TreemapItem<T>> onTap;
  final double height;

  static const _gap = 2.0;
  static const _headerHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Offset.zero & Size(constraints.maxWidth, height);
          final rects = squarify([for (final i in items) i.value], bounds);
          return Stack(
            children: [
              for (final (index, item) in items.indexed)
                ..._tile(context, item, rects[index], outer: true),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _tile(
    BuildContext context,
    TreemapItem<T> item,
    Rect rect, {
    required bool outer,
  }) {
    final inner = rect.deflate(_gap / 2);
    if (inner.width < 1 || inner.height < 1) return const [];
    final c = context.colors;
    final t = context.typo;

    if (outer && item.children.isNotEmpty) {
      final showHeader = inner.height > _headerHeight * 2;
      final body = showHeader
          ? Rect.fromLTRB(
              inner.left,
              inner.top + _headerHeight,
              inner.right,
              inner.bottom,
            )
          : inner;
      final childRects = squarify([
        for (final ch in item.children) ch.value,
      ], body);
      return [
        Positioned.fromRect(
          rect: inner,
          child: Tooltip(
            message: item.tooltip,
            waitDuration: const Duration(milliseconds: 150),
            child: HoverBuilder(
              onTap: item.tappable ? () => onTap(item) : null,
              builder: (context, hovered) => Container(
                color: hovered ? c.inverse : c.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.topLeft,
                child: showHeader
                    ? SizedBox(
                        height: _headerHeight,
                        child: _FittedLabel(
                          text: item.label,
                          style: t.body(
                            11.5,
                            color: c.onInverse,
                            weight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        for (final (i, child) in item.children.indexed)
          ..._tile(context, child, childRects[i], outer: false),
      ];
    }

    final labelStyle = t.body(
      12,
      color: c.textPrimary,
      weight: FontWeight.w600,
    );
    final detailStyle = t.numeric(10.5, color: c.textSecondary);
    return [
      Positioned.fromRect(
        rect: inner,
        child: Tooltip(
          message: item.tooltip,
          waitDuration: const Duration(milliseconds: 150),
          child: HoverBuilder(
            onTap: item.tappable ? () => onTap(item) : null,
            builder: (context, hovered) => AnimatedContainer(
              duration: AppMotion.fast,
              color: hovered ? c.chartTileHover : c.chartTile,
              padding: const EdgeInsets.all(5),
              alignment: Alignment.topLeft,
              child: inner.width > 36 && inner.height > 20
                  ? _FittedLabel(
                      text: item.label,
                      style: labelStyle,
                      detail: inner.height > 40 ? item.detail : null,
                      detailStyle: detailStyle,
                    )
                  : null,
            ),
          ),
        ),
      ),
    ];
  }
}

/// 한 줄에 다 들어갈 때만 글자를 쓴다. 잘린 글자는 보여주지 않는다.
///
/// [detail](비중 등)은 이름이 들어갈 때만 쓴다. 이름 없이 숫자만 남으면 무엇의 값인지 알 수 없다.
class _FittedLabel extends StatefulWidget {
  const _FittedLabel({
    required this.text,
    required this.style,
    this.detail,
    this.detailStyle,
  });

  final String text;
  final TextStyle style;
  final String? detail;
  final TextStyle? detailStyle;

  @override
  State<_FittedLabel> createState() => _FittedLabelState();
}

class _FittedLabelState extends State<_FittedLabel> {
  /// 잰 폭에 곱하는 여유.
  static const _safety = 1.05;

  @override
  void initState() {
    super.initState();
    // 웹 글꼴은 늦게 로드된다. 로드되면 폭이 바뀌므로 다시 잰다.
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    super.dispose();
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final base = DefaultTextStyle.of(context).style;
        Size measure(String s, TextStyle? st) {
          // Text 위젯처럼 기본 글꼴 설정을 합쳐서 잰다.
          final painter = TextPainter(
            text: TextSpan(text: s, style: base.merge(st)),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout();
          final size = painter.size;
          painter.dispose();
          return size;
        }

        bool fitsWidth(Size s) => s.width * _safety <= constraints.maxWidth;

        final w = widget;
        final labelSize = measure(w.text, w.style);
        if (labelSize.height > constraints.maxHeight) {
          return const SizedBox.shrink();
        }
        // 이름이 다 안 들어가는 타일에는 앞 글자만이라도 적는다 (…로 줄여서).
        // 큰 상자가 텅 비어 보이는 것보다 낫다. 두 글자도 안 들어가면 비운다.
        if (!fitsWidth(labelSize)) {
          final two = measure(w.text.characters.take(2).toString(), w.style);
          if (!fitsWidth(two)) return const SizedBox.shrink();
          return Text(
            w.text,
            style: w.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
        }
        final d = w.detail;
        final label = Text(
          w.text,
          style: w.style,
          maxLines: 1,
          softWrap: false,
        );
        if (d == null) return label;
        final detailSize = measure(d, w.detailStyle);
        // 작은 타일에서는 이름만 적는다.
        if (!fitsWidth(detailSize) ||
            labelSize.height + detailSize.height > constraints.maxHeight) {
          return label;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            label,
            Text(d, style: w.detailStyle, maxLines: 1, softWrap: false),
          ],
        );
      },
    );
  }
}
