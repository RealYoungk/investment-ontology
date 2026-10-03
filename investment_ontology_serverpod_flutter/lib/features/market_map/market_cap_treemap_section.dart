import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';
import 'market_load_notice.dart';

typedef IndustryMapLoader = Future<MarketCapTreemap> Function(
  String? section,
  Market? market,
);

/// KSIC 대분류 → 중분류 → 기업. 지도와 목록이 같은 탐색 동작을 사용한다.
class MarketCapTreemapSection extends StatefulWidget {
  const MarketCapTreemapSection({
    super.key,
    required this.market,
    required this.onSelectCompany,
    this.dataVersion = 0,
    this.loader,
  });

  final Market? market;
  final ValueChanged<String> onSelectCompany;
  final int dataVersion;
  final IndustryMapLoader? loader;

  @override
  State<MarketCapTreemapSection> createState() =>
      _MarketCapTreemapSectionState();
}

class _MarketCapTreemapSectionState extends State<MarketCapTreemapSection> {
  final _cache = <String?, MarketCapTreemap>{};
  final _listKey = GlobalKey();
  MarketCapTreemap? _map;
  bool _failed = false;
  bool _loading = true;
  String? _section;
  String? _division;
  int _seq = 0;
  int _visibleRows = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MarketCapTreemapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.market != widget.market ||
        oldWidget.dataVersion != widget.dataVersion) {
      _cache.clear();
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    final section = _section;
    final cached = _cache[section];
    setState(() {
      _failed = false;
      _loading = cached == null;
      _map = cached;
    });
    if (cached != null) return;
    try {
      final map =
          await (widget.loader?.call(section, widget.market) ??
              client.market.industryTreemap(
                sectionCode: section,
                market: widget.market,
              ));
      if (mounted && seq == _seq) {
        setState(() {
          _cache[section] = map;
          _map = map;
          _loading = false;
          if (_division != null && !map.nodes.any((n) => n.code == _division)) {
            _division = null;
          }
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _openSection(String? section) {
    setState(() {
      _section = section;
      _division = null;
      _visibleRows = 30;
    });
    _load();
  }

  void _openDivision(String? division) {
    setState(() {
      _division = division;
      _visibleRows = 30;
    });
  }

  void _select(String code) {
    if (_section == null) {
      _openSection(code);
    } else if (_division == null) {
      _openDivision(code);
    } else {
      widget.onSelectCompany(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final map = _map;
    final division = map?.nodes.where((n) => n.code == _division).firstOrNull;
    final nodes = division?.children ?? map?.nodes ?? <MarketCapNode>[];
    final total = division?.marketCap ?? map?.total ?? BigInt.zero;
    final count = nodes.fold<int>(0, (s, n) => s + n.companyCount);
    final level = _section == null
        ? '대분류'
        : _division == null
        ? '중분류'
        : '기업';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('업종 지도 · KSIC'),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            ShadButton.raw(
              onPressed: _section == null ? null : () => _openSection(null),
              enabled:
                  (_section == null ? null : () => _openSection(null)) != null,
              variant: ShadButtonVariant.link,
              child: Flexible(child: Text('전체 업종')),
            ),
            if (_section != null) ...[
              Icon(Icons.chevron_right, size: 16, color: c.textMuted),
              ShadButton.raw(
                onPressed: _division == null ? null : () => _openDivision(null),
                enabled:
                    (_division == null ? null : () => _openDivision(null)) !=
                    null,
                variant: ShadButtonVariant.link,
                child: Flexible(
                  child: Text('$_section ${map?.sectionName ?? ''}'),
                ),
              ),
            ],
            if (division != null) ...[
              Icon(Icons.chevron_right, size: 16, color: c.textMuted),
              Text(
                '${division.code} ${division.name}',
                style: t.body(13, weight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        if (_failed)
          MarketLoadNotice(subject: '업종 지도', retry: _load)
        else if (_loading || map == null)
          const ShadProgress(minHeight: 2)
        else if (map.baseDate == null)
          Text('아직 시세를 수집하지 않았습니다.', style: t.body(13, color: c.textMuted))
        else ...[
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.xs,
            children: [
              Text(
                '시가총액 ${formatKrw(total)}',
                style: t.numeric(16, weight: FontWeight.w600),
              ),
              Text(
                '${formatCount(count)}개사 · $level별 보기',
                style: t.body(13, color: c.textSecondary),
              ),
              Text(
                '기준일 ${formatDate(map.baseDate!)}',
                style: t.numeric(12, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            _division != null
                ? '기업을 선택하면 상세 정보를 볼 수 있어요.'
                : _section != null
                ? '중분류를 선택해 소속 기업을 살펴보세요.'
                : '대분류를 선택해 업종을 좁혀보세요.',
            style: t.body(13, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          if (nodes.isEmpty)
            Text('기업에 연결된 종목 시세가 없습니다.', style: t.body(13, color: c.textMuted))
          else
            LayoutBuilder(
              builder: (context, constraints) => AppTreemap<String>(
                items: _items(nodes, total),
                height: constraints.maxWidth < 600 ? 320 : 440,
                onTap: (item) {
                  if (item.id == '__more__') {
                    final listContext = _listKey.currentContext;
                    if (listContext != null) {
                      Scrollable.ensureVisible(listContext);
                    }
                  } else {
                    _select(item.id);
                  }
                },
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          _Footnote(map: map),
          const SizedBox(height: AppSpace.lg),
          Text(
            '$level 목록 · 시가총액 순',
            key: _listKey,
            style: t.body(14, weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.sm),
          _NodeTable(
            nodes: nodes.take(_visibleRows).toList(),
            total: total,
            companies: _division != null,
            onSelect: _select,
          ),
          if (nodes.length > _visibleRows) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.raw(
                onPressed: () => setState(() => _visibleRows += 30),
                variant: ShadButtonVariant.outline,
                child: Flexible(
                  child: Text(
                    '더 보기 (${formatCount(nodes.length - _visibleRows)}개 남음)',
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<TreemapItem<String>> _items(List<MarketCapNode> nodes, BigInt total) {
    final companies = _division != null;
    final shown = companies ? nodes.take(30).toList() : nodes;
    final rest = companies ? nodes.skip(30).toList() : <MarketCapNode>[];
    String share(BigInt cap) => total <= BigInt.zero
        ? '0.0%'
        : '${(cap.toDouble() / total.toDouble() * 100).toStringAsFixed(1)}%';
    return [
      for (final node in shown)
        TreemapItem(
          id: node.code,
          label: companies ? node.name : '${node.code} ${node.name}',
          value: node.marketCap.toDouble(),
          detail:
              '${formatKrw(node.marketCap)}${companies ? '' : ' · ${formatCount(node.companyCount)}개사'}',
          tooltip:
              '${node.name}\n시가총액 ${formatKrw(node.marketCap)} · 비중 ${share(node.marketCap)}\n'
              '${companies ? '눌러서 기업 상세 보기' : '${formatCount(node.companyCount)}개사 · 눌러서 하위 분류 보기'}',
        ),
      if (rest.isNotEmpty)
        TreemapItem(
          id: '__more__',
          label: '그 외 ${formatCount(rest.length)}개사',
          detail: '아래 목록 보기',
          value: rest.fold(BigInt.zero, (s, n) => s + n.marketCap).toDouble(),
          tooltip: '작은 기업은 아래 기업 목록에서 모두 찾아볼 수 있어요.',
        ),
    ];
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.map});
  final MarketCapTreemap map;

  @override
  Widget build(BuildContext context) => Text(
    [
      '면적 = 시가총액 · 색은 등락률을 나타내지 않습니다',
      '공식 한국표준산업분류 ${map.industryRevision}',
      '기업 시가총액은 보통주·우선주 등 발행 종목의 합계',
      if (map.unlinkedSecurityCount > 0)
        '기업 미연결 종목 ${formatCount(map.unlinkedSecurityCount)}개 (${formatKrw(map.unlinkedMarketCap)}) 제외',
      if (map.source != null) '출처 ${map.source!.title}',
    ].join(' · '),
    style: context.typo.body(11.5, color: context.colors.textMuted),
  );
}

/// 작은 타일도 같은 동작으로 탐색할 수 있도록 목록을 항상 펼친다.
class _NodeTable extends StatelessWidget {
  const _NodeTable({
    required this.nodes,
    required this.total,
    required this.companies,
    required this.onSelect,
  });
  final List<MarketCapNode> nodes;
  final BigInt total;
  final bool companies;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 600;
      if (!wide) {
        return Column(
          children: [
            for (final node in nodes)
              HoverBuilder(
                onTap: () => onSelect(node.code),
                builder: (context, hovered) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpace.md,
                    horizontal: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: hovered ? context.colors.surfaceHover : null,
                    border: Border(
                      bottom: BorderSide(color: context.colors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companies
                            ? '${node.name} →'
                            : '${node.code} ${node.name} →',
                        style: context.typo.body(
                          13,
                          color: context.colors.accent,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Wrap(
                        spacing: AppSpace.md,
                        runSpacing: AppSpace.xs,
                        children: [
                          Text(
                            formatKrw(node.marketCap),
                            style: context.typo.numeric(13),
                          ),
                          if (!companies)
                            Text(
                              '${formatCount(node.companyCount)}개사',
                              style: context.typo.body(
                                12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
      return AppDataTable(
        columns: [
          AppColumn(companies ? '기업' : '업종', flex: true),
          if (!companies && wide) const AppColumn('기업 수', numeric: true),
          const AppColumn('시가총액', numeric: true),
          if (wide) const AppColumn('비중', numeric: true),
        ],
        rows: [
          for (final node in nodes)
            AppRow([
              ShadButton.raw(
                onPressed: () => onSelect(node.code),
                variant: ShadButtonVariant.link,
                foregroundColor: context.colors.accent,
                child: Flexible(
                  child: Text(
                    companies
                        ? '${node.name} →'
                        : '${node.code} ${node.name} →',
                  ),
                ),
              ),
              if (!companies && wide)
                AppDataTable.text(
                  context,
                  '${formatCount(node.companyCount)}개사',
                  numeric: true,
                ),
              AppDataTable.text(
                context,
                formatKrw(node.marketCap),
                numeric: true,
              ),
              if (wide)
                AppDataTable.text(
                  context,
                  total <= BigInt.zero
                      ? '—'
                      : '${(node.marketCap.toDouble() / total.toDouble() * 100).toStringAsFixed(1)}%',
                  numeric: true,
                ),
            ]),
        ],
      );
    },
  );
}
