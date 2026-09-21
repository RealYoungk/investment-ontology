import 'package:flutter/material.dart';

import '../tokens.dart';

/// 표의 열 하나.
class AppColumn {
  const AppColumn(
    this.label, {
    this.numeric = false,
    this.width,
    bool? nowrap,
  }) : nowrap = nowrap ?? numeric;

  final String label;

  /// 숫자 열: 오른쪽 정렬, 숫자 글꼴.
  final bool numeric;

  /// 고정 폭. 없으면 내용에 맞춘다.
  final double? width;

  /// 줄바꿈·자르기 없이 내용 폭만큼 (숫자 열은 기본으로 그렇게 한다).
  /// 표는 가로로 밀 수 있으므로 넓어져도 된다.
  final bool nowrap;
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
  });

  final List<AppColumn> columns;
  final List<AppRow> rows;
  final double maxCellWidth;

  /// 글자 셀. 숫자 열이면 숫자 글꼴로 오른쪽 정렬.
  static Widget text(
    BuildContext context,
    String? value, {
    bool numeric = false,
    bool strong = false,
    Color? color,

    /// 줄바꿈을 막는다. 숫자 칸은 기본으로 막는다 ("10.8 2"처럼 쪼개지면 잘못 읽힌다).
    bool? nowrap,
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
    final keepOneLine = nowrap ?? numeric;
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
      constraints: col.width == null && !col.nowrap
          ? BoxConstraints(maxWidth: maxCellWidth)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 7,
      ),
      alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
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
  }
}
