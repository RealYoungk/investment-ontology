import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'service_links.dart';
import '../../client.dart';
import '../auth/app_auth.dart';

import '../../design/tokens.dart';
import '../auth/app_viewer.dart';

class MembershipCard extends StatefulWidget {
  const MembershipCard({super.key});
  @override
  State<MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<MembershipCard> {
  bool _canceling = false;

  Future<void> _cancel() async {
    setState(() => _canceling = true);
    try {
      await client.membership.cancelRenewal();
      await AppAuth.refreshMembership();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자동 갱신을 해지했습니다. 이미 결제한 기간까지 광고 없이 이용할 수 있습니다.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해지 결과를 확인하지 못했습니다. 잠시 후 다시 확인해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.viewer;
    final adFree = viewer?.isAdFree ?? false;
    final end = viewer?.paidThroughUtc?.toLocal();
    final c = context.colors;
    final t = context.typo;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adFree ? '광고 없이 이용 중' : '무료 이용',
            style: t.body(18, weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            adFree
                ? '이 계정으로 로그인하면 광고를 표시하지 않습니다.'
                : (viewer?.paymentAvailable ?? false)
                ? viewer!.isTestMembership
                      ? '이용권 테스트를 사용할 수 있습니다. 실제 요금이 청구되지 않습니다.'
                      : '월 2,900원으로 광고 없이 이용할 수 있습니다.'
                : '기업 정보는 무료로 조회할 수 있습니다. 광고 제거 이용권은 월 2,900원으로 준비하고 있습니다.',
            style: t.body(14, color: c.textSecondary),
          ),
          if (end != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '${end.year}년 ${end.month}월 ${end.day}일 ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}까지',
              style: t.body(14, color: c.textSecondary),
            ),
            if (viewer!.cancelAtPeriodEnd)
              Text('자동 갱신 해지됨', style: t.body(14, color: c.textSecondary))
            else
              TextButton(
                onPressed: _canceling ? null : _cancel,
                child: Text(_canceling ? '해지 중…' : '자동 갱신 해지'),
              ),
          ],
          const ServiceLinks(),
          if (!adFree && (viewer?.paymentAvailable ?? false)) ...[
            const SizedBox(height: AppSpace.sm),
            FilledButton(
              onPressed: () => context.push('/membership/checkout'),
              child: Text(
                viewer!.isTestMembership ? '이용권 테스트' : '광고 제거 이용권 시작하기',
              ),
            ),
          ],
          if (!adFree && !(viewer?.paymentAvailable ?? false)) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '아직 결제할 수 없으며, 요금이 청구되지 않습니다.',
              style: t.body(12, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
