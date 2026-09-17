import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../theme/ledger_theme.dart';
import 'format.dart';

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
  final bool compact;
  final String? selected;
  final int offset;
  final int pageSize;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final p = page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 2, color: Pal.ink),
        _HeaderRow(compact: compact),
        Container(height: 1, color: Pal.ink),
        SizedBox(
          height: 2,
          child: loading ? const LinearProgressIndicator() : null,
        ),
        if (p == null)
          const SizedBox(height: 240)
        else if (p.items.isEmpty)
          const _Empty()
        else
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: loading ? 0.55 : 1,
            child: Column(
              children: [
                for (final (i, c) in p.items.indexed)
                  _CompanyRow(
                    item: c,
                    index: offset + i + 1,
                    compact: compact,
                    selected: selected == c.corpCode,
                    onTap: () => onSelect(c.corpCode),
                  ),
              ],
            ),
          ),
        Container(height: 2, color: Pal.ink),
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

class _Cols {
  static const index = 52.0;
  static const code = 86.0;
  static const market = 70.0;
  static const ceo = 150.0;
  static const month = 56.0;
  static const est = 104.0;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, {double? width, int flex = 0, bool end = false}) {
      final t = Text(
        text,
        style: Typo.label(color: Pal.ink),
        textAlign: end ? TextAlign.end : TextAlign.start,
      );
      return width != null
          ? SizedBox(width: width, child: t)
          : Expanded(flex: flex, child: t);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          if (!compact) cell('NO', width: _Cols.index),
          cell('종목', width: _Cols.code),
          cell('회사명', flex: 5),
          cell('시장', width: _Cols.market),
          if (!compact) ...[
            cell('업종 (KSIC)', flex: 5),
            cell('대표자', width: _Cols.ceo),
            cell('결산', width: _Cols.month, end: true),
            cell('설립일', width: _Cols.est, end: true),
          ],
        ],
      ),
    );
  }
}

class _CompanyRow extends StatefulWidget {
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
  State<_CompanyRow> createState() => _CompanyRowState();
}

class _CompanyRowState extends State<_CompanyRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.item;
    final sel = widget.selected;
    final bg = sel
        ? Pal.ink
        : _hover
        ? Pal.paperDeep
        : Colors.transparent;
    final fg = sel ? Pal.paper : Pal.ink;
    final soft = sel ? Pal.rule : Pal.inkSoft;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bg,
            border: const Border(
              bottom: BorderSide(color: Pal.rule, width: 0.8),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Row(
            children: [
              if (!widget.compact)
                SizedBox(
                  width: _Cols.index,
                  child: Text(
                    '${widget.index}',
                    style: Typo.mono(
                      11.5,
                      color: sel ? Pal.rule : Pal.inkFaint,
                    ),
                  ),
                ),
              SizedBox(
                width: _Cols.code,
                child: Text(
                  c.stockCode ?? '—',
                  style: Typo.mono(13.5, color: fg, weight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(15, color: fg, weight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: _Cols.market,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MarketTag(market: c.market, inverted: sel),
                ),
              ),
              if (!widget.compact) ...[
                Expanded(
                  flex: 5,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (c.sectionCode != null)
                          TextSpan(
                            text: '${c.sectionCode} ',
                            style: Typo.mono(
                              11.5,
                              color: sel ? Pal.sealSoft : Pal.seal,
                              weight: FontWeight.w700,
                            ),
                          ),
                        TextSpan(
                          text: c.industryName ?? c.industryCode ?? '—',
                          style: Typo.body(13.5, color: soft),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: _Cols.ceo,
                  child: Text(
                    c.ceoName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.body(13.5, color: soft),
                  ),
                ),
                SizedBox(
                  width: _Cols.month,
                  child: Text(
                    c.fiscalMonth == null ? '—' : '${c.fiscalMonth}월',
                    textAlign: TextAlign.end,
                    style: Typo.body(13, color: soft),
                  ),
                ),
                SizedBox(
                  width: _Cols.est,
                  child: Text(
                    formatYmd(c.establishedDate),
                    textAlign: TextAlign.end,
                    style: Typo.mono(12.5, color: soft),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketTag extends StatelessWidget {
  const _MarketTag({required this.market, required this.inverted});

  final Market? market;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final color = switch (market) {
      Market.kospi => Pal.kospi,
      Market.kosdaq => Pal.kosdaq,
      Market.konex => Pal.konex,
      _ => Pal.inkFaint,
    };
    final c = inverted && market == Market.kospi ? Pal.paper : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: c, width: 1)),
      child: Text(
        marketLabel(market),
        style: Typo.body(11.5, color: c, weight: FontWeight.w600),
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
            style: Typo.mono(13, color: Pal.inkSoft),
          ),
          const Spacer(),
          _PageButton(
            icon: Icons.west,
            enabled: offset > 0,
            onTap: () => onPage((offset - pageSize).clamp(0, total)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$page / $pages', style: Typo.mono(13)),
          ),
          _PageButton(
            icon: Icons.east,
            enabled: offset + pageSize < total,
            onTap: () => onPage(offset + pageSize),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 38,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? Pal.ink : Pal.rule, width: 1.2),
          ),
          child: Icon(icon, size: 16, color: enabled ? Pal.ink : Pal.rule),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Text('해당하는 기업이 없습니다', style: Typo.display(22, color: Pal.inkSoft)),
          const SizedBox(height: 8),
          Text(
            '아직 수집 전이라면 위의 “DART에서 수집”을 눌러주세요.',
            style: Typo.body(13, color: Pal.inkFaint),
          ),
        ],
      ),
    );
  }
}
