import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../financials/financial_metrics.dart';
import '../governance/governance_view.dart';
import '../review/review_page.dart';

/// 관계망: 기업을 가운데 두고 지분·출자·임원·승인된 AI 관계를 따라 넓힌 그래프.
///
/// 기업 노드를 누르면 그 기업이 가운데로 온다. 인물은 인물 페이지로 간다.
typedef GraphFetch = Future<CompanyGraph> Function(
  String corpCode, {
  required int depth,
  required int maxNodes,
  required bool includeNames,
});

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, this.corpCode, this.fetch});

  final String? corpCode;
  final GraphFetch? fetch;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  CompanyGraph? _graph;
  Object? _error;
  bool _loading = false;
  int _depth = 1;
  bool _names = false;
  int _maxNodes = 40;
  GraphNode? _selected;

  /// 폰에서는 노드가 많으면 서로 겹쳐 못 읽는다. 처음 한 번만 줄여 둔다.
  bool _sizedForScreen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sizedForScreen) return;
    _sizedForScreen = true;
    if (MediaQuery.sizeOf(context).width < 600 && _maxNodes != 40) {
      _maxNodes = 40;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant GraphPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      _selected = null;
      _load();
    }
  }

  /// 늦게 온 응답이 새 응답을 덮지 않게 하는 요청 번호.
  int _seq = 0;

  Future<void> _load() async {
    final code = widget.corpCode;
    if (code == null) return;
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final g = await (widget.fetch ?? client.graph.neighborhood)(
        code,
        depth: _depth,
        maxNodes: _maxNodes,
        includeNames: _names,
      );
      if (mounted && seq == _seq) setState(() => (_graph = g, _error = null));
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  void _tap(GraphNode n) {
    setState(() => _selected = n);
    if (n.kind == 'company' && n.corpCode != null) {
      Router.neglect(context, () => context.go(AppRoutes.graph(n.corpCode!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final g = _graph;
    return PageFrame(
      maxWidth: AppLayout.contentWidth,
      children: [
        const PageHeading(
          title: '관계망',
          subtitle: '기업을 검색하고 주주·출자·임원·사업 관계를 따라 탐색하세요. 각 기업의 최신 사업보고서 기준입니다.',
        ),
        const SizedBox(height: AppSpace.lg),
        DataPanel(
          child: Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _CompanySearch(),
              AppToggleGroup<int>(
                label: '단계',
                value: _depth,
                options: const {1: '1', 2: '2', 3: '3'},
                onChanged: (d) {
                  setState(() => _depth = d);
                  _load();
                },
              ),
              AppToggleGroup<int>(
                label: '노드',
                value: _maxNodes,
                options: const {40: '40', 80: '80', 160: '160'},
                onChanged: (n) {
                  setState(() => _maxNodes = n);
                  _load();
                },
              ),
              ShadSwitch(
                value: _names,
                label: const Text('비상장·해외 법인 포함'),
                onChanged: (v) {
                  setState(() => _names = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (widget.corpCode == null)
          const ShadAlert(
            icon: Icon(LucideIcons.network),
            title: Text('어떤 기업과 연결되어 있을까요?'),
            description: Text(
              '위에서 기업을 검색하면 관계망을 볼 수 있습니다. 기업을 누르면 그 기업을 중심으로 다시 탐색합니다.',
            ),
          )
        else if (_error != null)
          ReadFailureNotice(subject: '관계망', retry: _load)
        else if (g == null)
          const ShadProgress(minHeight: 2)
        else ...[
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShadBadge.secondary(child: Text('노드 ${g.nodes.length}')),
              ShadBadge.secondary(child: Text('관계 ${g.edges.length}')),
              if (_loading) const Text('관계망 갱신 중…'),
              if (g.truncated)
                Text(
                  '노드 수 제한으로 약한 관계 일부를 뺐습니다',
                  style: t.body(12, color: c.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          LayoutBuilder(
            builder: (context, box) {
              // 폰에서는 점이 겹쳐 그림으로 읽기 어렵다. 관계를 종류별 목록으로 보여 준다.
              if (box.maxWidth < 600) {
                return _GraphList(graph: g, onTap: _tap);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: _loading ? 0.5 : 1,
                    child: ResearchGraphCanvas(
                      key: ValueKey(
                        '${g.centerKey}-${g.nodes.length}-${g.edges.length}',
                      ),
                      graph: _presentation(g),
                      selected: _selected?.key,
                      onTap: (node) =>
                          _tap(g.nodes.firstWhere((n) => n.key == node.key)),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  const _Legend(),
                  if (_selected case final n?) ...[
                    const SizedBox(height: AppSpace.md),
                    _Selection(node: n, graph: g),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// 기업 이름으로 찾아 관계망의 가운데에 둔다.
class _CompanySearch extends StatefulWidget {
  const _CompanySearch();

  @override
  State<_CompanySearch> createState() => _CompanySearchState();
}

class _CompanySearchState extends State<_CompanySearch> {
  final _controller = TextEditingController();
  List<CompanyListItem> _results = const [];
  Timer? _debounce;
  int _seq = 0;
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    final seq = ++_seq;
    final query = q.trim();
    setState(() {
      _results = const [];
      _loading = query.isNotEmpty;
      _failed = false;
    });
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final page = await client.company.list(query: query, limit: 6);
        if (mounted && seq == _seq) setState(() => _results = page.items);
      } catch (_) {
        if (mounted && seq == _seq) setState(() => _failed = true);
      } finally {
        if (mounted && seq == _seq) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return SizedBox(
      width: math.min(300, MediaQuery.sizeOf(context).width - 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('중심 기업', style: t.label(color: c.textSecondary)),
          const SizedBox(height: AppSpace.xs),
          ShadInput(
            placeholder: const Text('기업 이름 검색'),
            leading: Icon(LucideIcons.search, size: 18, color: c.textMuted),
            controller: _controller,
            onChanged: _search,
            style: t.body(14),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.sm),
              child: Text('검색 중…'),
            )
          else if (_failed)
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.sm),
              child: Text('검색하지 못했습니다. 다시 입력해 주세요.'),
            )
          else if (_controller.text.trim().isNotEmpty && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.sm),
              child: Text('검색 결과가 없습니다.'),
            ),
          for (final item in _results)
            ShadButton.ghost(
              width: double.infinity,
              mainAxisAlignment: MainAxisAlignment.start,
              onPressed: () {
                _debounce?.cancel();
                ++_seq;
                _controller.clear();
                setState(() {
                  _results = const [];
                  _loading = false;
                  _failed = false;
                });
                context.go(AppRoutes.graph(item.corpCode));
              },
              child: Expanded(
                child: Text(
                  item.name,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 폰에서 보는 관계망: 중심 기업의 관계를 종류별로 묶은 목록.
///
/// 그림 대신 글로 읽는다. 줄을 누르면 그 대상이 가운데로 온다 (그림과 같은 동작).
class _GraphList extends StatelessWidget {
  const _GraphList({required this.graph, required this.onTap});

  final CompanyGraph graph;
  final ValueChanged<GraphNode> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final byKey = {for (final n in graph.nodes) n.key: n};
    final center = byKey[graph.centerKey];

    // (제목, 이 노드에서 본 상대, 관계) — 중심에 붙은 것부터, 그다음 2단계.
    final groups = <String, List<(GraphNode, GraphEdge, bool)>>{};
    for (final e in graph.edges) {
      final fromCenter = e.from == graph.centerKey;
      final toCenter = e.to == graph.centerKey;
      final other = byKey[fromCenter ? e.to : e.from];
      if (other == null) continue;
      // 최대주주 명단(shareholderOf)과 타법인출자(investsIn)는 같은 지분을 양쪽에서
      // 적은 것이라 한 묶음으로 보여 준다 (아래에서 같은 상대는 하나로 합친다).
      final title = switch ((e.predicate, toCenter)) {
        (RelationPredicate.shareholderOf, true) ||
        (RelationPredicate.investsIn, true) => '주주',
        (RelationPredicate.shareholderOf, false) ||
        (RelationPredicate.investsIn, false) => '지분을 가진 곳',
        (RelationPredicate.executiveOf, true) => '임원',
        (RelationPredicate.executiveOf, false) => '임원으로 있는 곳',
        (RelationPredicate.suppliesTo, true) => '공급처',
        (RelationPredicate.suppliesTo, false) => '매출처',
        (RelationPredicate.competesWith, _) => '경쟁',
        (RelationPredicate.produces, _) => '제품',
      };
      if (!fromCenter && !toCenter) {
        groups.putIfAbsent('건너편 관계', () => []).add((other, e, false));
        continue;
      }
      groups.putIfAbsent(title, () => []).add((other, e, true));
    }
    for (final entry in groups.entries) {
      // 같은 상대가 두 번 나오면 지분율이 큰 쪽만 남긴다.
      final best = <String, (GraphNode, GraphEdge, bool)>{};
      for (final row in entry.value) {
        final key = '${row.$1.key}|${row.$3}';
        final kept = best[key];
        if (kept == null ||
            (row.$2.weight ?? 0) > (kept.$2.weight ?? 0) ||
            (kept.$2.estimated && !row.$2.estimated)) {
          best[key] = row;
        }
      }
      entry.value
        ..clear()
        ..addAll(best.values)
        ..sort((a, b) => (b.$2.weight ?? 0).compareTo(a.$2.weight ?? 0));
    }

    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (center != null)
            Text(center.label, style: t.body(16, weight: FontWeight.w700)),
          const SizedBox(height: AppSpace.sm),
          for (final entry in groups.entries) ...[
            SectionLabel('${entry.key} ${entry.value.length}'),
            const SizedBox(height: 4),
            for (final (other, edge, direct) in entry.value.take(30))
              ShadButton.ghost(
                width: double.infinity,
                height: null,
                onPressed: () => onTap(other),
                child: Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          direct
                              ? other.label
                              : '${byKey[edge.from]?.label} → ${byKey[edge.to]?.label}',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.body(
                            13.5,
                            color: other.kind == 'person'
                                ? c.accent
                                : c.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (edge.estimated)
                        Text('추정 ', style: t.body(11.5, color: c.textMuted)),
                      if (edge.weight case final w?)
                        Text(
                          formatRatio(w),
                          style: t.numeric(12.5, color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            if (entry.value.length > 30)
              Text(
                '그 밖에 ${entry.value.length - 30}건',
                style: t.body(12, color: c.textMuted),
              ),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    Widget dot(Color color, {bool ring = false}) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ring ? null : color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: color, width: 2) : null,
      ),
    );
    Widget line(Color color, {bool dashed = false, double width = 2}) =>
        SizedBox(
          width: 18,
          height: 10,
          child: CustomPaint(
            painter: _LegendLinePainter(color, dashed: dashed, width: width),
          ),
        );
    Widget item(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(text, style: t.body(12, color: c.textSecondary)),
      ],
    );
    return Wrap(
      spacing: AppSpace.lg,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        item(dot(c.inverse), '가운데 기업'),
        item(dot(c.chartSeries1), '기업 (원 크기 = 시가총액)'),
        item(dot(c.chartSeries2), '인물'),
        item(dot(c.chartGrid), '비상장·해외 법인, 제품'),
        item(line(c.chartSeries1, width: 3), '주주·출자 (굵기 = 지분율)'),
        item(line(c.chartSeries2), '임원'),
        item(line(c.success), '공급·매출·경쟁·제품 (본문에서 뽑아 승인)'),
        item(line(c.chartSeries1, dashed: true), '추정 인물 연결'),
        Text(
          '선 끝 점 = 방향(목적어 쪽) · 끌어서 이동, 휠·두 손가락으로 확대',
          style: t.body(11.5, color: c.textMuted),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter(this.color, {this.dashed = false, this.width = 2});

  final Color color;
  final bool dashed;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    if (dashed) {
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, size.width), y),
          paint,
        );
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawCircle(Offset(size.width - 2, y), 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter old) =>
      old.color != color || old.dashed != dashed || old.width != width;
}

/// 누른 노드의 관계 목록.
class _Selection extends StatelessWidget {
  const _Selection({required this.node, required this.graph});

  final GraphNode node;
  final CompanyGraph graph;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final labels = {for (final n in graph.nodes) n.key: n.label};
    final mine = [
      for (final e in graph.edges)
        if (e.from == node.key || e.to == node.key) e,
    ];
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.label,
                  style: t.body(16, weight: FontWeight.w700),
                ),
              ),
              if (node.corpCode != null)
                ShadButton.raw(
                  onPressed: () =>
                      context.push(AppRoutes.company(node.corpCode!)),
                  variant: ShadButtonVariant.link,
                  foregroundColor: c.accent,
                  child: Flexible(child: Text('기업 상세 →')),
                ),
              if (node.personId != null)
                ShadButton.raw(
                  onPressed: () =>
                      context.push(AppRoutes.person(node.personId!)),
                  variant: ShadButtonVariant.link,
                  foregroundColor: c.accent,
                  child: Flexible(child: Text('인물 →')),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          for (final e in mine)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${labels[e.from]} —${predicateLabel(e.predicate)}${e.estimated ? '(추정)' : ''}→ '
                '${labels[e.to]}${e.weight == null ? '' : ' ${formatRatio(e.weight)}'}',
                style: t.body(12.5),
              ),
            ),
        ],
      ),
    );
  }
}

ResearchGraph _presentation(CompanyGraph graph) => ResearchGraph(
  centerKey: graph.centerKey,
  nodes: [
    for (final n in graph.nodes)
      ResearchGraphNode(
        key: n.key,
        kind: n.kind,
        label: n.label,
        depth: n.depth,
        marketCap: n.marketCap?.toDouble(),
        tooltip: [
          n.label,
          if (n.marketCap != null) '시가총액 ${formatKrw(n.marketCap)}',
          if (n.kind == 'company') '눌러서 가운데로',
          if (n.kind == 'person') '눌러서 인물 보기',
        ].join('\n'),
      ),
  ],
  edges: [
    for (final e in graph.edges)
      ResearchGraphEdge(
        from: e.from,
        to: e.to,
        weight: e.weight,
        estimated: e.estimated,
        kind: switch (e.predicate) {
          RelationPredicate.shareholderOf ||
          RelationPredicate.investsIn => ResearchLinkKind.ownership,
          RelationPredicate.executiveOf => ResearchLinkKind.executive,
          _ => ResearchLinkKind.business,
        },
      ),
  ],
);
