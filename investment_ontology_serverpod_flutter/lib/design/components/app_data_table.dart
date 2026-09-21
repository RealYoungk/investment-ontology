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

  /// 표가 자리를 채울 때([AppDataTable.expand]) 남는 폭을 가져가는 열.
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

/// 가로로 스크롤되는 표. 셀은 위젯이고, 글자 셀은 [AppDataTable.text]로 만든다.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.maxCellWidth = 320,
    this.expand = false,
  });

  final List<AppColumn> columns;
  final List<AppRow> rows;
  final double maxCellWidth;

  /// 내용이 좁아도 표가 주어진 폭을 다 쓴다. 남는 폭은 [AppColumn.flex] 열이 가져간다.
  /// 열이 몇 개 없는 목록이 화면 왼쪽에 몰려 보이지 않게 할 때 쓴다.
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    Widget cell(Widget child, AppColumn col) => Container(
      width: col.width,
      constraints: col.width != null
          ? null
          : BoxConstraints(
              minWidth: col.minWidth ?? (col.numeric ? 76 : 0),
              maxWidth: col.nowrap ? double.infinity : maxCellWidth,
            ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 7,
      ),
      alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    );

    final flexColumns = {
      for (var i = 0; i < columns.length; i++)
        if (columns[i].flex) i: const FlexColumnWidth(),
    };
    Widget table(double? minWidth) => ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      child: Table(
        columnWidths: expand ? flexColumns : null,
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
                  ),
              ],
            ),
        ],
      ),
    );

    if (!expand) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table(null),
      );
    }
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table(box.maxWidth),
      ),
    );
  }
}
