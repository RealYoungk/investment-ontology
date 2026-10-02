import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/tokens.dart';
import '../../design/components/components.dart';
import '../common/formatters.dart';
import 'governance_view.dart';

/// 공시에 이름이 기재된 보통주 주주. 5% 또는 상위 N명으로 자르지 않는다.
List<GovernanceNode> snapshotHolders(CompanyGovernance data) {
  final common = data.shareholders.where(
    (s) => !s.isTotal && GovernanceView.isCommon(s.stockKind),
  );
  final names = {
    for (final s in common)
      if ((s.ratioEnd ?? 0) > 0 ||
          (s.sharesEnd != null && s.sharesEnd! > BigInt.zero) ||
          (s.ratioEnd == null && s.sharesEnd == null))
        s.holderName,
  };
  return GovernanceView(data)
      .holders()
      .where((h) => names.contains(h.name))
      .toList();
}

class OwnershipSnapshotCard extends StatelessWidget {
  const OwnershipSnapshotCard({super.key, required this.data, this.header});
  final CompanyGovernance data;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final holders = snapshotHolders(data);
    final minor = holders.where((h) => h.weight == 0).toList();
    final primary = holders.where((h) => h.weight != 0).toList();
    final total = GovernanceView(data).holderTotal();
    final date = data.shareholderPeriodEnd ?? data.settlementDate;
    final valid = total != null && total >= 0 && total <= 100;
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          Text(
            '${date == null ? '기준일 미확인' : '${formatDate(date)} 기준'} · 보통주',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(child: Text('최대주주 및 특수관계인', style: t.body(13))),
              Text(
                formatRatio(total),
                style: t.numeric(24, weight: FontWeight.w600),
              ),
            ],
          ),
          if (valid) ...[
            const SizedBox(height: AppSpace.sm),
            Semantics(
              label: '전체 보통주 100% 중 최대주주와 관계인 ${formatRatio(total)}',
              child: LinearProgressIndicator(
                value: total / 100,
                minHeight: 5,
                color: c.chartSeries1,
                backgroundColor: c.chartGrid,
              ),
            ),
          ] else
            Text(
              '보통주 지분율을 확인할 자료가 부족해요.',
              style: t.body(12, color: c.textSecondary),
            ),
          const SizedBox(height: AppSpace.md),
          for (final holder in primary) _SnapshotHolderRow(holder: holder),
          if (minor.isNotEmpty)
            Material(
              color: c.surface,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  '소량 보유 관계인 ${minor.length}명',
                  style: t.body(12, color: c.textSecondary),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Text(
                      '지분율이 0.00%로 표시되는 주주는 보유 주식 수로 보여줍니다.',
                      style: t.body(11, color: c.textMuted),
                    ),
                  ),
                  for (final holder in minor)
                    _SnapshotHolderRow(
                      holder: holder,
                      quantities: snapshotQuantities(data, holder),
                      comparisonDate: data.shareholderPeriodStart,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Match the same grouping identity as GovernanceView, keeping share classes separate.
({BigInt? end, BigInt? change}) snapshotQuantities(
  CompanyGovernance data,
  GovernanceNode holder,
) {
  final view = GovernanceView(data);
  final rows = data.shareholders
      .where(
        (s) =>
            !s.isTotal &&
            GovernanceView.isCommon(s.stockKind) &&
            (holder.corpCode != null
                ? view.corpCodeOf(s.holderCompanyId) == holder.corpCode
                : holder.personId != null
                ? s.holderPersonId == holder.personId
                : s.holderName.replaceAll(' ', '') ==
                      holder.name.replaceAll(' ', '')),
      )
      .toList();
  BigInt? sum(bool end) {
    if (rows.isEmpty ||
        rows.any((s) => (end ? s.sharesEnd : s.sharesBegin) == null)) {
      return null;
    }
    return rows.fold<BigInt>(
      BigInt.zero,
      (n, s) => n + (end ? s.sharesEnd! : s.sharesBegin!),
    );
  }

  final end = sum(true), begin = sum(false);
  return (end: end, change: end == null || begin == null ? null : end - begin);
}

class _SnapshotHolderRow extends StatelessWidget {
  const _SnapshotHolderRow({
    required this.holder,
    this.quantities,
    this.comparisonDate,
  });
  final DateTime? comparisonDate;
  final GovernanceNode holder;
  final ({BigInt? end, BigInt? change})? quantities;
  @override
  Widget build(BuildContext context) {
    final t = context.typo, c = context.colors;
    final q = quantities;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(holder.name, style: t.body(13, weight: FontWeight.w600)),
                if (holder.detail != null &&
                    holder.detail!.trim().isNotEmpty &&
                    holder.detail != '-')
                  Text(
                    holder.detail!,
                    style: t.body(12, color: c.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  q == null
                      ? (holder.weight == null
                            ? '지분율 미공시'
                            : formatRatio(holder.weight))
                      : q.end == null
                      ? '보유 주식 수 미공시'
                      : '${formatCount(q.end!.toInt())}주',
                  textAlign: TextAlign.right,
                  style: t.numeric(13, color: c.textSecondary),
                ),
                if (q != null && q.change != null && comparisonDate != null)
                  Text(
                    q.change == BigInt.zero
                        ? '${formatDate(comparisonDate!)} 이후 변동 없음'
                        : '${formatDate(comparisonDate!)}보다 ${formatCount(q.change!.abs().toInt())}주 ${q.change! > BigInt.zero ? '증가' : '감소'}',
                    textAlign: TextAlign.right,
                    style: t.body(11, color: c.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
