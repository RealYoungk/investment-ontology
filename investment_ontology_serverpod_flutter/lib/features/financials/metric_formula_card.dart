import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/components/components.dart';
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
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: !framed
          ? null
          : BoxDecoration(
              color: c.background,
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
                child: SectionLabel(
                  '계산식 · ${metric.label} = ${metric.display}'
                  '${fsDiv == null ? '' : ' · ${fsDivLabel(fsDiv!)}'}',
                  accent: true,
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
          const SizedBox(height: AppSpace.sm),
          if (metricDescriptions[metric.key] case final explanation?) ...[
            Text(explanation, style: t.body(13, color: c.textPrimary)),
            const SizedBox(height: AppSpace.sm),
          ],
          if (basisReason != null) ...[
            Text(
              financialBasisReason(basisReason),
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          SelectableText(d.formula, style: t.numeric(12, color: c.textPrimary)),
          const SizedBox(height: AppSpace.sm),
          for (final input in d.inputs)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(input.label, style: t.body(12.5)),
                      ),
                      Text(
                        input.currency == 'KRW' || input.amount == null
                            ? formatKrw(input.amount)
                            : '${input.amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')} ${input.currency}',
                        style: t.numeric(12.5, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(input.basis, style: t.numeric(10.5, color: c.textMuted)),
                ],
              ),
            ),
          if (d.missing != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '계산하지 않음: ${d.missing}',
              style: t.body(12, color: c.accent),
            ),
          ],
        ],
      ),
    );
  }
}
