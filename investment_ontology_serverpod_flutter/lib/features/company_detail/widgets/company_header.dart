import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import '../../financials/financial_metrics.dart';

/// 기업 상세 머리: 이름 · 시장 · 코드 · 업종과 핵심 지표 한 줄.
///
/// 지표는 화면에서 원천 값으로 계산한 값이다. 누르면 재무 탭에서 계산식과 입력값을 연다.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({
    super.key,
    required this.detail,
    required this.financials,
    required this.openMetric,
    required this.onOpenMetric,
  });

  final CompanyDetail detail;
  final CompanyFinancials? financials;

  /// 계산식을 펼친 지표 (강조 표시).
  final String? openMetric;
  final ValueChanged<String> onOpenMetric;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final company = detail.company;
    final industry = detail.industryPath.lastOrNull;
    final fin = financials;
    final hasFinancials =
        fin != null && (fin.periods.isNotEmpty || fin.market != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(company.name, style: t.display(40, color: c.textPrimary)),
            if (company.nameEng != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  company.nameEng!,
                  style: t.body(13.5, color: c.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 10,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTag(
              label: marketLabel(company.market),
              color: marketColor(context, company.market),
              filled: true,
              numeric: true,
              size: AppTagSize.medium,
            ),
            if (company.stockCode != null)
              AppTag(
                label: company.stockCode!,
                numeric: true,
                size: AppTagSize.medium,
              ),
            AppTag(
              label: 'DART ${company.corpCode}',
              numeric: true,
              size: AppTagSize.medium,
            ),
            if (industry != null)
              Text(
                '${industry.code} ${industry.name}',
                style: t.body(13.5, color: c.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        if (hasFinancials)
          _KeyStats(
            metrics: FinancialView(fin).metrics(),
            fsDiv: fin.fsDiv,
            open: openMetric,
            onTap: onOpenMetric,
          )
        else
          Text(
            '아직 재무·시세를 수집하지 않았습니다. 재무 탭에서 이 기업만 바로 받을 수 있습니다.',
            style: t.body(13, color: c.textMuted),
          ),
      ],
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({
    required this.metrics,
    required this.fsDiv,
    required this.open,
    required this.onTap,
  });

  final List<DerivedMetric> metrics;
  final FsDiv? fsDiv;
  final String? open;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderStrong, width: 1.5),
              bottom: BorderSide(color: c.border),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 좁은 화면에서는 두 칸씩 놓는다.
              final cell = constraints.maxWidth < 600
                  ? (constraints.maxWidth / 2).floorToDouble()
                  : 200.0;
              return Wrap(
                children: [
                  for (final m in metrics)
                    HoverBuilder(
                      onTap: () => onTap(m.key),
                      builder: (context, hovered) => AnimatedContainer(
                        duration: AppMotion.fast,
                        width: cell,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.sm,
                          AppSpace.md,
                          AppSpace.lg,
                          AppSpace.md,
                        ),
                        decoration: BoxDecoration(
                          color: hovered ? c.surfaceHover : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: open == m.key
                                  ? c.accent
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.label,
                              style: t.body(12, color: c.textSecondary),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                m.display,
                                maxLines: 1,
                                style: t.numeric(
                                  20,
                                  color: m.derived.value == null
                                      ? c.textMuted
                                      : c.textPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '${fsDiv == null ? '' : '${fsDivLabel(fsDiv!)}재무제표 · '}'
          '원천 값으로 화면에서 계산 · 누르면 계산식과 입력값',
          style: t.body(11.5, color: c.textMuted),
        ),
      ],
    );
  }
}
