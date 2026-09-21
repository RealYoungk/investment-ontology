import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';
import 'ingest_monitor.dart';

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
  _Destination('테마', '/themes'),
  _Destination('검수', '/review'),
  _Destination('데이터', '/data'),
];

/// 모든 화면을 감싸는 틀: 맨 위 메뉴(시장 · 기업 · 테마 · 검수 · 데이터) + 본문.
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
