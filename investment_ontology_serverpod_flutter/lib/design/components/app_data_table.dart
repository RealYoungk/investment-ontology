import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tokens.dart';

/// 표의 열 하나.
class AppColumn {
  const AppColumn(
    this.label, {
    this.numeric = false,
    this.width,
    this.nowrap = false,
    this.minWidth,
    this.flex = false,
  });

  final String label;

  /// 표가 자리를 채울 때 남는 폭을 가져가는 열. 아무 열도 표시하지 않으면 첫 글자 열이
  /// 가져간다.
  final bool flex;

  /// 숫자 열: 오른쪽 정렬, 숫자 글꼴.
  final bool numeric;

  /// 고정 폭. 없으면 내용에 맞춘다.
  final double? width;

  /// 한 줄로만 (날짜처럼 쪼개지면 안 되는 짧은 값). 폭이 모자라면 잘린다.
  final bool nowrap;

  /// 최소 폭. 숫자 열은 기본 76 — "10.82"가 "10.8 / 2"로 쪼개지지 않을 만큼.
  final double? minWidth;
}

/// 표의 행 하나.
class AppRow {
  const AppRow(this.cells, {this.emphasized = false, this.muted = false});

  final List<Widget> cells;

  /// 합계 행처럼 굵게.
  final bool emphasized;

  /// 흐리게 (추정 연결, 대체된 값 등).
  final bool muted;
}

/// 표. 셀은 위젯이고, 글자 셀은 [AppDataTable.text]로 만든다.
///
/// 남는 폭이 있으면 [AppColumn.flex] 열(없으면 첫 글자 열)이 가져가 표가 주어진 폭을 채우고,
/// 내용이 폭보다 넓으면 내용 폭대로 그려 가로로 민다. 둘 다 같은 배치에서 나온다: 가로 스크롤
/// 안에서 최소 폭만 주고, flex 열을 `MaxColumnWidth(내용 폭, flex)`로 두면 RenderTable이
/// 남는 폭만큼만 그 열을 키운다 (무한 폭에서 FlexColumnWidth만 쓰면 그 열이 0이 되어
/// 한 글자씩 세로로 늘어지던 것이 예전 버그).
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.maxCellWidth = 320,
    this.expand = true,
  });

  final List<AppColumn> columns;
  final List<AppRow> rows;

  /// 내용에 맞추는 열이 제 폭을 잴 때의 셀 최대 폭. 긴 글은 이 폭에서 줄을 바꾼다.
  /// (남는 폭을 가져가는 열은 이보다 넓어질 수 있다.)
  final double maxCellWidth;

  /// 내용이 좁아도 표가 주어진 폭을 다 쓴다 (기본). 끄면 늘 내용 폭대로.
  final bool expand;

  /// 글자 셀. 숫자 열이면 숫자 글꼴로 오른쪽 정렬.
  static Widget text(
    BuildContext context,
    String? value, {
    bool numeric = false,
    bool strong = false,
    Color? color,

    /// 한 줄로만. 폭이 모자라면 잘리므로, 짧은 값에만 쓴다.
    bool nowrap = false,
  }) {
    final t = context.typo;
    final c = context.colors;
    final style = numeric
        ? t.numeric(
            12.5,
            color: color ?? c.textPrimary,
            weight: strong ? FontWeight.w700 : null,
          )
        : t.body(
            13,
            color: color ?? c.textPrimary,
            weight: strong ? FontWeight.w700 : null,
          );
    final keepOneLine = nowrap;
    return Text(
      value ?? '—',
      style: value == null ? style.copyWith(color: c.textMuted) : style,
      textAlign: numeric ? TextAlign.right : TextAlign.left,
      softWrap: !keepOneLine,
      maxLines: keepOneLine ? 1 : null,
      overflow: keepOneLine ? TextOverflow.ellipsis : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;

    // 남는 폭을 가져갈 열: 표시한 열, 없으면 첫 글자 열 (고정 폭이 아닌).
    var flexIndexes = {
      for (var i = 0; i < columns.length; i++)
        if (columns[i].flex) i,
    };
    if (flexIndexes.isEmpty) {
      final first = columns.indexWhere(
        (col) => !col.numeric && col.width == null,
      );
      if (first >= 0) flexIndexes = {first};
    }

    // 남는 폭을 가져가는 열은 제 폭을 잴 때 화면의 3할까지만 요구한다. 폰에서 메모·근거처럼
    // 긴 글 열이 320px를 요구하면 다른 열이 밀려나 표가 화면을 넘는다. 남는 폭이 있으면
    // 어차피 flex로 넓어진다.
    Widget cell(Widget child, AppColumn col, double flexCap) => Container(
      width: col.width,
      constraints: col.width != null
          ? null
          : BoxConstraints(minWidth: col.minWidth ?? (col.numeric ? 76 : 0)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 7,
      ),
      alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: col.width != null || col.nowrap
          ? child
          : _IntrinsicCap(
              maxWidth: col.flex
                  ? math.min(maxCellWidth, flexCap)
                  : maxCellWidth,
              child: child,
            ),
    );

    Widget table(double flexCap) => Table(
      columnWidths: {
        for (final i in flexIndexes)
          i: const MaxColumnWidth(IntrinsicColumnWidth(), FlexColumnWidth()),
      },
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderStrong, width: 1.5),
              bottom: BorderSide(color: c.borderStrong),
            ),
          ),
          children: [
            for (final col in columns)
              cell(
                Text(
                  col.label,
                  style: t.body(12, color: c.textSecondary),
                  textAlign: col.numeric ? TextAlign.right : TextAlign.left,
                ),
                col,
                flexCap,
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            decoration: BoxDecoration(
              color: row.emphasized ? c.surfaceHover : null,
              border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
            ),
            children: [
              for (final (i, col) in columns.indexed)
                cell(
                  Opacity(
                    opacity: row.muted ? 0.6 : 1,
                    child: DefaultTextStyle.merge(
                      style: row.emphasized
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                      child: i < row.cells.length
                          ? row.cells[i]
                          : const SizedBox.shrink(),
                    ),
                  ),
                  col,
                  flexCap,
                ),
            ],
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: expand && box.maxWidth.isFinite ? box.maxWidth : 0,
          ),
          child: table(
            box.maxWidth.isFinite
                ? math.max(100, box.maxWidth * 0.3)
                : maxCellWidth,
          ),
        ),
      ),
    );
  }
}

/// 자식의 고유 폭(intrinsic width)만 [maxWidth]로 막고, 실제 배치 폭은 그대로 넘긴다.
///
/// 표가 열 폭을 잴 때 긴 글이 한 줄 폭 전체를 요구하지 않게 하면서도, 그 열이 남는 폭을
/// 가져가 넓어졌을 때는 넓어진 폭을 다 쓰게 한다 (BoxConstraints.maxWidth로 막으면 배치도
/// 같이 막힌다).
class _IntrinsicCap extends SingleChildRenderObjectWidget {
  const _IntrinsicCap({required this.maxWidth, required super.child});

  final double maxWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicCap(maxWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIntrinsicCap renderObject,
  ) => renderObject.maxWidth = maxWidth;
}

class _RenderIntrinsicCap extends RenderProxyBox {
  _RenderIntrinsicCap(this._maxWidth);

  double _maxWidth;
  set maxWidth(double v) {
    if (v == _maxWidth) return;
    _maxWidth = v;
    markNeedsLayout();
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.min(super.computeMaxIntrinsicWidth(height), _maxWidth);

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.min(super.computeMinIntrinsicWidth(height), _maxWidth);
}
