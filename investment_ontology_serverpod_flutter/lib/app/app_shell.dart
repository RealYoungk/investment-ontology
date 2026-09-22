import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';
import '../client.dart';
import '../features/auth/app_auth.dart';
import '../features/auth/app_viewer.dart';
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
  _Destination('홈', '/home'),
  _Destination('시장', '/market'),
  _Destination(
    '기업',
    '/companies',
    matches: ['/company/', '/reports/', '/person/'],
  ),
  _Destination('스크리너', '/screen', matches: ['/compare']),
  _Destination('관계망', '/graph'),
  _Destination('지분 묶음', '/groups'),
  _Destination('테마', '/themes'),
  _Destination('데이터', '/data'),
];

/// 모든 화면을 감싸는 틀: 맨 위 메뉴(시장 · 기업 · 스크리너 · 관계망 · 지분 묶음 · 테마 · 데이터) + 본문.
///
/// 검수 화면(`/review`)은 메뉴에 두지 않는다 — AI가 읽은 것은 대조 검수를 거쳐 스스로 확정하고,
/// 사람은 화면에 적힌 측정 정확도만 본다. 주소로는 여전히 열린다.
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
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      '투자 온톨로지',
                      style: t.body(
                        15,
                        color: c.accent,
                        weight: FontWeight.w700,
                      ),
                    ),
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
              if (constraints.maxWidth >= 1100)
                const Center(child: _GlobalSearch())
              else
                Center(
                  child: IconButton(
                    tooltip: '기업 · 인물 바로 가기',
                    icon: Icon(Icons.search, color: c.textPrimary),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _SearchDialog(),
                    ),
                  ),
                ),
              const SizedBox(width: AppSpace.md),
              const Center(child: _Account()),
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

/// 지금 계정의 역할(관리자 · 읽기 전용)과 로그아웃.
class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viewer = context.viewer;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewer != null)
          Tooltip(
            message: viewer.isAdmin
                ? '데이터를 바꿀 수 있습니다 (테마 · 수집 · 검수).'
                : '볼 수만 있습니다. 바꾸려면 관리자 권한이 필요합니다.',
            child: AppTag(
              label: viewer.roleLabel,
              color: viewer.isAdmin ? c.accent : c.textSecondary,
            ),
          ),
        const SizedBox(width: AppSpace.xs),
        AppIconButton(
          icon: Icons.logout,
          tooltip: '로그아웃',
          onPressed: () async {
            await AppAuth.signOut();
            // 다음에 로그인하는 사람이 보던 화면으로 들어가지 않게 첫 화면으로 돌린다.
            // (로그아웃 순간 로그인 문이 라우터를 내리므로 보던 화면은 이미 사라졌다.)
            AppRoutes.router.go('/market');
          },
        ),
      ],
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

/// 기업·인물 검색 결과.
typedef _Hits = ({List<CompanyListItem> companies, List<PersonHit> persons});

const _noHits = (companies: <CompanyListItem>[], persons: <PersonHit>[]);

/// 기업은 시가총액 순 8곳, 인물은 이어진 기업이 많은 순 4명.
Future<_Hits> _searchAll(String query) async {
  final (page, persons) = await (
    client.company.list(query: query, sort: CompanySort.marketCap, limit: 8),
    client.governance.searchPersons(query, limit: 4),
  ).wait;
  return (companies: page.items, persons: persons);
}

/// 검색 결과 목록: 기업 다음에 인물.
class _HitList extends StatelessWidget {
  const _HitList({
    required this.hits,
    required this.onCompany,
    required this.onPerson,
  });

  final _Hits hits;
  final ValueChanged<CompanyListItem> onCompany;
  final ValueChanged<PersonHit> onPerson;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    Widget row({required VoidCallback onTap, required List<Widget> children}) =>
        HoverBuilder(
          onTap: onTap,
          builder: (context, hovered) => Container(
            color: hovered ? c.surfaceHover : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 8,
            ),
            child: Row(children: children),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in hits.companies)
          row(
            onTap: () => onCompany(item),
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
                item.marketCap == null ? '' : formatKrw(item.marketCap),
                style: t.numeric(11.5, color: c.textMuted),
              ),
            ],
          ),
        if (hits.persons.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              2,
            ),
            child: Text('인물', style: t.label(color: c.textSecondary)),
          ),
          for (final p in hits.persons)
            row(
              onTap: () => onPerson(p),
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    p.birthYear == null ? '' : '${p.birthYear}년생',
                    style: t.numeric(11.5, color: c.textSecondary),
                  ),
                ),
                Text(p.name, style: t.body(13.5)),
                if (p.estimated)
                  Text(' · 추정', style: t.body(11.5, color: c.textMuted)),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    p.companyNames.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: t.body(11.5, color: c.textMuted),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

/// 어느 화면에서든 기업·인물로 바로 가는 검색.
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
  _Hits _hits = _noHits;
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
        _setHits(_noHits);
        return;
      }
      try {
        final hits = await _searchAll(query);
        if (mounted && _controller.text.trim() == query) _setHits(hits);
      } catch (_) {}
    });
  }

  void _setHits(_Hits hits) {
    _hits = hits;
    _overlay?.remove();
    _overlay = null;
    if (hits.companies.isEmpty && hits.persons.isEmpty) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _go(String location) {
    _controller.clear();
    _focus.unfocus();
    _setHits(_noHits);
    context.push(location);
  }

  Widget _buildOverlay(BuildContext context) {
    final c = context.colors;
    return Positioned(
      width: 360,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 4),
        // 결과 목록을 검색창의 일부로 묶어, 누르는 동안 "바깥을 눌렀다"로 닫히지 않게 한다.
        child: TextFieldTapRegion(
          child: Material(
            color: c.surface,
            elevation: 4,
            borderRadius: context.shape.borderRadius,
            child: _HitList(
              hits: _hits,
              onCompany: (item) => _go(AppRoutes.company(item.corpCode)),
              onPerson: (p) => _go(AppRoutes.person(p.personId)),
            ),
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
            if (_hits.companies.isNotEmpty) {
              _go(AppRoutes.company(_hits.companies.first.corpCode));
            } else if (_hits.persons.isNotEmpty) {
              _go(AppRoutes.person(_hits.persons.first.personId));
            }
          },
          onTapOutside: (_) {
            _focus.unfocus();
            _setHits(_noHits);
          },
          style: t.body(13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: '기업 · 인물 바로 가기',
            prefixIcon: Icon(Icons.search, size: 18, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// 좁은 화면의 검색: 검색창 대신 아이콘을 누르면 뜬다.
class _SearchDialog extends StatefulWidget {
  const _SearchDialog();

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();
  _Hits _hits = _noHits;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final query = q.trim();
      if (query.isEmpty) {
        setState(() => _hits = _noHits);
        return;
      }
      try {
        final hits = await _searchAll(query);
        if (mounted && _controller.text.trim() == query) {
          setState(() => _hits = hits);
        }
      } catch (_) {}
    });
  }

  void _go(String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.all(AppSpace.md),
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: context.shape.borderRadius,
        side: BorderSide(color: c.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _search,
              onSubmitted: (_) {
                if (_hits.companies.isNotEmpty) {
                  _go(AppRoutes.company(_hits.companies.first.corpCode));
                } else if (_hits.persons.isNotEmpty) {
                  _go(AppRoutes.person(_hits.persons.first.personId));
                }
              },
              style: t.body(15),
              decoration: InputDecoration(
                hintText: '회사명 · 종목코드 · 인물',
                prefixIcon: Icon(Icons.search, color: c.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            _HitList(
              hits: _hits,
              onCompany: (item) => _go(AppRoutes.company(item.corpCode)),
              onPerson: (p) => _go(AppRoutes.person(p.personId)),
            ),
          ],
        ),
      ),
    );
  }
}
