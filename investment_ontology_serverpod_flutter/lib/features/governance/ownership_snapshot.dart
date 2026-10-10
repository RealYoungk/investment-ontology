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
    final kinds = data.shareholders
        .where((s) => GovernanceView.isCommon(s.stockKind))
        .map((s) => s.stockKind?.trim() ?? '주식 종류 미표기')
        .toSet();
    final basis = kinds.length == 1 ? kinds.single : '공시 주식 종류 혼재';
    final valid =
        total != null && total >= 0 && total <= 100 && kinds.length == 1;
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          Text(
            '${date == null ? '기준일 미확인' : '${formatDate(date)} 기준'} · $basis',
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
            _OwnershipComposition(holders: holders, total: total, basis: basis),
          ] else
            Text(
              '보통주 지분율을 확인할 자료가 부족해요.',
              style: t.body(12, color: c.textSecondary),
            ),
          const SizedBox(height: AppSpace.md),
          for (final holder in primary)
            _SnapshotHolderRow(
              holder: holder,
              shares: snapshotQuantities(data, holder).end,
            ),
          if (minor.isNotEmpty)
            Material(
              color: c.surface,
              child: ShadAccordion<int>(
                maintainState: false,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Text(
                      '소량 보유 관계인 ${minor.length}명',
                      style: t.body(12, color: c.textSecondary),
                    ),
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
    this.shares,
    this.comparisonDate,
  });
  final BigInt? shares;
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
                if (q == null && shares != null)
                  Text(
                    '${formatCount(shares!.toInt())}주',
                    style: t.numeric(11, color: c.textMuted),
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

class _OwnershipComposition extends StatelessWidget {
  const _OwnershipComposition({
    required this.holders,
    required this.total,
    required this.basis,
  });
  final List<GovernanceNode> holders;
  final double total;
  final String basis;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette = categoricalChartColors(context);
    final known = holders
        .where((h) => h.weight != null && h.weight! > 0)
        .toList();
    final sum = known.fold<double>(0, (v, h) => v + h.weight!);
    if (sum > 100 || (sum - total).abs() > 0.2) {
      return Text(
        '주주별 지분 합계와 공시 합계가 달라 구성 차트를 표시하지 않습니다.',
        style: context.typo.body(12, color: c.textMuted),
      );
    }
    final small = known
        .where((h) => h.weight! < 1)
        .fold<double>(0, (v, h) => v + h.weight!);
    final segments = [
      for (final h in known.where((h) => h.weight! >= 1)) (h.name, h.weight!),
      if (small > 0) ('소량 보유 관계인', small),
      if (total > sum) ('그 외 관계인', total - sum),
      if (total < 100) ('그 외 주주', 100 - total),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                for (final (i, s) in segments.indexed)
                  ShadTooltip(
                    builder: (_) => Text('${s.$1} · ${formatRatio(s.$2)}'),
                    child: Semantics(
                      label: '${s.$1} ${formatRatio(s.$2)}',
                      child: Container(
                        width: box.maxWidth * s.$2 / 100,
                        color: s.$1 == '그 외 주주'
                            ? c.chartGrid
                            : palette[i % palette.length],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.xs,
          children: [
            for (final (i, s) in segments.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: s.$1 == '그 외 주주'
                        ? c.chartGrid
                        : palette[i % palette.length],
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${s.$1} ${formatRatio(s.$2)}',
                    style: context.typo.body(11),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '그 외 주주 = 전체 $basis에서 최대주주·관계인 공시 지분을 뺀 비중',
          style: context.typo.body(11, color: c.textMuted),
        ),
      ],
    );
  }
}
