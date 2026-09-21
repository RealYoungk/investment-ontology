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

  /// 늦게 온 응답이 새 응답을 덮지 않게 하는 요청 번호.
  int _seq = 0;

  Future<void> _load() async {
    final code = widget.corpCode;
    if (code == null) return;
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final g = await client.graph.neighborhood(
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

  /// 겹치지 않게 놓을 수 있는 이름의 노드 키. 큰 노드(가운데 먼저)부터 차례로
  /// 이름 상자를 놓고, 앞서 놓인 상자나 다른 원과 겹치면 그 이름은 뺀다.
  static Set<String> _placeLabels(
    CompanyGraph g,
    Map<String, Offset> pos, {
    int? limit,
  }) {
    final order = [...g.nodes]
      ..sort((a, b) {
        if (a.key == g.centerKey) return -1;
        if (b.key == g.centerKey) return 1;
        return _radius(b).compareTo(_radius(a));
      });
    final circles = [
      for (final n in g.nodes)
        if (pos[n.key] case final p?)
          Rect.fromCircle(center: p, radius: _radius(n)),
    ];
    final taken = <Rect>[];
    final out = <String>{};
    for (final n in order) {
      final p = pos[n.key];
      if (p == null) continue;
      if (limit != null && out.length >= limit) break;
      final fontSize = n.kind == 'name' ? 10.0 : 11.5;
      // 글자 폭 어림: 한글은 글자 크기만큼, 로마자·숫자는 그 절반쯤.
      var w = 8.0;
      for (final ch in n.label.runes) {
        w += ch > 0x2E80 ? fontSize : fontSize * 0.55;
      }
      w = math.min(w, 140);
      final box = Rect.fromLTWH(
        p.dx - w / 2,
        p.dy + _radius(n) + 2,
        w,
        fontSize + 5,
      );
      final isCenter = n.key == g.centerKey;
      final clash =
          taken.any((r) => r.overlaps(box)) ||
          (!isCenter &&
              circles.any(
                (c) => c.overlaps(box) && c.center != p,
              ));
      if (clash) continue;
      taken.add(box);
      out.add(n.key);
    }
    return out;
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
        // 이름이 서로 겹치면 못 읽는다. 큰 노드부터 이름을 놓고, 이미 놓인 이름이나
        // 다른 원과 겹치는 이름은 숨긴다 (눌렀을 때 툴팁·아래 목록에서 본다).
        // 좁은 화면에서는 그래도 많으니 열 개까지만.
        final labelled = _placeLabels(
          g,
          pos,
          limit: constraints.maxWidth >= 600 ? null : 10,
        );
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
                                    if (labelled.contains(n.key))
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
          if (center != null)
            Text(center.label, style: t.body(16, weight: FontWeight.w700)),
          const SizedBox(height: AppSpace.sm),
          for (final entry in groups.entries) ...[
            SectionLabel('${entry.key} ${entry.value.length}'),
            const SizedBox(height: 4),
            for (final (other, edge, direct) in entry.value.take(30))
              HoverBuilder(
                onTap: () => onTap(other),
                builder: (context, hovered) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          direct
                              ? other.label
                              : '${byKey[edge.from]?.label} → ${byKey[edge.to]?.label}',
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
