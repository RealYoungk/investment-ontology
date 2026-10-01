import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../auth/app_viewer.dart';

class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key});
  @override
  Widget build(BuildContext context) {
    final adFree = context.viewer?.isAdFree ?? false;
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
                : '기업 정보는 무료로 조회할 수 있습니다. 광고 없이 이용하는 유료 옵션을 준비하고 있습니다.',
            style: t.body(14, color: c.textSecondary),
          ),
          if (!adFree) ...[
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
