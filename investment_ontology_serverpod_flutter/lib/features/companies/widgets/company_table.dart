import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

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
  });

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
    final c = context.colors;
    final p = page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 2, color: c.borderStrong),
        _HeaderRow(compact: compact),
        Container(height: 1, color: c.borderStrong),
        SizedBox(
          height: 2,
          child: loading ? const LinearProgressIndicator() : null,
        ),
        if (p == null)
          const SizedBox(height: 240)
        else if (p.items.isEmpty)
          const _EmptyState()
        else
          AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: loading ? 0.55 : 1,
            child: Column(
              children: [
                for (final (i, item) in p.items.indexed)
                  _CompanyRow(
                    item: item,
                    index: offset + i + 1,
                    compact: compact,
                    selected: selected == item.corpCode,
                    onTap: () => onSelect(item.corpCode),
                  ),
              ],
            ),
          ),
        Container(height: 2, color: c.borderStrong),
        if (p != null && p.total > 0)
          _Pager(
            total: p.total,
            offset: offset,
            pageSize: pageSize,
            onPage: onPage,
          ),
      ],
    );
  }
}

/// 열 너비. 가변 열(회사명·업종)은 flex.
abstract final class _Col {
  static const index = 52.0;
  static const code = 86.0;
  static const market = 70.0;
  static const ceo = 150.0;
  static const month = 56.0;
  static const established = 104.0;
  static const nameFlex = 5;
  static const industryFlex = 5;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = context.typo.label(color: context.colors.textPrimary);
    Widget fixed(String text, double width, {bool end = false}) => SizedBox(
      width: width,
      child: Text(
        text,
        style: style,
        textAlign: end ? TextAlign.end : TextAlign.start,
      ),
    );
    Widget flex(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: AppSpace.sm,
      ),
      child: Row(
        children: [
          if (!compact) fixed('NO', _Col.index),
          fixed('종목', _Col.code),
          flex('회사명', _Col.nameFlex),
          fixed('시장', _Col.market),
          if (!compact) ...[
            flex('업종 (KSIC)', _Col.industryFlex),
            fixed('대표자', _Col.ceo),
            fixed('결산', _Col.month, end: true),
            fixed('설립일', _Col.established, end: true),
          ],
        ],
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({
    required this.item,
    required this.index,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final CompanyListItem item;
  final int index;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final fg = selected ? c.onInverse : c.textPrimary;
    final soft = selected ? c.border : c.textSecondary;

    return HoverBuilder(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: selected
              ? c.inverse
              : hovered
              ? c.surfaceHover
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: AppSpace.sm,
        ),
        child: Row(
          children: [
            if (!compact)
              SizedBox(
                width: _Col.index,
                child: Text(
                  '$index',
                  style: t.numeric(
                    11.5,
                    color: selected ? c.border : c.textMuted,
                  ),
                ),
              ),
            SizedBox(
              width: _Col.code,
              child: Text(
                item.stockCode ?? '—',
                style: t.numeric(13.5, color: fg, weight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: _Col.nameFlex,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.body(15, color: fg, weight: FontWeight.w600),
              ),
            ),
            SizedBox(
              width: _Col.market,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppTag(
                  label: marketLabel(item.market),
                  color: selected && item.market == Market.kospi
                      ? c.onInverse
                      : marketColor(context, item.market),
                ),
              ),
            ),
            if (!compact) ...[
              Expanded(
                flex: _Col.industryFlex,
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (item.sectionCode != null)
                        TextSpan(
                          text: '${item.sectionCode} ',
                          style: t.numeric(
                            11.5,
                            color: selected ? c.accentSubtle : c.accent,
                            weight: FontWeight.w700,
                          ),
                        ),
                      TextSpan(
                        text: item.industryName ?? item.industryCode ?? '—',
                        style: t.body(13.5, color: soft),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: _Col.ceo,
                child: Text(
                  item.ceoName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body(13.5, color: soft),
                ),
              ),
              SizedBox(
                width: _Col.month,
                child: Text(
                  item.fiscalMonth == null ? '—' : '${item.fiscalMonth}월',
                  textAlign: TextAlign.end,
                  style: t.body(13, color: soft),
                ),
              ),
              SizedBox(
                width: _Col.established,
                child: Text(
                  formatDate(item.establishedDate),
                  textAlign: TextAlign.end,
                  style: t.numeric(12.5, color: soft),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.total,
    required this.offset,
    required this.pageSize,
    required this.onPage,
  });

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
      child: Row(
        children: [
          Text(
            '${formatCount(from)}–${formatCount(to)} / ${formatCount(total)}개사',
            style: t.numeric(13, color: context.colors.textSecondary),
          ),
          const Spacer(),
          AppIconButton(
            icon: Icons.west,
            tooltip: '이전 페이지',
            onPressed: offset > 0
                ? () => onPage((offset - pageSize).clamp(0, total))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$page / $pages', style: t.numeric(13)),
          ),
          AppIconButton(
            icon: Icons.east,
            tooltip: '다음 페이지',
            onPressed: offset + pageSize < total
                ? () => onPage(offset + pageSize)
                : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Text(
            '해당하는 기업이 없습니다',
            style: context.typo.display(22, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '아직 수집 전이라면 위의 “DART에서 수집”을 눌러주세요.',
            style: context.typo.body(13, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
