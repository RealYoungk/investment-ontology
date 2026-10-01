import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'governance_view.dart';

/// 한 보고서의 보통주 현황. 소액주주와 최대주주 그룹을 더하지 않는다.
class OwnershipSnapshotCard extends StatelessWidget {
  const OwnershipSnapshotCard({super.key, required this.data});
  final CompanyGovernance data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final view = GovernanceView(data);
    final holders = view.holders().where((h) => (h.weight ?? 0) > 0).toList();
    final total = view.holderTotal();
    final date = data.shareholderPeriodEnd ?? data.settlementDate;
    final lead = holders.firstOrNull;
    final valid = total != null && total >= 0 && total <= 100;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${date == null ? '기준일 미확인' : '${formatDate(date)} 기준'} · ${data.bsnsYear}년 정기보고서',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('최대주주 및 특수관계인', style: t.body(14, weight: FontWeight.w600)),
          Text(
            '최대주주와 공시상 관계인의 보유 지분',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            formatRatio(total),
            style: t.numeric(28, weight: FontWeight.w600),
          ),
          if (lead != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '${lead.name}${holders.length > 1 ? ' 외 관계인' : ''}',
              style: t.body(16, weight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          if (valid) ...[
            Semantics(
              label: '전체 보통주 100% 중 최대주주와 관계인 ${formatRatio(total)}',
              child: ClipRRect(
                borderRadius: context.shape.borderRadius,
                child: LinearProgressIndicator(
                  value: total / 100,
                  minHeight: 14,
                  color: c.accent,
                  backgroundColor: c.border,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '보통주 전체 100% 중 보유 비중',
              style: t.body(12, color: c.textSecondary),
            ),
          ] else
            Text(
              '보통주 지분율을 확인할 자료가 부족해요.',
              style: t.body(13, color: c.textSecondary),
            ),
          if (holders.length > 1) ...[
            const SizedBox(height: AppSpace.lg),
            for (final holder in holders.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(holder.name, style: t.body(14))),
                    const SizedBox(width: AppSpace.sm),
                    Text(formatRatio(holder.weight), style: t.numeric(14)),
                  ],
                ),
              ),
            if (holders.length > 5)
              Text(
                '나머지 관계인은 아래 상세에서 확인',
                style: t.body(12, color: c.textSecondary),
              ),
          ],
          const SizedBox(height: AppSpace.md),
          Text(
            '보고서 기준의 보유 현황이에요. 이후 지분 변동은 공시에서 확인할 수 있어요.',
            style: t.body(12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
