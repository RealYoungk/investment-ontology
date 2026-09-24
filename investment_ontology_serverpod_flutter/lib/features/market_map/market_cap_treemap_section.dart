import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';
import 'market_load_notice.dart';

/// 업종별 시가총액 트리맵. 전체에서는 대분류 → 중분류, 대분류를 누르면 중분류 → 기업.
class MarketCapTreemapSection extends StatefulWidget {
  const MarketCapTreemapSection({
    super.key,
    required this.market,
    required this.onSelectCompany,
  });

  final Market? market;
  final ValueChanged<String> onSelectCompany;

  @override
  State<MarketCapTreemapSection> createState() =>
      _MarketCapTreemapSectionState();
}

class _MarketCapTreemapSectionState extends State<MarketCapTreemapSection> {
  /// 한 중분류 안에 이름을 따로 보여줄 기업 수. 나머지는 "그 외"로 묶는다.
  static const _companiesPerDivision = 30;

  /// 첫 화면에서 대분류 상자 안에 이름을 적을 기업 수.
  static const _companiesPerSection = 14;

  MarketCapTreemap? _map;
  bool _failed = false;
  String? _section;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MarketCapTreemapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.market != widget.market) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _failed = false);
    try {
      final map = await client.market.industryTreemap(
        sectionCode: _section,
        market: widget.market,
      );
      if (mounted && seq == _seq) {
        setState(() {
          _map = map;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  void _drill(String? section) {
    setState(() => _section = section);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final map = _map;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '업종별 시가총액 · KSIC',
          trailing: map?.baseDate == null
              ? null
              : Text(
                  '기준일 ${formatDate(map!.baseDate)}',
                  style: t.numeric(12, color: c.textMuted),
                ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (_failed)
          MarketLoadNotice(subject: '업종별 시가총액', retry: _load)
        else if (map == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (map.baseDate == null)
          Text(
            '아직 시세를 수집하지 않았습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else ...[
          _Breadcrumb(map: map, onBack: () => _drill(null)),
          const SizedBox(height: AppSpace.sm),
          if (map.nodes.isEmpty)
            Text(
              '기업에 연결된 종목 시세가 없습니다.',
              style: t.body(13, color: c.textMuted),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => AppTreemap<String>(
                items: _items(map, constraints.maxWidth),
                height: 440,
                onTap: (item) {
                  if (item.id.startsWith('corp:')) {
                    widget.onSelectCompany(item.id.substring(5));
                  } else if (map.sectionCode == null) {
                    // 대분류 머리글이나 '그 외' 타일 → 그 대분류로 들어간다.
                    final section = item.id.split('/').first;
                    if (section != '-') _drill(section);
                  }
                },
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          _Footnote(map: map),
          _NodeTable(map: map),
        ],
      ],
    );
  }

  List<TreemapItem<String>> _items(MarketCapTreemap map, double width) {
    // 좁은 화면에서는 타일이 작아 이름이 안 보이므로 덜 넣는다.
    final perSection = width < 700 ? 6 : _companiesPerSection;
    final total = map.total.toDouble();
    String share(BigInt cap) => total <= 0
        ? ''
        : '${(cap.toDouble() / total * 100).toStringAsFixed(1)}%';
    String tip(String name, BigInt cap, int count) =>
        '$name\n시가총액 ${formatKrw(cap)} · 비중 ${share(cap)} · ${formatCount(count)}개사';

    if (map.sectionCode == null) {
      return [
        for (final section in map.nodes)
          TreemapItem(
            id: section.code,
            label: '${section.code} ${section.name}',
            value: section.marketCap.toDouble(),
            tooltip:
                '${tip(section.name, section.marketCap, section.companyCount)}\n눌러서 중분류·기업 보기',
            tappable: section.code != '-',
            children: [
              for (final company in section.children.take(perSection))
                _companyItem(company, share),
              if (section.children.length > perSection ||
                  section.companyCount > section.children.length)
                _rest(
                  section.children.skip(perSection).toList(),
                  section,
                  id: '${section.code}/more',
                ),
            ],
          ),
      ];
    }

    return [
      for (final division in map.nodes)
        TreemapItem(
          id: division.code,
          label: '${division.code} ${division.name}',
          value: division.marketCap.toDouble(),
          tooltip: tip(
            division.name,
            division.marketCap,
            division.companyCount,
          ),
          tappable: false,
          children: [
            for (final company in division.children.take(_companiesPerDivision))
              _companyItem(company, share),
            if (division.children.length > _companiesPerDivision)
              _rest(
                division.children.skip(_companiesPerDivision).toList(),
                null,
              ),
          ],
        ),
    ];
  }

  static TreemapItem<String> _companyItem(
    MarketCapNode company,
    String Function(BigInt) share,
  ) => TreemapItem(
    id: 'corp:${company.code}',
    label: company.name,
    detail: formatKrw(company.marketCap),
    value: company.marketCap.toDouble(),
    tooltip:
        '${company.name} (${marketLabel(company.market)})\n'
        '시가총액 ${formatKrw(company.marketCap)} · 비중 ${share(company.marketCap)}\n'
        '눌러서 기업 상세 열기',
  );

  /// 남은 기업을 한 칸으로. 첫 화면에서는 눌러서 그 업종 전체를 본다.
  static TreemapItem<String> _rest(
    List<MarketCapNode> rest,
    MarketCapNode? section, {
    String id = '',
  }) {
    final cap = rest.fold(BigInt.zero, (s, n) => s + n.marketCap);
    final hidden = section == null
        ? rest.length
        : section.companyCount - (section.children.length - rest.length);
    final total = section == null
        ? cap
        : section.marketCap -
              section.children
                  .take(section.children.length - rest.length)
                  .fold(BigInt.zero, (s, n) => s + n.marketCap);
    return TreemapItem(
      id: id,
      label: '그 외 ${formatCount(hidden)}개사',
      detail: formatKrw(total),
      value: total.toDouble(),
      tooltip: section == null
          ? '그 외 ${formatCount(hidden)}개사 합계 ${formatKrw(total)}'
          : '${section.name}의 나머지 ${formatCount(hidden)}개사 합계 ${formatKrw(total)}\n눌러서 이 업종 전체 보기',
      tappable: section != null,
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.map, required this.onBack});

  final MarketCapTreemap map;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final total = Text(
      '합계 ${formatKrw(map.total)}',
      style: t.numeric(13, weight: FontWeight.w600),
    );
    if (map.sectionCode == null) {
      return Row(
        children: [
          Text('전체 업종', style: t.body(13, weight: FontWeight.w600)),
          const Spacer(),
          total,
        ],
      );
    }
    return Row(
      children: [
        AppButton(
          label: '← 전체 업종',
          variant: AppButtonVariant.link,
          tone: c.accent,
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            '${map.sectionCode} ${map.sectionName ?? ''}',
            style: t.body(13, weight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        total,
      ],
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.map});

  final MarketCapTreemap map;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Text(
      [
        '면적 = 기업 시가총액 (발행 종목 보통주·우선주 등의 시가총액 합)',
        '업종명 ${map.industryRevision}',
        if (map.unlinkedSecurityCount > 0)
          '기업에 연결되지 않은 종목 ${formatCount(map.unlinkedSecurityCount)}개 '
              '(${formatKrw(map.unlinkedMarketCap)})는 제외',
        if (map.source != null) '출처 ${map.source!.title}',
      ].join(' · '),
      style: t.body(11.5, color: c.textMuted),
    );
  }
}

/// 트리맵과 같은 값을 표로.
class _NodeTable extends StatelessWidget {
  const _NodeTable({required this.map});

  final MarketCapTreemap map;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final total = map.total.toDouble();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: c.border),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        dense: true,
        title: Text('표로 보기', style: t.body(12.5, color: c.textSecondary)),
        children: [
          for (final node in map.nodes)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      node.code,
                      style: t.numeric(12, weight: FontWeight.w700),
                    ),
                  ),
                  Expanded(child: Text(node.name, style: t.body(12.5))),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${formatCount(node.companyCount)}개사',
                      textAlign: TextAlign.right,
                      style: t.numeric(12, color: c.textSecondary),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      formatKrw(node.marketCap),
                      textAlign: TextAlign.right,
                      style: t.numeric(12),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      total <= 0
                          ? ''
                          : '${(node.marketCap.toDouble() / total * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: t.numeric(12, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
