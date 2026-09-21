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
import 'force_layout.dart';

/// 관계망: 기업을 가운데 두고 지분·출자·임원·승인된 AI 관계를 따라 넓힌 그래프.
///
/// 기업 노드를 누르면 그 기업이 가운데로 온다. 인물은 인물 페이지로 간다.
class GraphPage extends StatefulWidget {
  const GraphPage({super.key, this.corpCode});

  final String? corpCode;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  CompanyGraph? _graph;
  Object? _error;
  bool _loading = false;
  int _depth = 2;
  bool _names = false;
  int _maxNodes = 80;
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

  Future<void> _load() async {
    final code = widget.corpCode;
    if (code == null) return;
    setState(() => _loading = true);
    try {
      final g = await client.graph.neighborhood(
        code,
        depth: _depth,
        maxNodes: _maxNodes,
        includeNames: _names,
      );
      if (mounted) setState(() => (_graph = g, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      maxWidth: 1400,
      children: [
        const PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 관계망',
          title: '관계망',
          subtitle:
              '기업을 가운데 두고 주주·출자·임원 관계와 검수에서 승인한 AI 관계(공급·경쟁)를 따라 넓힙니다. '
              '기업을 누르면 그 기업이 가운데로 옵니다. 각 기업의 가장 최근 사업보고서 기준입니다.',
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
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
            AppToggleGroup<bool>(
              label: '비상장·해외 법인',
              value: _names,
              options: const {false: '숨기기', true: '보이기'},
              onChanged: (v) {
                setState(() => _names = v);
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (widget.corpCode == null)
          Text(
            '위에서 기업을 찾아 가운데에 두세요.',
            style: t.body(13, color: c.textMuted),
          )
        else if (_error != null)
          AppNotice(message: '관계망을 불러오지 못했습니다 — $_error')
        else if (g == null)
          const LinearProgressIndicator(minHeight: 2)
        else ...[
          Text(
            '노드 ${g.nodes.length} · 관계 ${g.edges.length}'
            '${g.truncated ? ' · 노드 수 제한으로 약한 관계 일부를 뺐습니다' : ''}',
            style: t.body(12, color: c.textMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: _loading ? 0.5 : 1,
            child: _GraphCanvas(
              key: ValueKey(
                '${g.centerKey}-${g.nodes.length}-${g.edges.length}',
              ),
              graph: g,
              selected: _selected?.key,
              onTap: _tap,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          const _Legend(),
          if (_selected case final n?) ...[
            const SizedBox(height: AppSpace.md),
            _Selection(node: n, graph: g),
          ],
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

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (q.trim().isEmpty) {
        setState(() => _results = const []);
        return;
      }
      final page = await client.company.list(query: q.trim(), limit: 6);
      if (mounted) setState(() => _results = page.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            onChanged: _search,
            style: t.body(14),
            decoration: InputDecoration(
              hintText: '가운데에 둘 기업',
              prefixIcon: Icon(Icons.search, size: 20, color: c.textPrimary),
            ),
          ),
          for (final item in _results)
            HoverBuilder(
              onTap: () {
                _controller.clear();
                setState(() => _results = const []);
                context.go(AppRoutes.graph(item.corpCode));
              },
              builder: (context, hovered) => Container(
                color: hovered ? c.surfaceHover : c.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 6,
                ),
                child: Text(item.name, style: t.body(13)),
              ),
            ),
        ],
      ),
    );
  }
}

class _GraphCanvas extends StatefulWidget {
  const _GraphCanvas({
    super.key,
    required this.graph,
    required this.selected,
    required this.onTap,
  });

  final CompanyGraph graph;
  final String? selected;
  final ValueChanged<GraphNode> onTap;

  @override
  State<_GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<_GraphCanvas> {
  static const _height = 680.0;
  Map<String, Offset>? _pos;
  double? _width;

  void _layout(double width) {
    if (_pos != null && _width == width) return;
    final g = widget.graph;
    _width = width;
    _pos = forceLayout(
      nodes: [for (final n in g.nodes) n.key],
      depth: {for (final n in g.nodes) n.key: n.depth},
      edges: [for (final e in g.edges) (e.from, e.to)],
      center: g.centerKey,
      size: Size(width, _height),
    );
  }

  /// 시가총액으로 기업 노드 크기를 정한다 (로그 비율).
  static double _radius(GraphNode n) {
    if (n.kind == 'name') return 5;
    if (n.kind == 'person') return 8;
    final cap = n.marketCap?.toDouble() ?? 0;
    if (cap <= 0) return 10;
    return (6 + (math.log(cap) / math.ln10 - 10) * 5).clamp(9, 30);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return LayoutBuilder(
      builder: (context, constraints) {
        _layout(constraints.maxWidth);
        final pos = _pos!;
        final g = widget.graph;
        // 좁은 화면에서는 이름이 서로 겹쳐 못 읽는다. 큰 노드만 이름을 적고,
        // 나머지는 눌렀을 때(툴팁·아래 목록)에서 본다.
        final labelled = constraints.maxWidth >= 600
            ? null
            : {
                g.centerKey,
                ...([...g.nodes]..sort(
                      (a, b) => _radius(b).compareTo(_radius(a)),
                    ))
                    .take(10)
                    .map((n) => n.key),
              };
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: context.shape.borderRadius,
            border: Border.all(color: c.border),
          ),
          child: ClipRect(
            child: InteractiveViewer(
              minScale: 0.4,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(400),
              child: SizedBox(
                width: constraints.maxWidth,
                height: _height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EdgePainter(
                          edges: g.edges,
                          pos: pos,
                          colors: c,
                        ),
                      ),
                    ),
                    for (final n in g.nodes)
                      if (pos[n.key] case final p?)
                        () {
                          final r = _radius(n);
                          final isCenter = n.key == g.centerKey;
                          final selected = n.key == widget.selected;
                          final fill = isCenter
                              ? c.inverse
                              : switch (n.kind) {
                                  'company' => c.chartSeries1,
                                  'person' => c.chartSeries2,
                                  _ => c.chartGrid,
                                };
                          return Positioned(
                            left: p.dx - 70,
                            top: p.dy - r,
                            width: 140,
                            child: Tooltip(
                              message: [
                                n.label,
                                if (n.marketCap != null)
                                  '시가총액 ${formatKrw(n.marketCap)}',
                                if (n.kind == 'company') '눌러서 가운데로',
                                if (n.kind == 'person') '눌러서 인물 보기',
                              ].join('\n'),
                              child: HoverBuilder(
                                onTap: n.kind == 'name'
                                    ? null
                                    : () => widget.onTap(n),
                                builder: (context, hovered) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: r * 2,
                                      height: r * 2,
                                      decoration: BoxDecoration(
                                        color: fill,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected || hovered
                                              ? c.textPrimary
                                              : c.surface,
                                          width: selected ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (labelled == null ||
                                        labelled.contains(n.key))
                                      Text(
                                        n.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: t.body(
                                          n.kind == 'name' ? 10 : 11.5,
                                          color: n.kind == 'name'
                                              ? c.textMuted
                                              : c.textPrimary,
                                          weight: isCenter
                                              ? FontWeight.w700
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.edges, required this.pos, required this.colors});

  final List<GraphEdge> edges;
  final Map<String, Offset> pos;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final a = pos[e.from], b = pos[e.to];
      if (a == null || b == null) continue;
      final color = switch (e.predicate) {
        RelationPredicate.shareholderOf ||
        RelationPredicate.investsIn => colors.chartSeries1,
        RelationPredicate.executiveOf => colors.chartSeries2,
        _ => colors.success,
      };
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1 + ((e.weight ?? 0).clamp(0, 50) / 50) * 4
        ..style = PaintingStyle.stroke;
      if (e.estimated) {
        final total = (b - a).distance;
        final dir = (b - a) / total;
        for (var d = 0.0; d < total; d += 9) {
          canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
        }
      } else {
        canvas.drawLine(a, b, paint);
      }
      // 방향: 목적어 쪽 가까이에 작은 점.
      final tip = Offset.lerp(a, b, 0.8)!;
      canvas.drawCircle(tip, 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.edges != edges || old.pos != pos;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Text(
      '검정 = 가운데 기업 · 파랑 = 기업·지분(주주·출자) · 주황 = 인물·임원 · 초록 = 승인된 AI 관계(공급·경쟁·제품) · '
      '점선 = 추정 인물 연결 · 선 굵기 = 지분율 · 점 = 방향(목적어 쪽) · 원 크기 = 시가총액 · '
      '끌어서 이동, 휠·두 손가락으로 확대',
      style: t.body(11.5, color: c.textMuted),
    );
  }
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
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(node.label, style: t.body(16, weight: FontWeight.w700)),
              const Spacer(),
              if (node.corpCode != null)
                AppButton(
                  label: '기업 상세 →',
                  variant: AppButtonVariant.link,
                  tone: c.accent,
                  onPressed: () =>
                      context.push(AppRoutes.company(node.corpCode!)),
                ),
              if (node.personId != null)
                AppButton(
                  label: '인물 →',
                  variant: AppButtonVariant.link,
                  tone: c.accent,
                  onPressed: () =>
                      context.push(AppRoutes.person(node.personId!)),
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
