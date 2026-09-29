import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';
import '../client.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final destinations = [
      for (final d in _destinations)
        (
          destination: d,
          active: d.owns(path),
          onTap: () =>
              context.go(d.path == '/companies' ? _companiesLocation : d.path),
        ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 1100;
        return Scaffold(
          key: _scaffoldKey,
          drawer: desktop
              ? null
              : Drawer(
                  width: 288,
                  backgroundColor: c.inverse,
                  child: _DeskNavigation(
                    destinations: [
                      for (final item in destinations)
                        (
                          destination: item.destination,
                          active: item.active,
                          onTap: () {
                            _scaffoldKey.currentState?.closeDrawer();
                            item.onTap();
                          },
                        ),
                    ],
                    onClose: () => _scaffoldKey.currentState?.closeDrawer(),
                  ),
                ),
          backgroundColor: c.background,
          body: Row(
            children: [
              if (desktop) _DeskNavigation(destinations: destinations),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(destinations: destinations, desktop: desktop),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeskNavigation extends StatelessWidget {
  const _DeskNavigation({required this.destinations, this.onClose});
  final VoidCallback? onClose;
  final List<({_Destination destination, bool active, VoidCallback onTap})>
  destinations;
  static const icons = [
    Icons.home_outlined,
    Icons.bar_chart,
    Icons.business_outlined,
    Icons.filter_alt_outlined,
    Icons.hub_outlined,
    Icons.account_tree_outlined,
    Icons.bookmarks_outlined,
    Icons.storage_outlined,
  ];
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      width: onClose == null ? 204 : 288,
      color: c.inverse,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 12, 28),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: context.shape.borderRadius,
                    child: Image.asset(
                      'assets/brand/alfinder-logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      '알파인더',
                      style: t.body(
                        17,
                        color: c.onInverse,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      tooltip: '메뉴 닫기',
                      onPressed: onClose,
                      icon: Icon(Icons.close, color: c.onInverse, size: 22),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: destinations[i].active
                            ? c.onInverse.withValues(alpha: .13)
                            : c.inverse,
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          dense: true,
                          minTileHeight: 46,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: Icon(
                            icons[i],
                            size: 19,
                            color: c.onInverse.withValues(
                              alpha: destinations[i].active ? 1 : .65,
                            ),
                          ),
                          title: Text(
                            destinations[i].destination.label,
                            style: t.body(
                              14,
                              color: c.onInverse.withValues(
                                alpha: destinations[i].active ? 1 : .72,
                              ),
                              weight: destinations[i].active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: destinations[i].destination.path == '/data'
                              ? const _IngestIndicator()
                              : null,
                          selected: destinations[i].active,
                          onTap: destinations[i].onTap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (context.isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(color: c.onInverse.withValues(alpha: .15)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '관리자',
                        style: t.label(
                          color: c.onInverse.withValues(alpha: .5),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.storage_outlined,
                        size: 20,
                        color: c.onInverse,
                      ),
                      title: Text(
                        '데이터 관리',
                        style: t.body(14, color: c.onInverse),
                      ),
                      selected: GoRouterState.of(context).uri.path == '/data',
                      onTap: () {
                        onClose?.call();
                        context.go('/data');
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.manage_accounts_outlined,
                        size: 20,
                        color: c.onInverse,
                      ),
                      title: Text(
                        '회원 관리',
                        style: t.body(14, color: c.onInverse),
                      ),
                      selected:
                          GoRouterState.of(context).uri.path ==
                          '/admin/accounts',
                      selectedTileColor: c.onInverse.withValues(alpha: .13),
                      onTap: () {
                        onClose?.call();
                        context.go('/admin/accounts');
                      },
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  onClose?.call();
                  context.go('/about');
                },
                child: Text(
                  '서비스 소개',
                  style: t.body(12, color: c.onInverse.withValues(alpha: .7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.destinations, required this.desktop});
  final bool desktop;
  final List<({_Destination destination, bool active, VoidCallback onTap})>
  destinations;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          if (GoRouter.of(context).canPop())
            IconButton(
              tooltip: '이전 화면',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          if (!desktop)
            IconButton(
              tooltip: '전체 메뉴',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, size: 22),
            ),
          Text(
            destinations
                    .where((d) => d.active)
                    .firstOrNull
                    ?.destination
                    .label ??
                '알파인더',
            style: t.body(14, color: c.textSecondary, weight: FontWeight.w600),
          ),
          const Spacer(),
          if (desktop)
            const _GlobalSearch()
          else
            IconButton(
              tooltip: '기업 · 인물 · 테마 · 메뉴 검색',
              icon: const Icon(Icons.search, size: 21),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _SearchDialog(),
              ),
            ),
          const SizedBox(width: 12),
          const _Account(),
        ],
      ),
    );
  }
}

/// 지금 계정의 역할(관리자 · 읽기 전용)과 로그아웃.
class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) => context.viewer == null
      ? TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('로그인'),
        )
      : IconButton(
          tooltip: context.viewer == null ? '로그인' : '내 계정',
          icon: Icon(
            Icons.account_circle_outlined,
            color: context.colors.textSecondary,
            size: 24,
          ),
          onPressed: () =>
              context.go(context.viewer == null ? '/login' : '/account'),
        );
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
typedef _SearchLink = ({String title, String detail, String location});
typedef _Hits = ({
  List<CompanyListItem> companies,
  List<PersonHit> persons,
  List<_SearchLink> links,
});

const _noHits = (
  companies: <CompanyListItem>[],
  persons: <PersonHit>[],
  links: <_SearchLink>[],
);

/// 기업은 시가총액 순 8곳, 인물은 이어진 기업이 많은 순 4명.
Future<_Hits> _searchAll(String query) async {
  final (page, persons, themes) = await (
    client.company.list(query: query, sort: CompanySort.marketCap, limit: 8),
    client.governance.searchPersons(query, limit: 4),
    client.theme.list(),
  ).wait;
  final q = query.toLowerCase().replaceAll(' ', '');
  bool matches(String text) =>
      text.toLowerCase().replaceAll(' ', '').contains(q);
  final links = <_SearchLink>[
    for (final theme in themes)
      if (matches(
        '${theme.theme.name} ${theme.theme.description ?? ''} ${theme.topNames.join(' ')}',
      ))
        (
          title: theme.theme.name,
          detail: '테마 · ${theme.memberCount}개 기업',
          location: AppRoutes.theme(theme.theme.id!),
        ),
    for (final item in const [
      (title: '시장', detail: '코스피 코스닥 지수 시가총액 업종', location: '/market'),
      (title: '기업', detail: '상장기업 종목 목록', location: '/companies'),
      (
        title: '스크리너',
        detail: 'PER PBR ROE 영업이익률 성장률 배당수익률 FCF 조건 검색',
        location: '/screen',
      ),
      (title: '기업 비교', detail: '재무 수익성 밸류에이션 비교', location: '/compare'),
      (title: '관계망', detail: '주주 임원 고객 공급 출자 연결', location: '/graph'),
      (title: '지분 묶음', detail: '기업집단 지배구조 계열사', location: '/groups'),
      (title: '테마', detail: '투자 아이디어 관련 기업 묶음', location: '/themes'),
      (title: '서비스 소개', detail: '사용법 도움말 출처', location: '/about'),
    ])
      if (matches('${item.title} ${item.detail}')) item,
  ];
  return (companies: page.items, persons: persons, links: links);
}

/// 검색 결과 목록: 기업 다음에 인물.
class _HitList extends StatelessWidget {
  const _HitList({
    required this.hits,
    required this.onCompany,
    required this.onPerson,
    required this.onLocation,
  });

  final _Hits hits;
  final ValueChanged<CompanyListItem> onCompany;
  final ValueChanged<PersonHit> onPerson;
  final ValueChanged<String> onLocation;

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
        for (final link in hits.links)
          row(
            onTap: () => onLocation(link.location),
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(link.title, style: t.body(13.5)),
                    Text(
                      link.detail,
                      style: t.body(11.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

/// 검색 대기, 실패, 빈 결과를 데스크톱과 모바일에서 동일하게 표시한다.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.loading,
    required this.failed,
    required this.hits,
    required this.onCompany,
    required this.onPerson,
    required this.onLocation,
  });

  final bool loading;
  final bool failed;
  final _Hits hits;
  final ValueChanged<CompanyListItem> onCompany;
  final ValueChanged<PersonHit> onPerson;
  final ValueChanged<String> onLocation;

  @override
  Widget build(BuildContext context) {
    if (!loading &&
        !failed &&
        (hits.companies.isNotEmpty ||
            hits.persons.isNotEmpty ||
            hits.links.isNotEmpty)) {
      return _HitList(
        hits: hits,
        onCompany: onCompany,
        onPerson: onPerson,
        onLocation: onLocation,
      );
    }
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            if (loading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Expanded(
              child: Text(
                loading
                    ? '검색 중…'
                    : failed
                    ? '검색하지 못했습니다. 검색어를 다시 입력해 주세요.'
                    : '검색 결과가 없습니다.',
                style: context.typo.body(
                  13.5,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
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
  bool _loading = false;
  bool _failed = false;
  int _request = 0;

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
    final request = ++_request;
    final query = q.trim();
    _loading = query.isNotEmpty;
    _failed = false;
    _setHits(_noHits, show: query.isNotEmpty);
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final hits = await _searchAll(query);
        if (!mounted || request != _request) return;
        _loading = false;
        _setHits(hits, show: true);
      } catch (_) {
        if (!mounted || request != _request) return;
        _loading = false;
        _failed = true;
        _setHits(_noHits, show: true);
      }
    });
  }

  void _setHits(_Hits hits, {bool show = false}) {
    _hits = hits;
    _overlay?.remove();
    _overlay = null;
    if (!show) return;
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
  }

  void _dismiss() {
    _debounce?.cancel();
    _request++;
    _loading = false;
    _failed = false;
    _setHits(_noHits);
  }

  void _go(String location) {
    _controller.clear();
    _focus.unfocus();
    _dismiss();
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
            child: _SearchResults(
              loading: _loading,
              failed: _failed,
              hits: _hits,
              onCompany: (item) => _go(AppRoutes.company(item.corpCode)),
              onPerson: (p) => _go(AppRoutes.person(p.personId)),
              onLocation: _go,
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
            } else if (_hits.links.isNotEmpty) {
              _go(_hits.links.first.location);
            } else if (_hits.persons.isNotEmpty) {
              _go(AppRoutes.person(_hits.persons.first.personId));
            }
          },
          onTapOutside: (_) {
            _focus.unfocus();
            _dismiss();
          },
          style: t.body(13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: '기업 · 인물 · 테마 · 메뉴 검색',
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
  bool _loading = false;
  bool _failed = false;
  int _request = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    final request = ++_request;
    final query = q.trim();
    setState(() {
      _hits = _noHits;
      _loading = query.isNotEmpty;
      _failed = false;
    });
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final hits = await _searchAll(query);
        if (!mounted || request != _request) return;
        setState(() {
          _hits = hits;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
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
                } else if (_hits.links.isNotEmpty) {
                  _go(_hits.links.first.location);
                } else if (_hits.persons.isNotEmpty) {
                  _go(AppRoutes.person(_hits.persons.first.personId));
                }
              },
              style: t.body(15),
              decoration: InputDecoration(
                hintText: '기업 · 인물 · 테마 · 메뉴 검색',
                prefixIcon: Icon(Icons.search, color: c.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            if (_controller.text.trim().isNotEmpty)
              _SearchResults(
                loading: _loading,
                failed: _failed,
                hits: _hits,
                onCompany: (item) => _go(AppRoutes.company(item.corpCode)),
                onPerson: (p) => _go(AppRoutes.person(p.personId)),
                onLocation: _go,
              ),
          ],
        ),
      ),
    );
  }
}
