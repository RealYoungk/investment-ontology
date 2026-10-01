import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/tokens.dart';
import 'financial_metrics.dart';
import 'metric_profile.dart';

class MetricFormulaCard extends StatelessWidget {
  const MetricFormulaCard({
    super.key,
    this.framed = true,
    required this.metric,
    required this.fsDiv,
    this.basisReason,
    this.onClose,
  });

  final bool framed;
  final DerivedMetric metric;
  final FsDiv? fsDiv;
  final String? basisReason;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = metric.derived;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: !framed
          ? null
          : BoxDecoration(
              color: c.surface,
              borderRadius: context.shape.borderRadius,
              border: Border.all(
                color: c.borderStrong,
                width: context.shape.strokeWidth,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  style: t.body(20, weight: FontWeight.w600),
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, size: 18, color: c.textPrimary),
                  tooltip: '닫기',
                ),
            ],
          ),
          if (d.value != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(metric.display, style: t.numeric(30, weight: FontWeight.w700)),
          ],
          if (metricDescriptions[metric.key] case final explanation?) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              explanation,
              style: t.body(14, color: c.textSecondary).copyWith(height: 1.5),
            ),
          ],
          if (d.missing != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              d.missing!,
              style: t.body(14, color: c.textPrimary).copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text('계산 방법', style: t.body(12, color: c.textSecondary)),
          const SizedBox(height: AppSpace.sm),
          SelectableText(
            d.formula,
            style: t.body(15, weight: FontWeight.w600).copyWith(height: 1.6),
          ),
          if (d.inputs.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Text('계산에 사용한 값', style: t.body(12, color: c.textSecondary)),
            const SizedBox(height: AppSpace.sm),
            for (final input in d.inputs)
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xs,
                      children: [
                        Text(input.label, style: t.body(14)),
                        Tooltip(
                          message: input.amount == null
                              ? '해당 입력값 미확보'
                              : '${input.amount} ${input.currency}',
                          child: Text(
                            input.amount == null
                                ? '자료 미확보'
                                : input.currency == 'KRW'
                                ? formatUnitAmountCompact(
                                    input.amount!.toDouble(),
                                    '원',
                                  )
                                : '${input.amount} ${input.currency}',
                            style: t.numeric(15, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (input.basis.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        input.basis,
                        style: t
                            .body(12, color: c.textSecondary)
                            .copyWith(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          if (fsDiv != null || basisReason != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              [
                if (fsDiv != null) '${fsDivLabel(fsDiv!)} 기준',
                if (basisReason != null) financialBasisReason(basisReason),
              ].join(' · '),
              style: t.body(12, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
