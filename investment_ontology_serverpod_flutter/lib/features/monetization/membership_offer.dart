import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/tokens.dart';

/// Compact summary on the payment confirmation, not the plan marketing page.
class MembershipBenefits extends StatelessWidget {
  const MembershipBenefits({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmarks_outlined, color: c.accent, size: 24),
              const SizedBox(width: AppSpace.sm),
              Text('알파인더 멤버십', style: t.body(20, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          for (final item in [
            '관심기업 최대 20개 등록',
            '광고 없이 기업 정보 탐색',
            '관심기업의 새 공시 모아보기',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 18, color: c.accent),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(item, style: t.body(14))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showMembershipOffer(BuildContext context) async {
  final upgrade = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      final t = context.typo;
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '나의 기업 목록을 넓혀보세요',
                          style: t.body(20, weight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '무료 플랜의 관심기업 3개를 모두 담았어요.\n멤버십으로 더 많은 기업을 함께 지켜보세요.',
                    style: t
                        .body(14, color: c.textSecondary)
                        .copyWith(height: 1.6),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: c.accentSubtle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '멤버십',
                          style: t.body(
                            13,
                            color: c.accent,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '관심기업 20개',
                          style: t.body(28, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '17개 더 등록하고, 광고 없이 탐색하세요.',
                          style: t.body(13, color: c.textSecondary),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          '가입 가격을 유지하는 월간 멤버십',
                          style: t.numeric(20, weight: FontWeight.w600),
                        ),
                        Text(
                          '부가세 포함 · 언제든 갱신 해지',
                          style: t.body(12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('플랜 비교하고 업그레이드'),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('지금은 무료로 이용할게요'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  if (upgrade == true && context.mounted) context.push('/membership');
}
