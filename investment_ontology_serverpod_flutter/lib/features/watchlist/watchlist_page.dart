import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'watchlist_store.dart';
import 'search_keyboard.dart';
import '../monetization/membership_offer.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key, this.addCode, this.store});
  final String? addCode;
  final WatchlistStore? store;
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with WidgetsBindingObserver {
  late final store = widget.store ?? WatchlistStore.instance;
  final _searchState = ValueNotifier<int>(0);
  BuildContext? _searchContext;
  bool _unreadOnly = false;
  bool _mobileUpdates = true;
  String? _selectedCode;
  String? _notice;
  bool _busy = false;
  final _companyMenus = <String, ShadPopoverController>{};
  bool _adding = false;
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  int _searchEpoch = 0;
  List<CompanyListItem> _results = [];
  bool _searching = false;
  String? _searchError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.refresh();
    if (widget.addCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSave());
    }
  }

  Future<void> _restoreSave() async {
    final code = widget.addCode;
    if (code == null || !RegExp(r'^\d{8}$').hasMatch(code) || _adding) return;
    _adding = true;
    // Idempotent server add, even when the store is still loading.
    await _action(() async {
      await client.watchlist.add(code);
      await store.refresh();
    });
    if (mounted && _notice == null) context.go('/watchlist');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      store.refresh();
    }
  }

  Future<void> _action(Future<void> Function() run) async {
    if (_busy) return;
    _updateSearch(() {
      _busy = true;
      _notice = null;
    });
    try {
      await run();
    } on WatchlistError catch (e) {
      if (mounted) {
        if (e.code == 'limit' && store.view?.paid == false) {
          final searchContext = _searchContext;
          if (searchContext != null && searchContext.mounted) {
            Navigator.pop(searchContext);
          }
          await showMembershipOffer(context);
        } else {
          _updateSearch(() => _notice = e.message);
        }
      }
    } catch (_) {
      if (mounted) _updateSearch(() => _notice = '요청을 처리하지 못했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) _updateSearch(() => _busy = false);
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    final epoch = ++_searchEpoch;
    final query = value.trim();
    _updateSearch(() {
      _results = [];
      _searchError = null;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final page = await client.company.list(query: query, limit: 8);
        if (mounted && epoch == _searchEpoch) {
          _updateSearch(() {
            _results = page.items;
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted && epoch == _searchEpoch) {
          _updateSearch(() {
            _searchError = '기업 검색에 실패했습니다.';
            _searching = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    for (final menu in _companyMenus.values) {
      menu.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _query.dispose();
    _searchFocus.dispose();
    releaseSearchKeyboard();
    _searchState.dispose();
    super.dispose();
  }

  String _date(DateTime date) {
    final d = date.toUtc().add(const Duration(hours: 9));
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Widget _panel(Widget child) => ShadCard(
    padding: EdgeInsets.zero,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _empty(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.xl,
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: context.colors.textMuted),
        const SizedBox(height: AppSpace.md),
        Text(title, style: context.typo.body(16, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
      ],
    ),
  );

  String _scanLabel(WatchlistView view) => !view.workerEnabled
      ? '자동 공시 확인 대기'
      : switch (view.scanStatus) {
          'failed' => '공시 확인 재시도 중',
          'notConfigured' => '공시 수집 연결 대기',
          'budgetWaiting' => '다음 공시 확인 대기',
          'running' => '공시 확인 중',
          'catchingUp' => '지난 공시 확인 중',
          _ =>
            view.lastCheckedAt == null
                ? '첫 공시 확인 대기'
                : '확인 ${_date(view.lastCheckedAt!)}',
        };

  Widget _companies(WatchlistView view) {
    final c = context.colors;
    final t = context.typo;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '지켜보는 기업',
                    style: t.body(16, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${view.companies.length}/${view.limit}',
                  style: t.body(12, color: c.textMuted),
                ),
              ],
            ),
          ),
          Semantics(
            selected: _selectedCode == null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (_selectedCode == null) ? c.surfaceHover : null,
              ),
              child: ShadButton.ghost(
                width: double.infinity,
                height: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                onPressed: () => setState(() {
                  _selectedCode = null;
                  _mobileUpdates = true;
                }),
                child: Flexible(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 20,
                        color: _selectedCode == null ? c.accent : c.textMuted,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          '전체 기업',
                          style: t.body(14, weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        '${view.updates.where((u) => !u.read).length}',
                        style: t.body(12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          for (final company in view.companies) ...[
            Semantics(
              selected: _selectedCode == company.corpCode,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (_selectedCode == company.corpCode)
                      ? c.surfaceHover
                      : null,
                ),
                child: ShadButton.ghost(
                  width: double.infinity,
                  height: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm,
                  ),
                  onPressed: () => setState(() {
                    _selectedCode = company.corpCode;
                    _mobileUpdates = true;
                  }),
                  child: Flexible(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: t.body(15, weight: FontWeight.w600),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpace.xs,
                                ),
                                child: Text(
                                  '${company.stockCode ?? company.corpCode} · ${!company.active
                                      ? '알림 일시 중지'
                                      : !company.monitoringReady
                                      ? '첫 확인 대기'
                                      : company.unreadCount > 0
                                      ? '새 공시 ${company.unreadCount}건'
                                      : '새 공시 없음'}',
                                  style: t.body(
                                    12,
                                    color: company.unreadCount > 0
                                        ? c.accent
                                        : c.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        ShadContextMenu(
                          controller: _companyMenus.putIfAbsent(
                            company.corpCode,
                            ShadPopoverController.new,
                          ),
                          items: [
                            ShadContextMenuItem(
                              enabled: !_busy,
                              onPressed: () => ((value) {
                                if (value == 'detail') {
                                  context.push(
                                    AppRoutes.company(company.corpCode),
                                  );
                                  return;
                                }
                                _action(() async {
                                  if (value == 'remove') {
                                    await store.toggle(company.corpCode);
                                    if (mounted &&
                                        _selectedCode == company.corpCode) {
                                      setState(() => _selectedCode = null);
                                    }
                                  } else if (value == 'prioritize') {
                                    await client.watchlist.prioritize(
                                      company.corpCode,
                                    );
                                    await store.refresh();
                                  } else {
                                    await client.watchlist.mute(
                                      company.corpCode,
                                      !company.muted,
                                    );
                                    await store.refresh();
                                  }
                                });
                              })('detail'),
                              child: Text('기업 상세 보기'),
                            ),
                            if (company.active)
                              ShadContextMenuItem(
                                enabled: !_busy,
                                onPressed: () => ((value) {
                                  if (value == 'detail') {
                                    context.push(
                                      AppRoutes.company(company.corpCode),
                                    );
                                    return;
                                  }
                                  _action(() async {
                                    if (value == 'remove') {
                                      await store.toggle(company.corpCode);
                                      if (mounted &&
                                          _selectedCode == company.corpCode) {
                                        setState(() => _selectedCode = null);
                                      }
                                    } else if (value == 'prioritize') {
                                      await client.watchlist.prioritize(
                                        company.corpCode,
                                      );
                                      await store.refresh();
                                    } else {
                                      await client.watchlist.mute(
                                        company.corpCode,
                                        !company.muted,
                                      );
                                      await store.refresh();
                                    }
                                  });
                                })('mute'),
                                child: Text(
                                  company.muted ? '기기 알림 켜기' : '기기 알림 끄기',
                                ),
                              ),
                            if (!company.active)
                              ShadContextMenuItem(
                                enabled: !_busy,
                                onPressed: () => ((value) {
                                  if (value == 'detail') {
                                    context.push(
                                      AppRoutes.company(company.corpCode),
                                    );
                                    return;
                                  }
                                  _action(() async {
                                    if (value == 'remove') {
                                      await store.toggle(company.corpCode);
                                      if (mounted &&
                                          _selectedCode == company.corpCode) {
                                        setState(() => _selectedCode = null);
                                      }
                                    } else if (value == 'prioritize') {
                                      await client.watchlist.prioritize(
                                        company.corpCode,
                                      );
                                      await store.refresh();
                                    } else {
                                      await client.watchlist.mute(
                                        company.corpCode,
                                        !company.muted,
                                      );
                                      await store.refresh();
                                    }
                                  });
                                })('prioritize'),
                                child: Text('이 기업 알림 활성화'),
                              ),
                            ShadContextMenuItem(
                              enabled: !_busy,
                              onPressed: () => ((value) {
                                if (value == 'detail') {
                                  context.push(
                                    AppRoutes.company(company.corpCode),
                                  );
                                  return;
                                }
                                _action(() async {
                                  if (value == 'remove') {
                                    await store.toggle(company.corpCode);
                                    if (mounted &&
                                        _selectedCode == company.corpCode) {
                                      setState(() => _selectedCode = null);
                                    }
                                  } else if (value == 'prioritize') {
                                    await client.watchlist.prioritize(
                                      company.corpCode,
                                    );
                                    await store.refresh();
                                  } else {
                                    await client.watchlist.mute(
                                      company.corpCode,
                                      !company.muted,
                                    );
                                    await store.refresh();
                                  }
                                });
                              })('remove'),
                              child: Text('관심등록 해제'),
                            ),
                          ],
                          child: Semantics(
                            container: true,
                            label: '${company.name} 관리',
                            button: true,
                            enabled: !_busy,
                            onTap: (!_busy)
                                ? () =>
                                      _companyMenus[company.corpCode]!.toggle()
                                : null,
                            child: ExcludeSemantics(
                              child: ShadIconButton.ghost(
                                enabled: !_busy,
                                semanticLabel: '${company.name} 관리',
                                onPressed: () =>
                                    _companyMenus[company.corpCode]!.toggle(),
                                icon: const Icon(LucideIcons.ellipsisVertical),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (view.companies.isEmpty)
            _empty(
              LucideIcons.star,
              '첫 기업을 담아보세요',
              '계속 살펴볼 기업을 관심종목에 추가하세요.',
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: ShadButton.ghost(
              onPressed: _openSearch,
              leading: const Icon(LucideIcons.plus, size: 18),
              child: Flexible(child: const Text('종목 추가')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feed(WatchlistView view) {
    final c = context.colors;
    final t = context.typo;
    final updates = view.updates
        .where(
          (u) =>
              (_selectedCode == null || u.corpCode == _selectedCode) &&
              (!_unreadOnly || !u.read),
        )
        .toList();
    final selected = view.companies
        .where((c) => c.corpCode == _selectedCode)
        .firstOrNull;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected == null ? '최근 업데이트' : '${selected.name} 업데이트',
                        style: t.body(18, weight: FontWeight.w700),
                      ),
                    ),
                    Semantics(
                      container: true,
                      label: '새로고침',
                      button: true,
                      enabled: !(store.loading),
                      onTap: (!(store.loading))
                          ? store.loading
                                ? null
                                : store.refresh
                          : null,
                      child: ExcludeSemantics(
                        child: ShadIconButton.ghost(
                          enabled: !(store.loading),
                          onPressed: store.loading ? null : store.refresh,
                          icon: const Icon(LucideIcons.refreshCw, size: 20),
                          semanticLabel: '새로고침',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '관심 기업의 새 공시를 한곳에서 확인하세요.',
                  style: t.body(13, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    IntrinsicWidth(
                      child: ShadToggle.outline(
                        value: !_unreadOnly,
                        onChanged: (_) => setState(() => _unreadOnly = false),
                        child: const Text('전체'),
                      ),
                    ),
                    IntrinsicWidth(
                      child: ShadToggle.outline(
                        value: _unreadOnly,
                        onChanged: (_) => setState(() => _unreadOnly = true),
                        child: const Text('읽지 않음'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (updates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
              child: _empty(
                LucideIcons.inbox,
                _unreadOnly ? '읽지 않은 공시가 없습니다' : '새 공시가 오면 여기에 모아드려요',
                view.companies.isEmpty
                    ? '기업을 추가하면 업데이트를 확인할 수 있습니다.'
                    : '처음 확인한 공시는 기준으로 삼고, 이후 새 공시부터 보여드립니다.',
              ),
            ),
          for (final update in updates) ...[
            ShadButton.ghost(
              width: double.infinity,
              height: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              onPressed: () => _action(() async {
                await launchUrl(
                  Uri.parse(update.url),
                  mode: LaunchMode.externalApplication,
                );
                await client.watchlist.markRead(update.noticeId);
                await store.refresh();
              }),
              child: Flexible(
                child: Row(
                  children: [
                    Icon(
                      update.read ? LucideIcons.fileText : LucideIcons.mail,
                      size: 22,
                      color: update.read ? c.textMuted : c.accent,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update.companyName,
                                style: t.body(12, color: c.textSecondary),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                update.title,
                                style: t.body(
                                  15,
                                  weight: update.read
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpace.sm),
                            child: Text(
                              '${_date(update.publishedAt)} · DART${update.title.contains('정정') ? ' · 정정 공시' : ''}',
                              style: t.body(12, color: c.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Icon(
                      LucideIcons.arrowUpRight,
                      size: 16,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Icon(LucideIcons.clock, size: 14, color: c.textMuted),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    _scanLabel(view),
                    style: t.body(12, color: c.textMuted),
                  ),
                ),
                ShadTooltip(
                  builder: (_) => Text(
                    !view.workerEnabled
                        ? '현재 개발 서버는 자동 수집이 꺼져 있습니다. 뉴스 알림은 기업 매칭 검증 후 제공할 예정입니다.'
                        : '뉴스 알림은 기업 매칭 검증 후 제공할 예정입니다.',
                  ),
                  child: Semantics(
                    tooltip: !view.workerEnabled
                        ? '현재 개발 서버는 자동 수집이 꺼져 있습니다. 뉴스 알림은 기업 매칭 검증 후 제공할 예정입니다.'
                        : '뉴스 알림은 기업 매칭 검증 후 제공할 예정입니다.',
                    child: Icon(
                      LucideIcons.info,
                      size: 16,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSearch(VoidCallback update) {
    setState(update);
    _searchState.value++;
  }

  Future<void> _openSearch() async {
    _searchFocus.unfocus();
    prepareSearchKeyboard();
    _debounce?.cancel();
    _searchEpoch++;
    _query.clear();
    _results = [];
    _searchError = null;
    _searching = false;
    Widget content(BuildContext modalContext) {
      _searchContext = modalContext;
      return ListenableBuilder(
        listenable: Listenable.merge([store, _searchState]),
        builder: (context, _) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * .75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _searchPanel(),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Text(_notice!),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (MediaQuery.sizeOf(context).width < 600) {
      await showShadSheet<void>(
        useRootNavigator: true,
        context: context,
        side: ShadSheetSide.bottom,
        barrierLabel: '검색 닫기',
        builder: (_) => InheritedTheme.captureAll(
          context,
          Builder(
            builder: (context) => ShadSheet(
              closeIcon: const SizedBox.shrink(),
              scrollable: true,
              child: content(context),
            ),
          ),
        ),
      );
    } else {
      await showShadDialog<void>(
        context: context,
        builder: (overlayContext) => InheritedTheme.captureAll(
          context,
          Builder(
            builder: (context) => ShadDialog(
              closeIcon: const SizedBox.shrink(),
              child: Material(
                type: MaterialType.transparency,
                child: content(context),
              ),
            ),
          ),
        ),
        barrierLabel: '닫기',
      );
    }
    releaseSearchKeyboard();
    _searchContext = null;
  }

  Widget _searchPanel() => _panel(
    Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '관심종목 추가',
                  style: context.typo.body(16, weight: FontWeight.w700),
                ),
              ),
              Semantics(
                container: true,
                label: '검색 닫기',
                button: true,
                enabled: true,
                onTap: () => Navigator.pop(_searchContext!),
                child: ExcludeSemantics(
                  child: ShadIconButton.ghost(
                    onPressed: () => Navigator.pop(_searchContext!),
                    icon: const Icon(LucideIcons.x, size: 20),
                    semanticLabel: '검색 닫기',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ShadInput(
            autofocus: true,
            focusNode: _searchFocus,
            onPressedAlwaysCalled: true,
            controller: _query,
            onChanged: _search,
            placeholder: Text('기업명 또는 종목코드 검색'),
            leading: Icon(LucideIcons.search),
            onPressed: () {
              _searchFocus.requestFocus();
              SystemChannels.textInput.invokeMethod<void>('TextInput.show');
            },
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(AppSpace.md),
              child: Text('검색 중…'),
            ),
          if (_searchError != null) Text(_searchError!),
          if (!_searching &&
              _searchError == null &&
              _query.text.trim().isNotEmpty &&
              _results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpace.md),
              child: Text('검색 결과가 없습니다.'),
            ),
          for (final item in _results)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name),
                        Text(item.stockCode ?? item.corpCode),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Semantics(
                    container: true,
                    label: store.contains(item.corpCode) ? '관심등록 해제' : '관심등록',
                    button: true,
                    toggled: store.contains(item.corpCode),
                    enabled: !(_busy),
                    onTap: (!(_busy))
                        ? _busy
                              ? null
                              : () => _action(() => store.toggle(item.corpCode))
                        : null,
                    child: ExcludeSemantics(
                      child: ShadIconButton.ghost(
                        enabled: !(_busy),
                        icon: Icon(
                          LucideIcons.star,
                          color: store.contains(item.corpCode)
                              ? context.colors.accent
                              : context.colors.textMuted,
                        ),
                        onPressed: _busy
                            ? null
                            : () => _action(() => store.toggle(item.corpCode)),
                        semanticLabel: store.contains(item.corpCode)
                            ? '관심등록 해제'
                            : '관심등록',
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final view = store.view;
      final c = context.colors;
      final t = context.typo;
      return PageFrame(
        maxWidth: 1160,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관심종목', style: t.body(28, weight: FontWeight.w700)),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      '지켜보는 기업의 변화를 놓치지 마세요.',
                      style: t.body(14, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Semantics(
                container: true,
                label: '종목 추가',
                button: true,
                enabled: true,
                onTap: _openSearch,
                child: ExcludeSemantics(
                  child: ShadIconButton.ghost(
                    onPressed: _openSearch,
                    icon: const Icon(LucideIcons.plus),
                    semanticLabel: '종목 추가',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          if (view != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          IntrinsicWidth(
                            child: ShadToggle.outline(
                              value: !_mobileUpdates,
                              onChanged: (_) =>
                                  setState(() => _mobileUpdates = false),
                              child: Text('종목 ${view.companies.length}'),
                            ),
                          ),
                          IntrinsicWidth(
                            child: ShadToggle.outline(
                              value: _mobileUpdates,
                              onChanged: (_) =>
                                  setState(() => _mobileUpdates = true),
                              child: const Text('업데이트'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      if (_mobileUpdates) _feed(view) else _companies(view),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 310, child: _companies(view)),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(child: _feed(view)),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${view.paid ? '멤버십' : '무료 플랜'} · 최대 ${view.limit}개 기업',
                    style: t.body(12, color: c.textMuted),
                  ),
                ),
                ShadButton.ghost(
                  onPressed: () => context.push('/membership'),
                  child: Flexible(
                    child: Text(view.paid ? '멤버십 관리' : '20개로 늘리기'),
                  ),
                ),
              ],
            ),
          ] else if (store.loading)
            const Padding(
              padding: EdgeInsets.all(AppSpace.xl),
              child: Center(child: ShadSpinner()),
            ),
          if (store.error != null) ...[
            Text(store.error!, style: t.body(13, color: c.textSecondary)),
            ShadButton.ghost(
              onPressed: store.refresh,
              child: Flexible(child: const Text('다시 시도')),
            ),
          ],
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Text(_notice!, style: t.body(13, color: c.textSecondary)),
            ),
        ],
      );
    },
  );
}
