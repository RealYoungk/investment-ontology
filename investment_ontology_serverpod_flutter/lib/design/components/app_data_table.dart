import 'package:flutter/material.dart';

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

  /// 자리를 채우는 배치에서 이 열이 차지한다고 보는 폭 (실제 폭이 아니라 표가 들어갈지
  /// 가늠하는 어림).
  double get _guess =>
      width ??
      minWidth ??
      (numeric
          ? 92
          : flex
          ? 200
          : 120);
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
/// 자리가 넉넉하면 주어진 폭을 다 쓰고 남는 폭은 [AppColumn.flex] 열이 가져간다. 열이
/// 폭보다 많으면 (열 어림의 합이 폭을 넘으면) 내용 폭대로 그리고 가로로 민다.
/// 예전처럼 무한 폭 안에서 flex 열을 쓰면 그 열이 한 글자 폭으로 찌그러지므로, 채우는
/// 배치에서는 표에 유한한 폭을 준다.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.maxCellWidth = 320,
    this.expand = true,
    this.fitWidth,
  });

  final List<AppColumn> columns;
  final List<AppRow> rows;

  /// 내용에 맞추는 열의 셀 최대 폭. 긴 글은 이 폭에서 줄을 바꾼다.
  final double maxCellWidth;

  /// 내용이 좁아도 표가 주어진 폭을 다 쓴다 (기본). 끄면 늘 내용 폭대로.
  final bool expand;

  /// 자리를 채우는 배치에 필요한 최소 폭. 없으면 열마다 어림한 폭의 합.
  final double? fitWidth;

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

  double get _fitWidth =>
      fitWidth ??
      columns.fold(0.0, (s, col) => s + col._guess) + AppSpace.sm * 2;

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

    Widget cell(Widget child, AppColumn col, {required bool fills}) =>
        Container(
          width: col.width,
          constraints: col.width != null
              ? null
              : BoxConstraints(
                  minWidth: col.minWidth ?? (col.numeric ? 76 : 0),
                  maxWidth: col.nowrap || fills
                      ? double.infinity
                      : maxCellWidth,
                ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: 7,
          ),
          alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        );

    Widget table({required bool fill}) => Table(
      columnWidths: fill
          ? {for (final i in flexIndexes) i: const FlexColumnWidth()}
          : null,
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
            for (final (i, col) in columns.indexed)
              cell(
                Text(
                  col.label,
                  style: t.body(12, color: c.textSecondary),
                  textAlign: col.numeric ? TextAlign.right : TextAlign.left,
                ),
                col,
                fills: fill && flexIndexes.contains(i),
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
                  fills: fill && flexIndexes.contains(i),
                ),
            ],
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) {
        final fill =
            expand &&
            box.maxWidth.isFinite &&
            box.maxWidth >= _fitWidth &&
            flexIndexes.isNotEmpty;
        if (fill) {
          return SizedBox(width: box.maxWidth, child: table(fill: true));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table(fill: false),
        );
      },
    );
  }
}
