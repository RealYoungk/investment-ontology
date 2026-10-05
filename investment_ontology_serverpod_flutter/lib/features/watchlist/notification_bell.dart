import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/tokens.dart';
import '../../design/components/components.dart';
import 'push_platform.dart';
import 'watchlist_store.dart';
import 'update_destination.dart';

/// Shared account-scoped inbox. The page and bell listen to the same store.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _popover = ShadPopoverController();
  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = WatchlistStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unread = store.view?.updates.where((u) => !u.read).length ?? 0;
        return ShadPopover(
          controller: _popover,
          popover: (_) => InheritedTheme.captureAll(
            context,
            _NotificationInbox(onClose: _popover.hide),
          ),
          child: Semantics(
            container: true,
            label: unread > 0 ? '알림함 · 읽지 않은 알림 $unread개' : '알림함',
            button: true,
            enabled: true,
            onTap: () {
              if (store.owner == null) {
                context.push('/login');
                return;
              }
              store.refresh();
              if (MediaQuery.sizeOf(context).width < 600) {
                showShadSheet<void>(
                  useRootNavigator: true,
                  context: context,
                  side: ShadSheetSide.bottom,
                  barrierLabel: '알림 닫기',
                  builder: (_) => InheritedTheme.captureAll(
                    context,
                    ShadSheet(
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
                      child: _NotificationInbox(),
                    ),
                  ),
                );
              } else {
                _popover.toggle();
              }
            },
            child: ExcludeSemantics(
              child: ShadIconButton.ghost(
                width: 36,
                height: 36,
                hoverBackgroundColor: ShadTheme.of(context).colorScheme.accent,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      LucideIcons.bell,
                      color: context.colors.textSecondary,
                      size: 20,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -8,
                        right: -10,
                        child: ShadBadge(
                          child: Text(unread > 99 ? '99+' : '$unread'),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  if (store.owner == null) {
                    context.push('/login');
                    return;
                  }
                  store.refresh();
                  if (MediaQuery.sizeOf(context).width < 600) {
                    showShadSheet<void>(
                      useRootNavigator: true,
                      context: context,
                      side: ShadSheetSide.bottom,
                      barrierLabel: '알림 닫기',
                      builder: (_) => InheritedTheme.captureAll(
                        context,
                        ShadSheet(
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
                          child: _NotificationInbox(),
                        ),
                      ),
                    );
                  } else {
                    _popover.toggle();
                  }
                },
                semanticLabel: unread > 0 ? '알림함 · 읽지 않은 알림 $unread개' : '알림함',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationInbox extends StatefulWidget {
  const _NotificationInbox({this.fullPage = false, this.onClose});
  final VoidCallback? onClose;
  final bool fullPage;
  @override
  State<_NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<_NotificationInbox> {
  final store = WatchlistStore.instance;
  String _push = 'checking';
  bool _settings = false;
  bool _busy = false;
  String? _notice;
  @override
  void initState() {
    super.initState();
    _checkPush();
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
    } catch (_) {
      if (mounted) setState(() => _notice = '요청을 처리하지 못했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final view = store.view;
      final c = context.colors;
      final t = context.typo;
      if (store.owner == null) {
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
          title: const Text('알림함'),
          actions: [
            ShadButton.ghost(
              onPressed: () => Navigator.pop(context),
              child: Flexible(child: const Text('닫기')),
            ),
          ],
          child: Material(
            type: MaterialType.transparency,
            child: const Text('로그인 후 알림을 확인할 수 있습니다.'),
          ),
        );
      }
      return Material(
        color: c.surface,
        elevation: widget.fullPage ? 0 : 8,
        shadowColor: c.textPrimary.withValues(alpha: .12),
        borderRadius: context.shape.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.sm,
                  AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _settings
                            ? '알림 설정'
                            : widget.fullPage
                            ? '최근 알림'
                            : '알림',
                        style: t.body(18, weight: FontWeight.w700),
                      ),
                    ),
                    Semantics(
                      container: true,
                      label: _settings ? '알림 목록' : '알림 설정',
                      button: true,
                      enabled: true,
                      onTap: () => setState(() => _settings = !_settings),
                      child: ExcludeSemantics(
                        child: ShadIconButton.ghost(
                          onPressed: () =>
                              setState(() => _settings = !_settings),
                          icon: Icon(
                            _settings
                                ? LucideIcons.arrowLeft
                                : LucideIcons.settings,
                            size: 20,
                          ),
                          semanticLabel: _settings ? '알림 목록' : '알림 설정',
                        ),
                      ),
                    ),
                    if (!widget.fullPage)
                      Semantics(
                        container: true,
                        label: '알림함 닫기',
                        button: true,
                        enabled: true,
                        onTap: widget.onClose ?? () => Navigator.pop(context),
                        child: ExcludeSemantics(
                          child: ShadIconButton.ghost(
                            onPressed:
                                widget.onClose ?? () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.x, size: 20),
                            semanticLabel: '알림함 닫기',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (store.loading && view == null)
                        const Padding(
                          padding: EdgeInsets.all(AppSpace.xl),
                          child: Center(child: ShadSpinner()),
                        ),
                      if (store.error != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          child: Text(store.error!),
                        ),
                      if (!_settings && view != null && view.updates.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.xl,
                          ),
                          child: Text(
                            '새 알림이 없어요',
                            textAlign: TextAlign.center,
                            style: t.body(14, color: c.textMuted),
                          ),
                        ),
                      if (!_settings && view != null)
                        for (final update
                            in (widget.fullPage
                                ? view.updates
                                : view.updates.take(10)))
                          ShadButton.ghost(
                            width: double.infinity,
                            height: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.sm,
                            ),
                            onPressed: _busy
                                ? null
                                : () => _action(() async {
                                    final path = investmentNotePath(update.url);
                                    if (path != null) {
                                      context.push(path);
                                    } else {
                                      await launchUrl(
                                        Uri.parse(update.url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                    await client.watchlist.markRead(
                                      update.noticeId,
                                    );
                                    await store.refresh();
                                  }),
                            child: Flexible(
                              child: Row(
                                children: [
                                  Icon(
                                    update.read
                                        ? LucideIcons.fileText
                                        : LucideIcons.mail,
                                    color: update.read ? c.textMuted : c.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          update.title,
                                          style: t.body(
                                            14,
                                            weight: update.read
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${update.companyName} · ${updateSourceLabel(update.url)}',
                                          style: t.body(12, color: c.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  const Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (_settings && view != null)
                        ShadAccordion<int>(
                          maintainState: false,
                          initialValue: 0,
                          children: [
                            ShadAccordionItem<int>(
                              value: 0,
                              title: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.slidersHorizontal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Text('기기 알림 설정', style: t.body(14)),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpace.lg,
                                      0,
                                      AppSpace.lg,
                                      AppSpace.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          switch (_push) {
                                            'unsupported' => '이 브라우저에서는 기기 알림을 지원하지 않습니다. 아이폰은 홈 화면에 추가한 웹 앱에서 설정해 주세요.',
                                            'denied' =>
                                              '브라우저 설정에서 알림 권한을 허용해 주세요.',
                                            'enabled' => '이 기기의 알림이 켜져 있습니다.',
                                            _ =>
                                              view.pushConfigured
                                                  ? '허용하면 브라우저를 닫아도 공시와 투자 관점 업데이트 알림을 받을 수 있습니다.'
                                                  : '기기 알림 발송 설정을 준비 중입니다. 앱 알림함은 이용할 수 있습니다.',
                                          },
                                          style: t.body(
                                            13,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpace.md),
                                        ShadButton(
                                          enabled:
                                              !(_busy ||
                                                  !view.pushConfigured ||
                                                  _push == 'unsupported' ||
                                                  _push == 'denied'),
                                          onPressed:
                                              _busy ||
                                                  !view.pushConfigured ||
                                                  _push == 'unsupported' ||
                                                  _push == 'denied'
                                              ? null
                                              : () => _pushToggle(view),
                                          leading: const Icon(
                                            LucideIcons.bell,
                                            size: 18,
                                          ),
                                          child: Flexible(
                                            child: Text(
                                              _push == 'enabled'
                                                  ? '이 기기 알림 끄기'
                                                  : '이 기기 알림 켜기',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (_notice != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          child: Text(_notice!),
                        ),
                    ],
                  ),
                ),
              ),
              if (!widget.fullPage && !_settings)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: ShadButton.ghost(
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                      context.go('/notifications');
                    },
                    child: Flexible(child: const Text('모두 보기')),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WatchlistStore.instance.refresh();
  }

  @override
  Widget build(BuildContext context) => const PageFrame(
    maxWidth: 760,
    children: [
      PageHeading(title: '알림', subtitle: '관심 기업의 새 소식을 확인하세요.'),
      SizedBox(height: AppSpace.lg),
      _NotificationInbox(fullPage: true),
    ],
  );
}
