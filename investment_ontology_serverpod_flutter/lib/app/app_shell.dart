import '../design/components/company_logo.dart';
import '../features/search/search_catalog.dart';
import '../design/components/navigation_menu.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';
import '../client.dart';
import '../features/auth/app_viewer.dart';
import '../features/financials/financial_metrics.dart';
import 'ingest_monitor.dart';
import '../features/monetization/ad_banner.dart';
import 'router.dart';
import '../features/watchlist/notification_bell.dart';

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
  _Destination('기업 찾기', '/screen', matches: ['/industries']),
  _Destination('기업 비교', '/compare'),
  _Destination('관계망', '/graph'),
  _Destination('관심종목', '/watchlist', matches: ['/notifications']),
  _Destination('투자 관점', '/insights'),
];

/// 모든 화면을 감싸는 틀: 맨 위 메뉴(시장 · 기업 · 스크리너 · 관계망 · 데이터) + 본문.
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

  Future<void> _openMenu(
    BuildContext context,
    List<({_Destination destination, bool active, VoidCallback onTap})>
    destinations,
  ) => showShadSheet<void>(
    useRootNavigator: true,
    context: context,
    side: ShadSheetSide.left,
    barrierLabel: '메뉴 닫기',
    builder: (sheetContext) => InheritedTheme.captureAll(
      context,
      Builder(
        builder: (sheetContext) => ShadSheet(
          constraints: BoxConstraints.tightFor(
            width: 288,
            height: MediaQuery.sizeOf(sheetContext).height,
          ),
          padding: EdgeInsets.zero,
          useSafeArea: false,
          scrollable: false,
          closeIcon: const SizedBox.shrink(),
          child: _DeskNavigation(
            destinations: [
              for (final item in destinations)
                (
                  destination: item.destination,
                  active: item.active,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    item.onTap();
                  },
                ),
            ],
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );

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
        final desktop = box.maxWidth >= 960;
        return Scaffold(
          backgroundColor: c.background,
          // Paint navigation after the nested route: its BlockSemantics must
          // not hide the persistent header/sidebar from assistive technology.
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Stack(
              children: [
                Positioned.fill(
                  left: 0,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: 64,
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(2),
                          child: PageFrameLeadScope(
                            leading:
                                const {'/market', '/companies'}.contains(path)
                                ? const AdBanner()
                                : null,
                            child: widget.child,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(1),
                          child: _TopBar(
                            destinations: destinations,
                            desktop: desktop,
                            onMenu: () => _openMenu(context, destinations),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeskNavigation extends StatefulWidget {
  const _DeskNavigation({required this.destinations, this.onClose});
  final VoidCallback? onClose;
  final List<({_Destination destination, bool active, VoidCallback onTap})>
  destinations;
  @override
  State<_DeskNavigation> createState() => _DeskNavigationState();
}

class _DeskNavigationState extends State<_DeskNavigation> {
  final controller = ShadSidebarController();
  static const icons = [
    LucideIcons.house,
    LucideIcons.chartColumn,
    LucideIcons.building2,
    LucideIcons.listFilter,
    LucideIcons.arrowLeftRight,
    LucideIcons.network,
    LucideIcons.star,
    LucideIcons.bookOpen,
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void go(String path) {
    widget.onClose?.call();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 100 || constraints.maxHeight < 220) {
        return const SizedBox.shrink();
      }
      return ShadSidebarScope(
        controller: controller,
        isMobile: true,
        inSheet: true,
        open: true,
        side: ShadSidebarSide.start,
        variant: ShadSidebarVariant.sidebar,
        collapsible: ShadSidebarCollapsible.none,
        collapsedWidth: 48,
        child: ShadSidebar(
          width: 288,
          header: Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.sm,
              right: AppSpace.sm,
              top: AppSpace.md,
              bottom: AppSpace.sm,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: context.shape.borderRadius,
                  child: Image.asset(
                    'assets/brand/alfinder-logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text('알파인더', style: context.typo.display(20))),
                ShadButton.ghost(
                  onPressed: widget.onClose,
                  enabled: widget.onClose != null,
                  child: Semantics(
                    label: '메뉴 닫기',
                    child: const Icon(LucideIcons.x, size: 18),
                  ),
                ),
              ],
            ),
          ),
          footer: ShadSidebarMenu(
            children: [
              ShadSidebarMenuButton(
                size: ShadSidebarMenuButtonSize.lg,
                leading: const Icon(LucideIcons.info, size: 18),
                onPressed: () => go('/about'),
                child: const Text('서비스 소개'),
              ),
            ],
          ),
          children: [
            ShadSidebarGroup(
              children: [
                ShadSidebarMenu(
                  children: [
                    for (var i = 0; i < widget.destinations.length; i++)
                      ShadSidebarMenuButton(
                        size: ShadSidebarMenuButtonSize.lg,
                        isActive: widget.destinations[i].active,
                        leading: Icon(icons[i], size: 18),
                        onPressed: widget.destinations[i].onTap,
                        child: Text(widget.destinations[i].destination.label),
                      ),
                    if (context.isAdmin) ...[
                      ShadSidebarMenuButton(
                        size: ShadSidebarMenuButtonSize.lg,
                        leading: const Icon(LucideIcons.database, size: 18),
                        trailing: const _IngestIndicator(),
                        onPressed: () => go('/data'),
                        child: const Text('데이터 관리'),
                      ),
                      ShadSidebarMenuButton(
                        size: ShadSidebarMenuButtonSize.lg,
                        leading: const Icon(
                          LucideIcons.usersRound,
                          size: 18,
                        ),
                        onPressed: () => go('/admin/accounts'),
                        child: const Text('회원 관리'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.destinations,
    required this.desktop,
    required this.onMenu,
  });
  final bool desktop;
  final VoidCallback onMenu;
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
            Semantics(
              container: true,
              label: '이전 화면',
              button: true,
              enabled: true,
              onTap: () => context.pop(),
              child: ExcludeSemantics(
                child: ShadIconButton.ghost(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                  semanticLabel: '이전 화면',
                ),
              ),
            ),
          if (!desktop)
            Semantics(
              container: true,
              label: '전체 메뉴',
              button: true,
              enabled: true,
              onTap: onMenu,
              child: ExcludeSemantics(
                child: ShadIconButton.ghost(
                  onPressed: onMenu,
                  icon: const Icon(LucideIcons.menu, size: 22),
                  semanticLabel: '전체 메뉴',
                ),
              ),
            ),
          if (!desktop) const SizedBox(width: AppSpace.sm),
          if (desktop) ...[
            Image.asset(
              'assets/brand/alfinder-logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: AppSpace.sm),
          ],
          Text(
            desktop
                ? '알파인더'
                : destinations
                          .where((d) => d.active)
                          .firstOrNull
                          ?.destination
                          .label ??
                      '알파인더',
            style: t.body(
              desktop ? 20 : 14,
              color: c.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          if (desktop) ...[
            const SizedBox(width: AppSpace.lg),
            AppNavigationMenu(
              entries: [
                for (final item in destinations)
                  NavigationEntry(
                    label: item.destination.label,
                    selected: item.active,
                    onPressed: item.onTap,
                  ),
              ],
            ),
            ShadButton.ghost(
              hoverBackgroundColor: ShadTheme.of(context).colorScheme.accent,
              onPressed: onMenu,
              child: const Text('더보기'),
            ),
          ],
          const Spacer(),
          const _MobileSearchButton(),
          const SizedBox(width: AppSpace.xs),
          const NotificationBell(),
          const SizedBox(width: AppSpace.xs),
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
      ? ShadButton.outline(
          hoverBackgroundColor: ShadTheme.of(context).colorScheme.accent,
          height: 36,
          onPressed: () => context.go('/login'),
          child: Flexible(child: const Text('로그인')),
        )
      : Semantics(
          container: true,
          label: context.viewer == null ? '로그인' : '내 계정',
          button: true,
          enabled: true,
          onTap: () =>
              context.go(context.viewer == null ? '/login' : '/account'),
          child: ExcludeSemantics(
            child: ShadIconButton.ghost(
              icon: Icon(
                LucideIcons.userRound,
                color: context.colors.textSecondary,
                size: 24,
              ),
              onPressed: () =>
                  context.go(context.viewer == null ? '/login' : '/account'),
              semanticLabel: context.viewer == null ? '로그인' : '내 계정',
            ),
          ),
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
          ? ShadTooltip(
              builder: (_) => Text('수집 중'),
              child: Semantics(
                tooltip: '수집 중',
                child: StatusDot(
                  color: context.colors.accent,
                  label: '',
                  pulsing: true,
                ),
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
  int companyTotal,
  int failedSources,
  String query,
});

const _noHits = (
  companies: <CompanyListItem>[],
  persons: <PersonHit>[],
  links: <_SearchLink>[],
  companyTotal: 0,
  failedSources: 0,
  query: '',
);

/// 기업은 시가총액 순 8곳, 인물은 이어진 기업이 많은 순 4명.
Future<_Hits> _searchAll(String query) async {
  final links = searchDestinations(query);
  var companies = <CompanyListItem>[];
  var persons = <PersonHit>[];
  var companyTotal = 0;
  var failedSources = 0;
  await Future.wait([
    () async {
      try {
        final page = await client.company.list(
          query: query,
          sort: CompanySort.marketCap,
          limit: 8,
        );
        companies = page.items;
        companyTotal = page.total;
      } catch (_) {
        failedSources++;
      }
    }(),
    () async {
      try {
        persons = await client.governance.searchPersons(query, limit: 4);
      } catch (_) {
        failedSources++;
      }
    }(),
  ]);
  if (failedSources > 0 &&
      links.isEmpty &&
      companies.isEmpty &&
      persons.isEmpty) {
    throw StateError('Search sources unavailable');
  }
  return (
    companies: companies,
    persons: persons,
    links: links,
    companyTotal: companyTotal,
    failedSources: failedSources,
    query: query,
  );
}

/// 검색 결과 목록: 기업 다음에 인물.
class _HitList extends StatelessWidget {
  const _HitList({
    required this.hits,
    this.selectedIndex = -1,
    this.selectedKey,
    required this.onCompany,
    required this.onPerson,
    required this.onLocation,
  });

  final _Hits hits;
  final int selectedIndex;
  final GlobalKey? selectedKey;
  final ValueChanged<CompanyListItem> onCompany;
  final ValueChanged<PersonHit> onPerson;
  final ValueChanged<String> onLocation;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    var rowIndex = 0;
    Widget row({required VoidCallback onTap, required List<Widget> children}) {
      final selected = rowIndex++ == selectedIndex;
      return Semantics(
        key: selected ? selectedKey : null,
        selected: selected,
        child: HoverBuilder(
          onTap: onTap,
          builder: (context, hovered) => Container(
            color: selected
                ? c.accentSubtle
                : hovered
                ? c.surfaceHover
                : c.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 8,
            ),
            child: Row(children: children),
          ),
        ),
      );
    }

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
              CompanyLogo(
                name: item.name,
                stockCode: item.stockCode,
                corpCode: item.corpCode,
                size: 28,
              ),
              const SizedBox(width: AppSpace.sm),
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
    this.selectedIndex = -1,
    this.selectedKey,
    required this.onCompany,
    required this.onPerson,
    required this.onLocation,
  });

  final bool loading;
  final bool failed;
  final _Hits hits;
  final int selectedIndex;
  final GlobalKey? selectedKey;
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hits.failedSources > 0)
            Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: Text(
                '일부 결과를 불러오지 못했습니다.',
                style: context.typo.body(12, color: context.colors.textMuted),
              ),
            ),
          _HitList(
            hits: hits,
            selectedIndex: selectedIndex,
            selectedKey: selectedKey,
            onCompany: onCompany,
            onPerson: onPerson,
            onLocation: onLocation,
          ),
          if (hits.companyTotal > hits.companies.length)
            ShadButton.ghost(
              onPressed: () => onLocation(
                Uri(
                  path: '/companies',
                  queryParameters: {'q': hits.query, 'sort': 'marketCap'},
                ).toString(),
              ),
              child: Flexible(
                child: Text('기업 검색 결과 ${hits.companyTotal}개 모두 보기'),
              ),
            ),
        ],
      );
    }
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            if (loading) ...[
              const ExcludeSemantics(child: ShadSpinner(size: 16)),
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

mixin _SearchKeyboard<T extends StatefulWidget> on State<T> {
  _Hits get _hits;
  TextEditingController get _controller;
  void _go(String location);
  void _refreshSelection();
  void _closeSearch();
  int _selectedIndex = -1;
  final _selectedKey = GlobalKey();
  List<String> get _locations => [
    for (final link in _hits.links) link.location,
    for (final company in _hits.companies) AppRoutes.company(company.corpCode),
    for (final person in _hits.persons) AppRoutes.person(person.personId),
  ];
  void _submitSelected() {
    if (_controller.value.composing.isValid &&
        !_controller.value.composing.isCollapsed) {
      return;
    }
    final locations = _locations;
    if (locations.isNotEmpty) {
      _go(
        locations[_selectedIndex < 0
            ? 0
            : _selectedIndex.clamp(0, locations.length - 1)],
      );
    }
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_controller.value.composing.isValid &&
        !_controller.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeSearch();
      return KeyEventResult.handled;
    }
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!down && !up) return KeyEventResult.ignored;
    final count = _locations.length;
    if (count == 0) return KeyEventResult.ignored;
    _selectedIndex = _selectedIndex < 0
        ? (down ? 0 : count - 1)
        : (_selectedIndex + (down ? 1 : -1)).clamp(0, count - 1);
    _refreshSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = _selectedKey.currentContext;
      if (mounted && selected != null) {
        Scrollable.ensureVisible(selected, alignment: 0.5);
      }
    });
    return KeyEventResult.handled;
  }
}

/// 어느 화면에서든 기업·인물로 바로 가는 검색.
class _GlobalSearch extends StatefulWidget {
  const _GlobalSearch();

  @override
  State<_GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<_GlobalSearch> with _SearchKeyboard {
  @override
  void _refreshSelection() => _overlay?.markNeedsBuild();
  @override
  void _closeSearch() {
    _focus.unfocus();
    _dismiss();
  }

  @override
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  OverlayEntry? _overlay;
  @override
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
    _selectedIndex = -1;
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

  @override
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.65,
              ),
              child: SingleChildScrollView(
                child: _SearchResults(
                  loading: _loading,
                  failed: _failed,
                  hits: _hits,
                  selectedIndex: _selectedIndex,
                  selectedKey: _selectedKey,
                  onCompany: (item) => _go(AppRoutes.company(item.corpCode)),
                  onPerson: (p) => _go(AppRoutes.person(p.personId)),
                  onLocation: _go,
                ),
              ),
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
        child: Focus(
          onKeyEvent: _onSearchKey,
          child: ShadInput(
            placeholder: Text('기업 · 인물 · 메뉴 검색'),
            leading: Icon(LucideIcons.search, size: 18, color: c.textSecondary),
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: _search,
            onSubmitted: (_) => _submitSelected(),
            style: t.body(13.5),
            onPressedOutside: (_) {
              _focus.unfocus();
              _dismiss();
            },
          ),
        ),
      ),
    );
  }
}

/// Keep the real editor mounted so its keyboard request runs in the icon's
/// user gesture, not in a later dialog build (which iOS Safari rejects).
class _MobileSearchButton extends StatefulWidget {
  const _MobileSearchButton();

  @override
  State<_MobileSearchButton> createState() => _MobileSearchButtonState();
}

class _MobileSearchButtonState extends State<_MobileSearchButton> {
  final _dialogKey = GlobalKey<_SearchDialogState>();
  OverlayEntry? _entry;
  LocalHistoryEntry? _history;
  bool _open = false;
  bool _disposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final entry = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: Offstage(
            offstage: !_open,
            child: Stack(
              children: [
                ModalBarrier(
                  color: Theme.of(context).colorScheme.scrim
                      .withValues(alpha: .54),
                  dismissible: true,
                  onDismiss: _close,
                  semanticsLabel: MaterialLocalizations.of(context)
                      .modalBarrierDismissLabel,
                ),
                _SearchDialog(key: _dialogKey, onClose: _close),
              ],
            ),
          ),
        ),
      );
      _entry = entry;
      Overlay.of(context).insert(entry);
    });
  }

  void _show() {
    if (_open || _dialogKey.currentState == null) return;
    _open = true;
    _history = LocalHistoryEntry(onRemove: _hide);
    ModalRoute.of(context)?.addLocalHistoryEntry(_history!);
    _entry!.markNeedsBuild();
    _dialogKey.currentState!.activateSearch();
  }

  void _hide() {
    _history = null;
    if (_disposing) return;
    _open = false;
    _dialogKey.currentState?.deactivateSearch();
    _entry?.markNeedsBuild();
  }

  void _close() {
    final history = _history;
    if (history != null) {
      history.remove();
    } else {
      _hide();
    }
  }

  @override
  void dispose() {
    _disposing = true;
    _history?.remove();
    _entry?.remove();
    _entry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => const Text('기업 · 인물 · 메뉴 검색'),
    child: Semantics(
      container: true,
      label: '기업 · 인물 · 메뉴 검색',
      button: true,
      enabled: true,
      onTap: _show,
      child: ExcludeSemantics(
        child: ShadIconButton.ghost(
          width: 36,
          height: 36,
          hoverBackgroundColor: ShadTheme.of(context).colorScheme.accent,
          icon: Icon(
            LucideIcons.search,
            size: 20,
            color: context.colors.textSecondary,
          ),
          onPressed: _show,
          semanticLabel: '기업 · 인물 · 메뉴 검색',
        ),
      ),
    ),
  );
}

/// 좁은 화면의 검색: 같은 입력 요소를 유지한 채 팝업을 열고 닫는다.
class _SearchDialog extends StatefulWidget {
  const _SearchDialog({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> with _SearchKeyboard {
  final _focus = FocusNode(canRequestFocus: false, skipTraversal: true);

  void activateSearch() {
    _focus
      ..canRequestFocus = true
      ..skipTraversal = false
      ..requestFocus();
    // Commit synchronously while the browser still has user activation.
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  void deactivateSearch() {
    _focus
      ..unfocus()
      ..canRequestFocus = false
      ..skipTraversal = true;
    _debounce?.cancel();
    _request++;
    _controller.clear();
    setState(() {
      _hits = _noHits;
      _selectedIndex = -1;
      _loading = false;
      _failed = false;
    });
  }

  @override
  void _refreshSelection() => setState(() {});
  @override
  void _closeSearch() => widget.onClose();
  @override
  final _controller = TextEditingController();
  @override
  _Hits _hits = _noHits;
  Timer? _debounce;
  bool _loading = false;
  bool _failed = false;
  int _request = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    _selectedIndex = -1;
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

  @override
  void _go(String location) {
    final router = GoRouter.of(context);
    widget.onClose();
    router.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return ShadDialog(
      closeIcon: Builder(
        builder: (context) => Semantics(
          container: true,
          label: '닫기',
          button: true,
          onTap: () => Navigator.of(context).pop(),
          child: ExcludeSemantics(
            child: ShadIconButton.ghost(
              width: 20,
              height: 20,
              padding: EdgeInsets.zero,
              icon: const Icon(LucideIcons.x, size: 16),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      alignment: Alignment.topCenter,
      backgroundColor: c.surface,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Focus(
                onKeyEvent: _onSearchKey,
                child: ShadInput(
                  placeholder: Text('기업 · 인물 · 메뉴 검색'),
                  leading: Icon(LucideIcons.search, color: c.textSecondary),
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: _search,
                  onSubmitted: (_) => _submitSelected(),
                  style: t.body(16),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              if (_controller.text.trim().isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    child: _SearchResults(
                      loading: _loading,
                      failed: _failed,
                      hits: _hits,
                      selectedIndex: _selectedIndex,
                      selectedKey: _selectedKey,
                      onCompany: (item) =>
                          _go(AppRoutes.company(item.corpCode)),
                      onPerson: (p) => _go(AppRoutes.person(p.personId)),
                      onLocation: _go,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
