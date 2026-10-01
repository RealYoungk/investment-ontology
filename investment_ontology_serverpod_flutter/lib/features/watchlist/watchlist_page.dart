import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'watchlist_store.dart';
import 'push_platform.dart';

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
  String _push = 'checking';
  String? _notice;
  bool _busy = false;
  bool _adding = false;
  final _query = TextEditingController();
  Timer? _debounce;
  int _searchEpoch = 0;
  List<CompanyListItem> _results = [];
  bool _searching = false;
  String? _searchError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPush();
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
      _checkPush();
    }
  }

  Future<void> _checkPush() async {
    try {
      final status = await pushStatus();
      if (mounted) setState(() => _push = status);
    } catch (_) {
      if (mounted) setState(() => _push = 'unsupported');
    }
  }

  Future<void> _action(Future<void> Function() run) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await run();
    } on WatchlistError catch (e) {
      if (mounted) setState(() => _notice = e.message);
    } catch (_) {
      if (mounted) setState(() => _notice = '요청을 처리하지 못했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    final epoch = ++_searchEpoch;
    final query = value.trim();
    setState(() {
      _results = [];
      _searchError = null;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final page = await client.company.list(query: query, limit: 8);
        if (mounted && epoch == _searchEpoch) {
          setState(() {
            _results = page.items;
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted && epoch == _searchEpoch) {
          setState(() {
            _searchError = '기업 검색에 실패했습니다.';
            _searching = false;
          });
        }
      }
    });
  }

  Future<void> _pushToggle(WatchlistView view) async {
    if (_busy) return;
    await _action(() async {
      if (_push == 'enabled') {
        final endpoint = await pushEndpoint();
        if (endpoint != null) await client.watchlist.unsubscribePush(endpoint);
        await disablePush();
      } else {
        if (view.vapidPublicKey == null || store.owner == null) return;
        final raw = await enablePush(view.vapidPublicKey!, store.owner!);
        final sub = jsonDecode(raw) as Map<String, dynamic>;
        try {
          await client.watchlist.subscribePush(
            sub['endpoint'] as String,
            sub['keys']['p256dh'] as String,
            sub['keys']['auth'] as String,
          );
        } catch (_) {
          await disablePush();
          rethrow;
        }
      }
      await _checkPush();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  String _date(DateTime date) {
    final d = date.toUtc().add(const Duration(hours: 9));
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final view = store.view;
      final c = context.colors;
      final t = context.typo;
      return PageFrame(
        maxWidth: 1040,
        children: [
          const PageHeading(
            eyebrow: '나의 리서치',
            title: '관심종목',
            subtitle: '지켜볼 기업을 저장하고, 새 공시를 한곳에서 확인하세요.',
          ),
          const SizedBox(height: AppSpace.lg),
          if (view != null) ...[
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${view.paid ? '멤버십' : '무료'} · ${view.companies.length}/${view.limit}개',
                  style: t.body(14, weight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => context.push('/account'),
                  child: const Text('멤버십 확인'),
                ),
                AppButton(
                  label: store.loading ? '확인 중…' : '새로고침',
                  onPressed: store.loading ? null : store.refresh,
                  icon: Icons.refresh,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _query,
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: '기업명 또는 종목코드',
                hintText: '관심종목에 추가할 기업 찾기',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(AppSpace.md),
                child: Text('검색 중…'),
              ),
            if (_searchError != null)
              Text(_searchError!, style: t.body(13, color: c.textSecondary)),
            if (!_searching &&
                _searchError == null &&
                _query.text.trim().isNotEmpty &&
                _results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpace.md),
                child: Text('검색 결과가 없습니다.'),
              ),
            for (final item in _results)
              ListTile(
                title: Text(item.name),
                subtitle: Text(item.stockCode ?? item.corpCode),
                trailing: IconButton(
                  tooltip: store.contains(item.corpCode) ? '관심등록 해제' : '관심등록',
                  icon: Icon(
                    store.contains(item.corpCode)
                        ? Icons.star
                        : Icons.star_border,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _action(() => store.toggle(item.corpCode)),
                ),
              ),
            const SizedBox(height: AppSpace.lg),
            if (view.companies.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: c.surfaceHover,
                  borderRadius: context.shape.borderRadius,
                ),
                child: const Text(
                  '아직 관심종목이 없습니다. 위에서 기업을 찾아 추가하거나 기업 상세의 관심등록을 눌러 주세요.',
                ),
              ),
            for (final company in view.companies)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpace.md,
                        runSpacing: AppSpace.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.push(
                              AppRoutes.company(company.corpCode),
                            ),
                            child: Text(
                              company.name,
                              style: t.body(17, weight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            company.stockCode ?? '',
                            style: t.body(12, color: c.textMuted),
                          ),
                          Text(
                            company.active
                                ? company.monitoringReady
                                      ? '새 공시 ${company.unreadCount}건'
                                      : '첫 공시 확인 대기'
                                : '무료 한도 초과 · 알림 일시 중지',
                            style: t.body(12, color: c.textSecondary),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.xs,
                        children: [
                          if (!company.active)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _action(() async {
                                      await client.watchlist.prioritize(
                                        company.corpCode,
                                      );
                                      await store.refresh();
                                    }),
                              child: const Text('이 기업 알림 활성화'),
                            ),
                          TextButton(
                            onPressed: _busy || !company.active
                                ? null
                                : () => _action(() async {
                                    await client.watchlist.mute(
                                      company.corpCode,
                                      !company.muted,
                                    );
                                    await store.refresh();
                                  }),
                            child: Text(
                              company.muted ? '기기 알림 켜기' : '기기 알림 끄기',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    () => store.toggle(company.corpCode),
                                  ),
                            child: const Text('관심등록 해제'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpace.lg),
            Text('기기 알림', style: t.body(18, weight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            Text(
              '허용하면 브라우저를 닫아도 새 공시 알림을 받을 수 있습니다. 기기 설정에 따라 지연될 수 있으며 모든 업데이트는 아래 알림함에 남습니다.',
              style: t.body(13, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(switch (_push) {
              'unsupported' =>
                '이 브라우저에서는 기기 알림을 지원하지 않습니다. 아이폰은 홈 화면에 추가한 웹 앱에서 설정해 주세요.',
              'denied' => '브라우저 설정에서 알림 권한을 허용한 뒤 다시 확인해 주세요.',
              'enabled' => '이 기기의 알림이 켜져 있습니다.',
              _ =>
                view.pushConfigured
                    ? '알림 켜기를 누른 뒤 브라우저 권한을 허용해 주세요.'
                    : '기기 알림 발송 설정을 준비 중입니다. 앱 알림함은 이용할 수 있습니다.',
            }, style: t.body(13, color: c.textMuted)),
            const SizedBox(height: AppSpace.sm),
            AppButton(
              label: _push == 'enabled' ? '이 기기 알림 끄기' : '기기 알림 켜기',
              icon: Icons.notifications_outlined,
              onPressed:
                  _busy ||
                      !view.pushConfigured ||
                      _push == 'unsupported' ||
                      _push == 'denied'
                  ? null
                  : () => _pushToggle(view),
            ),
            const SizedBox(height: AppSpace.xl),
            Text('공시 알림함', style: t.body(18, weight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),
            Text(
              !view.workerEnabled
                  ? '현재 개발 서버는 자동 수집이 꺼져 있습니다.'
                  : switch (view.scanStatus) {
                      'failed' => '공시 확인에 실패했습니다. 복구 후 이어서 확인합니다.',
                      'notConfigured' => '공시 수집 연결을 준비 중입니다.',
                      'budgetWaiting' => '오늘의 수집 예산을 사용했습니다. 다음 확인을 기다리고 있습니다.',
                      'running' => '공시를 확인하고 있습니다.',
                      'catchingUp' => '중단된 구간의 공시를 이어서 확인하고 있습니다.',
                      _ =>
                        view.lastCheckedAt == null
                            ? '첫 공시 확인을 기다리고 있습니다.'
                            : '마지막 확인 ${_date(view.lastCheckedAt!)}',
                    },
              style: t.body(12, color: c.textMuted),
            ),
            Text(
              '첫 확인까지의 공시는 기준점으로 삼고, 그 이후 발견한 새 공시부터 알려드립니다. 뉴스 알림은 기업 매칭 검증 후 제공할 예정입니다.',
              style: t.body(12, color: c.textMuted),
            ),
            if (view.updates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: Text('아직 새 공시 알림이 없습니다.'),
              ),
            for (final update in view.updates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  update.read
                      ? Icons.drafts_outlined
                      : Icons.mark_email_unread_outlined,
                  color: update.read ? c.textMuted : c.accent,
                ),
                title: Text(
                  '${update.companyName} · ${update.title}',
                  style: t.body(
                    14,
                    weight: update.read ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${_date(update.publishedAt)} · DART${update.title.contains('정정') ? ' · 정정 공시' : ''}',
                ),
                trailing: const Icon(Icons.north_east, size: 18),
                onTap: () => _action(() async {
                  await launchUrl(
                    Uri.parse(update.url),
                    mode: LaunchMode.externalApplication,
                  );
                  await client.watchlist.markRead(update.noticeId);
                  await store.refresh();
                }),
              ),
          ] else if (store.loading)
            const Padding(
              padding: EdgeInsets.all(AppSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (store.error != null) ...[
            Text(store.error!, style: t.body(13, color: c.textSecondary)),
            TextButton(onPressed: store.refresh, child: const Text('다시 시도')),
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
