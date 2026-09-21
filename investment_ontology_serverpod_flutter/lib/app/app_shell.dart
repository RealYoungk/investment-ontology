import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';
import '../client.dart';
import '../features/financials/financial_metrics.dart';
import 'ingest_monitor.dart';
import 'router.dart';

/// 맨 위 메뉴 한 칸.
class _Destination {
  const _Destination(this.label, this.path, {this.matches = const []});

  final String label;
  final String path;

  /// 이 메뉴에 속하는 다른 경로 (예: 기업 상세는 "기업").
  final List<String> matches;

  bool owns(String location) =>
      location.startsWith(path) || matches.any(location.startsWith);
}

const _destinations = [
  _Destination('시장', '/market'),
  _Destination(
    '기업',
    '/companies',
    matches: ['/company/', '/reports/', '/person/'],
  ),
  _Destination('관계망', '/graph'),
  _Destination('테마', '/themes'),
  _Destination('검수', '/review'),
  _Destination('데이터', '/data'),
];

/// 모든 화면을 감싸는 틀: 맨 위 메뉴(시장 · 기업 · 관계망 · 테마 · 검수 · 데이터) + 본문.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// 지금 경로와 검색어 (`/companies?market=kospi`).
  final Uri location;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// 기업 목록으로 돌아갈 때 쓰던 필터를 그대로 되살리기 위한 마지막 목록 주소.
  String _companiesLocation = '/companies';

  @override
  void initState() {
    super.initState();
    _remember();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remember();
  }

  void _remember() {
    if (widget.location.path == '/companies') {
      _companiesLocation = widget.location.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = widget.location.path;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            destinations: [
              for (final d in _destinations)
                (
                  destination: d,
                  active: d.owns(path),
                  onTap: () => context.go(
                    d.path == '/companies' ? _companiesLocation : d.path,
                  ),
                ),
            ],
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.destinations});

  final List<({_Destination destination, bool active, VoidCallback onTap})>
  destinations;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = PageFrame.gutter(constraints.maxWidth);
        final compact = constraints.maxWidth < PageFrame.compactBreakpoint;
        return Container(
          height: 56,
          padding: EdgeInsets.symmetric(horizontal: pad),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(
              bottom: BorderSide(color: c.borderStrong, width: 1.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                Center(
                  child: Text(
                    'INVESTMENT ONTOLOGY',
                    style: t.label(color: c.accent),
                  ),
                ),
                const SizedBox(width: AppSpace.xxl),
              ],
              // 좁은 화면에서는 메뉴가 넘치지 않게 가로로 밀어 본다.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final d in destinations)
                        _NavItem(
                          label: d.destination.label,
                          active: d.active,
                          onTap: d.onTap,
                          trailing: d.destination.path == '/data'
                              ? const _IngestIndicator()
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
              if (constraints.maxWidth >= 1100) ...[
                const Center(child: _GlobalSearch()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return HoverBuilder(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: hovered && !active ? c.surfaceHover : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: active ? c.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.body(
                15,
                color: active ? c.textPrimary : c.textSecondary,
                weight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpace.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 수집이 돌고 있으면 "데이터" 메뉴 옆에 깜빡이는 점.
class _IngestIndicator extends StatelessWidget {
  const _IngestIndicator();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: IngestMonitor.instance.running,
      builder: (context, running, _) => running
          ? Tooltip(
              message: '수집 중',
              child: StatusDot(
                color: context.colors.accent,
                label: '',
                pulsing: true,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// 어느 화면에서든 기업으로 바로 가는 검색.
class _GlobalSearch extends StatefulWidget {
  const _GlobalSearch();

  @override
  State<_GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<_GlobalSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  OverlayEntry? _overlay;
  List<CompanyListItem> _results = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _overlay?.remove();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final query = q.trim();
      if (query.isEmpty) {
        _setResults(const []);
        return;
      }
      try {
        final page = await client.company.list(
          query: query,
          sort: CompanySort.marketCap,
          limit: 8,
        );
        if (mounted && _controller.text.trim() == query) {
          _setResults(page.items);
        }
      } catch (_) {}
    });
  }

  void _setResults(List<CompanyListItem> items) {
    _results = items;
    _overlay?.remove();
    _overlay = null;
    if (items.isEmpty) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _open(CompanyListItem item) {
    _controller.clear();
    _focus.unfocus();
    _setResults(const []);
    context.push(AppRoutes.company(item.corpCode));
  }

  Widget _buildOverlay(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Positioned(
      width: 320,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 4),
        child: Material(
          color: c.surface,
          elevation: 4,
          borderRadius: context.shape.borderRadius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in _results)
                HoverBuilder(
                  onTap: () => _open(item),
                  builder: (context, hovered) => Container(
                    color: hovered ? c.surfaceHover : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            item.stockCode ?? '',
                            style: t.numeric(12, color: c.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.body(13.5),
                          ),
                        ),
                        Text(
                          item.marketCap == null
                              ? ''
                              : formatKrw(item.marketCap),
                          style: t.numeric(11.5, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return CompositedTransformTarget(
      link: _link,
      child: SizedBox(
        width: 260,
        height: 36,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _search,
          onSubmitted: (_) {
            if (_results.isNotEmpty) _open(_results.first);
          },
          onTapOutside: (_) {
            _focus.unfocus();
            Future<void>.delayed(
              const Duration(milliseconds: 150),
              () => _setResults(const []),
            );
          },
          style: t.body(13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: '기업 바로 가기',
            prefixIcon: Icon(Icons.search, size: 18, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}
