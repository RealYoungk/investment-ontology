import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'app_auth.dart';
import '../monetization/membership_card.dart';
import '../monetization/payment_admin_dialog.dart';
import 'app_viewer.dart';
import 'sign_in_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.manage = false});
  final bool manage;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<List<AccountView>> _load = _fetch();
  bool _busy = false;
  String _query = '';
  late final Future<bool> _mailConfigured = widget.manage
      ? client.account.mailConfigured()
      : Future.value(false);
  int _offset = 0;
  Future<List<AccountView>> _fetch() async => widget.manage
      ? client.account.list(offset: _offset)
      : [await client.account.me()];
  void _reload() {
    final next = _fetch();
    setState(() {
      _load = next;
    });
  }

  Future<bool> _confirm(String title, String message) async =>
      await showShadDialog<bool>(
        context: context,
        builder: (overlayContext) => InheritedTheme.captureAll(
          context,
          Builder(
            builder: (dialogContext) => ShadDialog(
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
              title: Text(title),
              actions: [
                ShadButton.ghost(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Flexible(child: const Text('취소')),
                ),
                ShadButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Flexible(child: const Text('확인')),
                ),
              ],
              child: Material(
                type: MaterialType.transparency,
                child: Text(message),
              ),
            ),
          ),
        ),
        barrierLabel: '닫기',
      ) ??
      false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text('처리하지 못했습니다. 권한과 연결 상태를 확인해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _access(AccountView user, {bool? admin, bool? blocked}) async {
    final action = admin != null
        ? (admin ? '관리자 권한 부여' : '일반 회원으로 변경')
        : (blocked! ? '이용 정지' : '이용 정지 해제');
    if (!await _confirm(action, '${user.email}\n변경 후 이 회원은 다시 로그인해야 합니다.')) {
      return;
    }
    await _run(
      () => client.account.updateAccess(
        user.userId,
        isAdmin: admin ?? user.isAdmin,
        blocked: blocked ?? user.blocked,
      ),
    );
  }

  Future<void> _delete() async {
    final password = TextEditingController();
    final accepted = await showShadDialog<bool>(
      context: context,
      builder: (overlayContext) => InheritedTheme.captureAll(
        context,
        Builder(
          builder: (dialogContext) => ShadDialog(
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
            title: const Text('회원 탈퇴'),
            actions: [
              ShadButton.ghost(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Flexible(child: const Text('취소')),
              ),
              ShadButton.ghost(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Flexible(child: const Text('탈퇴')),
              ),
            ],
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '로그인 계정과 인증 정보가 삭제되며 되돌릴 수 없습니다. 공용 기업 데이터는 유지됩니다. 현재 비밀번호를 입력해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  ShadInput(
                    controller: password,
                    obscureText: true,
                    placeholder: Text('현재 비밀번호'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierLabel: '닫기',
    );
    final value = password.text;
    // Allow the dialog's exit animation to release the controller first.
    Future<void>.delayed(const Duration(seconds: 1), password.dispose);
    if (accepted != true || value.isEmpty) return;
    await _run(() async {
      await client.account.deleteMe(value);
      await AppAuth.signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.manage && !context.isAdmin) {
      return const Center(child: Text('관리자만 회원을 관리할 수 있습니다.'));
    }
    final t = context.typo;
    final c = context.colors;
    return PageFrame(
      maxWidth: 900,
      children: [
        PageHeading(
          title: widget.manage ? '회원 관리' : '내 계정',
          subtitle: widget.manage
              ? '회원 권한과 이용 상태를 관리합니다.'
              : '로그인 정보와 계정 보안을 관리합니다.',
        ),
        const SizedBox(height: AppSpace.xl),
        if (!widget.manage) const MembershipCard(),
        if (widget.manage)
          FutureBuilder<bool>(
            future: _mailConfigured,
            builder: (context, snapshot) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg),
              child: ShadAlert(
                icon: const Icon(LucideIcons.mail),
                title: const Text('인증 메일'),
                description: Text(
                  snapshot.hasError
                      ? '설정 조회 실패 · 연결 상태를 확인해 주세요.'
                      : snapshot.hasData
                      ? (snapshot.data!
                            ? '발송 설정됨 · 실제 수신 테스트가 필요합니다.'
                            : '발신 도메인과 메일 발송 키 설정이 필요합니다. 가입·재설정 메일은 아직 보낼 수 없습니다.')
                      : '설정 확인 중…',
                ),
              ),
            ),
          ),
        if (widget.manage) ...[
          ShadInput(
            placeholder: const Text('현재 페이지에서 이메일 검색'),
            leading: const Icon(LucideIcons.search, size: 18),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        FutureBuilder<List<AccountView>>(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  const ShadAlert.destructive(
                    title: Text('계정 정보를 불러오지 못했습니다.'),
                    description: Text('권한과 연결 상태를 확인한 뒤 다시 시도해 주세요.'),
                  ),
                  ShadButton.ghost(
                    onPressed: _reload,
                    child: Flexible(child: const Text('다시 시도')),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: ShadSpinner());
            }
            final pageUsers = snapshot.data!;
            final users = pageUsers
                .where(
                  (user) =>
                      !widget.manage ||
                      user.email.toLowerCase().contains(_query),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.manage) ...[
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      ShadBadge.secondary(
                        child: Text(
                          pageUsers.isEmpty
                              ? '현재 페이지 0명'
                              : '조회 ${_offset + 1}–${_offset + pageUsers.length} · ${pageUsers.length}명',
                        ),
                      ),
                      ShadBadge.outline(
                        child: Text(
                          '관리자 ${pageUsers.where((u) => u.isAdmin).length}명',
                        ),
                      ),
                      ShadBadge.outline(
                        child: Text(
                          '이용 정지 ${pageUsers.where((u) => u.blocked).length}명',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  if (users.isEmpty)
                    ShadAlert(
                      icon: const Icon(LucideIcons.users),
                      title: Text(
                        _query.isEmpty
                            ? '등록된 회원이 없습니다.'
                            : '현재 페이지에 검색 결과가 없습니다.',
                      ),
                      description: const Text('검색은 현재 조회한 최대 50명의 회원에 적용됩니다.'),
                    ),
                ],
                for (final user in users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: ShadCard(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        AppLayout.panelPadding(
                          MediaQuery.sizeOf(context).width,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            user.email,
                            style: t.body(17, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              ShadBadge.secondary(
                                child: Text(user.isAdmin ? '관리자' : '일반 회원'),
                              ),
                              if (user.blocked)
                                const ShadBadge.destructive(
                                  child: Text('이용 정지'),
                                )
                              else
                                const ShadBadge.outline(child: Text('이용 가능')),
                              if (user.userId == context.viewer?.userId)
                                const ShadBadge.outline(child: Text('내 계정')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '가입일 ${user.createdAt.toLocal().toIso8601String().split('T').first}',
                            style: t.body(12, color: c.textMuted),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          const ShadSeparator.horizontal(
                            margin: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpace.lg),
                          if (widget.manage)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ShadButton.raw(
                                  onPressed: _busy
                                      ? null
                                      : () => showShadDialog<void>(
                                          context: context,
                                          builder: (overlayContext) =>
                                              InheritedTheme.captureAll(
                                                context,
                                                Builder(
                                                  builder: (_) =>
                                                      PaymentAdminDialog(
                                                        user: user,
                                                      ),
                                                ),
                                              ),
                                          barrierLabel: '닫기',
                                        ),
                                  enabled:
                                      (_busy
                                          ? null
                                          : () => showShadDialog<void>(
                                              context: context,
                                              builder: (overlayContext) =>
                                                  InheritedTheme.captureAll(
                                                    context,
                                                    Builder(
                                                      builder: (_) =>
                                                          PaymentAdminDialog(
                                                            user: user,
                                                          ),
                                                    ),
                                                  ),
                                              barrierLabel: '닫기',
                                            )) !=
                                      null,
                                  variant: ShadButtonVariant.outline,
                                  child: Flexible(child: Text('결제 내역 · 환불')),
                                ),
                                if (user.userId != context.viewer?.userId) ...[
                                  ShadButton.raw(
                                    onPressed: _busy
                                        ? null
                                        : () => _access(
                                            user,
                                            admin: !user.isAdmin,
                                          ),
                                    enabled:
                                        (_busy
                                            ? null
                                            : () => _access(
                                                user,
                                                admin: !user.isAdmin,
                                              )) !=
                                        null,
                                    variant: ShadButtonVariant.outline,
                                    child: Flexible(
                                      child: Text(
                                        user.isAdmin ? '일반 회원으로 변경' : '관리자로 변경',
                                      ),
                                    ),
                                  ),
                                  ShadButton.raw(
                                    onPressed: _busy
                                        ? null
                                        : () => _access(
                                            user,
                                            blocked: !user.blocked,
                                          ),
                                    enabled:
                                        (_busy
                                            ? null
                                            : () => _access(
                                                user,
                                                blocked: !user.blocked,
                                              )) !=
                                        null,
                                    variant: ShadButtonVariant.outline,
                                    child: Flexible(
                                      child: Text(
                                        user.blocked ? '정지 해제' : '이용 정지',
                                      ),
                                    ),
                                  ),
                                  ShadButton.raw(
                                    onPressed: _busy
                                        ? null
                                        : () async {
                                            if (await _confirm(
                                              '로그인 세션 종료',
                                              '${user.email}\n모든 기기의 로그인 갱신을 차단합니다. 이미 발급된 접근 토큰은 최대 10분간 유효할 수 있습니다.',
                                            )) {
                                              await _run(
                                                () => client.account
                                                    .revokeSessions(
                                                      userId: user.userId,
                                                    ),
                                              );
                                            }
                                          },
                                    enabled:
                                        (_busy
                                            ? null
                                            : () async {
                                                if (await _confirm(
                                                  '로그인 세션 종료',
                                                  '${user.email}\n모든 기기의 로그인 갱신을 차단합니다. 이미 발급된 접근 토큰은 최대 10분간 유효할 수 있습니다.',
                                                )) {
                                                  await _run(
                                                    () => client.account
                                                        .revokeSessions(
                                                          userId: user.userId,
                                                        ),
                                                  );
                                                }
                                              }) !=
                                        null,
                                    variant: ShadButtonVariant.outline,
                                    child: Flexible(child: Text('로그인 세션 종료')),
                                  ),
                                ] else
                                  Text(
                                    '현재 내 계정',
                                    style: t.body(13, color: c.textMuted),
                                  ),
                              ],
                            )
                          else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ShadButton.raw(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const SignInPage(
                                              resetPassword: true,
                                            ),
                                          ),
                                        ),
                                  enabled:
                                      (_busy
                                          ? null
                                          : () => Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const SignInPage(
                                                      resetPassword: true,
                                                    ),
                                              ),
                                            )) !=
                                      null,
                                  variant: ShadButtonVariant.outline,
                                  child: Flexible(child: Text('비밀번호 재설정')),
                                ),
                                ShadButton.raw(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await _confirm(
                                            '모든 기기에서 로그아웃',
                                            '다른 기기의 로그인 갱신을 차단합니다. 이미 발급된 접근 토큰은 최대 10분간 유효할 수 있습니다.',
                                          )) {
                                            await _run(() async {
                                              await client.account
                                                  .revokeSessions();
                                              await AppAuth.signOut();
                                            });
                                          }
                                        },
                                  enabled:
                                      (_busy
                                          ? null
                                          : () async {
                                              if (await _confirm(
                                                '모든 기기에서 로그아웃',
                                                '다른 기기의 로그인 갱신을 차단합니다. 이미 발급된 접근 토큰은 최대 10분간 유효할 수 있습니다.',
                                              )) {
                                                await _run(() async {
                                                  await client.account
                                                      .revokeSessions();
                                                  await AppAuth.signOut();
                                                });
                                              }
                                            }) !=
                                      null,
                                  variant: ShadButtonVariant.outline,
                                  child: Flexible(child: Text('모든 기기에서 로그아웃')),
                                ),
                                ShadButton.raw(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(AppAuth.signOut),
                                  enabled:
                                      (_busy
                                          ? null
                                          : () => _run(AppAuth.signOut)) !=
                                      null,
                                  variant: ShadButtonVariant.outline,
                                  child: Flexible(child: Text('로그아웃')),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (user.isAdmin)
                              Text(
                                '관리자 계정은 다른 관리자에게 권한을 이전한 뒤 탈퇴할 수 있습니다.',
                                style: t.body(12, color: c.textMuted),
                              )
                            else
                              ShadButton.ghost(
                                onPressed: _busy ? null : _delete,
                                enabled: (_busy ? null : _delete) != null,
                                child: Flexible(child: const Text('회원 탈퇴')),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (widget.manage)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShadButton.ghost(
                        onPressed: _offset == 0
                            ? null
                            : () {
                                _offset -= 50;
                                _reload();
                              },
                        enabled:
                            (_offset == 0
                                ? null
                                : () {
                                    _offset -= 50;
                                    _reload();
                                  }) !=
                            null,
                        leading: const Icon(LucideIcons.chevronLeft, size: 16),
                        child: const Text('이전'),
                      ),
                      ShadButton.ghost(
                        onPressed: pageUsers.length < 50
                            ? null
                            : () {
                                _offset += 50;
                                _reload();
                              },
                        enabled:
                            (pageUsers.length < 50
                                ? null
                                : () {
                                    _offset += 50;
                                    _reload();
                                  }) !=
                            null,
                        trailing: const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                        ),
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                if (!widget.manage && context.isAdmin)
                  ShadButton.ghost(
                    onPressed: () => context.push('/admin/accounts'),
                    child: Flexible(child: const Text('회원 관리 열기')),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
