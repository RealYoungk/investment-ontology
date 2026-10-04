import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import '../../financials/financial_metrics.dart';

/// 상장사 목록 표.
class CompanyTable extends StatelessWidget {
  const CompanyTable({
    super.key,
    required this.page,
    required this.loading,
    required this.compact,
    required this.selected,
    required this.offset,
    required this.pageSize,
    required this.onSelect,
    required this.onPage,
    this.sort,
    this.onSort,
  });

  final CompanySort? sort;
  final ValueChanged<CompanySort>? onSort;
  final CompanyPage? page;
  final bool loading;

  /// 좁은 화면: 종목·회사명·시장만.
  final bool compact;
  final String? selected;
  final int offset;
  final int pageSize;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final p = page;
    final rowHeight = compact ? 72.0 : 64.0;
    final headers = compact
        ? ['회사명', '시가총액']
        : ['NO', '종목', '회사명', '시장', '시가총액', '업종 (KSIC)', '대표자', '결산', '설립일'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact && onSort != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: AppSelect<CompanySort>(
              label: '정렬',
              placeholder: '시가총액순',
              allowClear: false,
              value: sort,
              options: const {
                CompanySort.marketCap: '시가총액순',
                CompanySort.name: '가나다순',
                CompanySort.stockCode: '종목코드순',
                CompanySort.establishedDate: '설립 오래된 순',
              },
              onChanged: (value) {
                if (value != null) onSort!(value);
              },
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        if (loading) const ShadProgress(),
        if (p == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 72),
            child: Center(child: Text('기업 목록 불러오는 중…')),
          )
        else if (p.items.isEmpty)
          const ShadEmpty(
            title: Text('해당하는 기업이 없습니다'),
            description: Text('검색어를 바꾸거나 시장·업종 필터를 초기화해 보세요.'),
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              // All rows fit the outer page: the table never owns vertical wheel scrolling.
              const fixedWidths = [48.0, 88.0, 88.0, 160.0, 140.0, 64.0, 112.0];
              final flexibleWidth =
                  (box.maxWidth -
                      fixedWidths.fold<double>(
                        0,
                        (sum, width) => sum + width,
                      )) /
                  2;
              final widths = compact
                  ? [box.maxWidth - 144, 144.0]
                  : [
                      48.0,
                      88.0,
                      flexibleWidth,
                      88.0,
                      160.0,
                      flexibleWidth,
                      140.0,
                      64.0,
                      112.0,
                    ];
              return SizedBox(
                height: 48 + p.items.length * rowHeight,
                child: ShadTable(
                  primary: false,
                  verticalScrollPhysics: const NeverScrollableScrollPhysics(),
                  horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
                  columnCount: headers.length,
                  rowCount: p.items.length,
                  columnSpanExtent: (column) =>
                      FixedTableSpanExtent(widths[column]),
                  rowSpanExtent: (row) =>
                      FixedTableSpanExtent(row == 0 ? 48 : rowHeight),
                  header: (context, column) {
                    final columnSort = compact
                        ? (column == 0
                              ? CompanySort.name
                              : CompanySort.marketCap)
                        : switch (column) {
                            1 => CompanySort.stockCode,
                            2 => CompanySort.name,
                            4 => CompanySort.marketCap,
                            8 => CompanySort.establishedDate,
                            _ => null,
                          };
                    final active = columnSort != null && columnSort == sort;
                    return ShadTableCell.header(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      alignment: column == (compact ? 1 : 4)
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: columnSort != null && onSort != null
                          ? ShadTooltip(
                              builder: (_) =>
                                  Text('${headers[column]} 기준으로 정렬'),
                              child: ShadButton.ghost(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                onPressed: () => onSort!(columnSort),
                                trailing: Icon(
                                  active
                                      ? (columnSort == CompanySort.marketCap
                                            ? LucideIcons.arrowDown
                                            : LucideIcons.arrowUp)
                                      : LucideIcons.arrowUpDown,
                                  size: 14,
                                  color: active
                                      ? context.colors.accent
                                      : context.colors.textSecondary,
                                ),
                                child: Text(
                                  headers[column],
                                  style: active
                                      ? context.typo.body(
                                          13,
                                          weight: FontWeight.w700,
                                          color: context.colors.accent,
                                        )
                                      : null,
                                ),
                              ),
                            )
                          : Text(headers[column]),
                    );
                  },
                  onRowTap: (row) {
                    if (row > 0) onSelect(p.items[row - 1].corpCode);
                  },
                  builder: (context, vicinity) {
                    final item = p.items[vicinity.row];
                    final column = vicinity.column;
                    final cap = item.marketCap == null
                        ? '—'
                        : formatKrw(item.marketCap);
                    final name = ShadButton.ghost(
                      height: compact ? 56 : 40,
                      width: double.infinity,
                      padding: EdgeInsets.zero,
                      onPressed: () => onSelect(item.corpCode),
                      child: Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typo.body(
                                14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (compact)
                              Text(
                                '${item.stockCode ?? '—'} · ${marketLabel(item.market)}',
                                style: context.typo.numeric(
                                  11.5,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                    final values = compact
                        ? [item.name, cap]
                        : [
                            '${offset + vicinity.row + 1}',
                            item.stockCode ?? '—',
                            item.name,
                            marketLabel(item.market),
                            cap,
                            '${item.sectionCode == null ? '' : '${item.sectionCode} '}${item.industryName ?? item.industryCode ?? '—'}',
                            item.ceoName ?? '—',
                            item.fiscalMonth == null
                                ? '—'
                                : '${item.fiscalMonth}월',
                            formatDate(item.establishedDate),
                          ];
                    final numeric = compact
                        ? column == 1
                        : [0, 1, 4, 7, 8].contains(column);
                    return ShadTableCell(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      alignment: column == (compact ? 1 : 4)
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: column == (compact ? 0 : 2)
                          ? name
                          : !compact && column == 3
                          ? ShadBadge.outline(child: Text(values[column]))
                          : Text(
                              values[column],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: numeric
                                  ? context.typo.numeric(13)
                                  : context.typo.body(
                                      13,
                                      color: context.colors.textSecondary,
                                    ),
                            ),
                    );
                  },
                ),
              );
            },
          ),
        if (p != null && p.total > 0)
          _Pager(
            total: p.total,
            offset: offset,
            pageSize: pageSize,
            onPage: onPage,
            loading: loading,
          ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.total,
    required this.offset,
    required this.pageSize,
    required this.onPage,
    required this.loading,
  });

  final bool loading;
  final int total;
  final int offset;
  final int pageSize;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final from = offset + 1;
    final to = (offset + pageSize).clamp(0, total);
    final page = offset ~/ pageSize + 1;
    final pages = (total / pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${formatCount(from)}–${formatCount(to)} / ${formatCount(total)}개사',
            style: t.numeric(13, color: context.colors.textSecondary),
          ),
          LayoutBuilder(
            builder: (context, box) => ShadPagination(
              page: page,
              pageCount: pages,
              enabled: !loading,
              previousLabel: const Text('이전'),
              nextLabel: const Text('다음'),
              siblingCount: box.maxWidth < 600 ? 0 : 1,
              boundaryCount: box.maxWidth < 600 ? 0 : 1,
              onPageChanged: (value) => onPage((value - 1) * pageSize),
            ),
          ),
        ],
      ),
    );
  }
}
