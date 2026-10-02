import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_auth.dart';
import 'billing_platform.dart';
import 'service_links.dart';
import 'membership_offer.dart';
import 'membership_availability.dart';

class BillingCheckoutPage extends StatefulWidget {
  const BillingCheckoutPage({
    super.key,
    this.state,
    this.authKey,
    this.failed = false,
    this.replaceCard = false,
    this.loadStatus,
    this.beginCheckout,
    this.completeCheckout,
    this.launch,
    this.refresh,
    this.abortCheckout,
    this.checkoutEnabled = membershipCheckoutEnabled,
  });
  final bool checkoutEnabled;
  final String? state;
  final String? authKey;
  final bool failed;
  final bool replaceCard;
  final Future<MembershipView> Function()? loadStatus;
  final Future<BillingCheckoutView> Function(String)? beginCheckout;
  final Future<MembershipView> Function(String, String)? completeCheckout;
  final Future<void> Function(BillingCheckoutView)? launch;
  final Future<void> Function()? refresh;
  final Future<void> Function(String)? abortCheckout;
  @override
  State<BillingCheckoutPage> createState() => _BillingCheckoutPageState();
}

class _BillingCheckoutPageState extends State<BillingCheckoutPage> {
  MembershipView? _status;
  bool _accepted = false;
  bool _busy = true;
  String? _message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      if (widget.state != null || widget.authKey != null || widget.failed) {
        clearBillingQuery();
      }
      if (widget.failed && widget.state != null) {
        await (widget.abortCheckout ?? client.membership.abortCheckout)(
          widget.state!,
        );
      }
      if (widget.failed) {
        _message = '카드 등록이 취소되었거나 완료되지 않았습니다. 계정에서 이용권 상태를 확인해 주세요.';
      }
      if (widget.state != null && widget.authKey != null && !widget.failed) {
        _status =
            await (widget.completeCheckout ??
                client.membership.completeCheckout)(
              widget.state!,
              widget.authKey!,
            );
        await (widget.refresh ?? AppAuth.refreshMembership)();
        _message = widget.replaceCard
            ? '결제 카드를 변경했습니다. 추가 요금은 청구하지 않았습니다.'
            : _status!.adFree
            ? '멤버십이 적용되었습니다. 관심기업을 20개까지 등록할 수 있습니다.'
            : '결제 결과를 확인 중입니다. 새 결제를 시작하지 말고 계정 상태를 확인해 주세요.';
      } else {
        _status = await (widget.loadStatus ?? client.membership.status)();
      }
    } catch (_) {
      _message = '결제 상태를 확인하지 못했습니다. 잠시 후 계정 상태를 다시 확인해 주세요.';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _start() async {
    if (!widget.checkoutEnabled ||
        !_accepted ||
        _busy ||
        _status?.paymentAvailable != true ||
        _status?.termsVersion == null) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    String? pendingState;
    try {
      final checkout =
          await (widget.beginCheckout ??
              (widget.replaceCard
                  ? client.membership.beginCardReplacement
                  : client.membership.beginCheckout))(
            _status!.termsVersion!,
          );
      pendingState = checkout.state;
      await (widget.launch ?? openBilling)(checkout);
    } catch (_) {
      if (pendingState != null) {
        try {
          await (widget.abortCheckout ?? client.membership.abortCheckout)(
            pendingState,
          );
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '카드 등록창을 열지 못했습니다. 잠시 후 다시 확인해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return PageFrame(
      maxWidth: 680,
      children: [
        PageHeading(
          title: widget.replaceCard ? '결제 카드 변경' : '멤버십 시작하기',
          subtitle: widget.replaceCard
              ? '다음 결제에 사용할 카드를 변경하세요.'
              : '선택한 플랜과 결제 조건을 확인하세요.',
        ),
        const SizedBox(height: AppSpace.lg),
        if (!widget.replaceCard) ...[
          Text('플랜 선택  /  결제 확인', style: t.body(12, color: c.textMuted)),
          const SizedBox(height: AppSpace.lg),
          const MembershipBenefits(),
          const SizedBox(height: AppSpace.xl),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Text(_message!, style: t.body(14, color: c.textSecondary)),
        if (!_busy && _status != null)
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: context.shape.borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.replaceCard ? '카드 변경' : '월간 멤버십',
                  style: t.body(13, color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.sm),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '2,900',
                        style: t.numeric(36, weight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' 원 / 월',
                        style: t.body(14, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '부가세 포함 · 매월 자동 갱신',
                  style: t.body(12, color: c.textMuted),
                ),
                if (_status!.isTest) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: c.surfaceHover,
                      borderRadius: context.shape.borderRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            '테스트 결제 · 실제 요금 청구 없음',
                            style: t.body(12, color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                if (_status!.adFree && !widget.replaceCard)
                  Text('멤버십 이용 중 · 관심기업 20개와 광고 제거가 적용됩니다.', style: t.body(14))
                else if (!widget.checkoutEnabled || !_status!.paymentAvailable)
                  Text('이용권 출시를 준비하고 있습니다. 아직 결제할 수 없습니다.', style: t.body(14))
                else ...[
                  Text(
                    widget.replaceCard
                        ? '카드를 바꿔도 이용 기간과 해지 상태는 유지됩니다. 카드 변경으로 추가 결제하지 않습니다.'
                        : '카드 등록 후 첫 2,900원을 결제하고 매월 같은 기준일에 자동 갱신합니다. 해당 날짜가 없는 달은 말일입니다. 계정에서 갱신 해지할 수 있고 이미 결제한 기간까지 이용합니다. 현재 기간 안에 이메일로 환불 요청하면 해당 회차 전액을 환불하고 이용권과 다음 갱신을 종료합니다.',
                    style: t.body(14, color: c.textSecondary),
                  ),
                  const ServiceLinks(),
                  Material(
                    color: c.surface,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.replaceCard
                            ? '다음 정기결제에 사용할 카드를 변경하는 데 동의합니다.'
                            : _status!.isTest
                            ? '카드 등록과 2,900원 자동결제 테스트에 동의합니다.'
                            : '월 2,900원 정기결제와 이용권 약관에 동의합니다.',
                        style: t.body(14),
                      ),
                      value: _accepted,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _accepted = v ?? false),
                    ),
                  ),
                  FilledButton(
                    onPressed: _accepted && !_busy ? _start : null,
                    child: Text(
                      widget.replaceCard
                          ? '카드 변경하기'
                          : _status!.isTest
                          ? '테스트 카드 등록'
                          : '월 2,900원 결제하고 시작하기',
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpace.lg),
        if (!widget.replaceCard)
          TextButton.icon(
            onPressed: () => context.go('/watchlist'),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('관심종목으로 돌아가기'),
          ),
        TextButton(
          onPressed: () => context.go('/account'),
          child: const Text('계정 상태 확인'),
        ),
      ],
    );
  }
}
