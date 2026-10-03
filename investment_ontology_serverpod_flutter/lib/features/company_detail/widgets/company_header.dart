import 'company_basic_info.dart';
import '../../watchlist/watchlist_button.dart';
import '../../financials/metric_profile.dart';
import '../../financials/metric_formula_card.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/components/adaptive_detail.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';

/// 기업 상세 머리: 이름 · 개인 액션 · 기본정보 링크와 핵심 지표.
///
/// 지표는 화면에서 원천 값으로 계산한 값이다. 누르면 현재 화면에서 계산식과 입력값을 연다.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({
    super.key,
    required this.detail,
    required this.financials,
    this.onBasisChanged,
    this.changingBasis = false,
    this.basisError,
    this.selectedBasis,
    this.onCompare,
  });

  final VoidCallback? onCompare;
  final ValueChanged<FsDiv?>? onBasisChanged;
  final FsDiv? selectedBasis;
  final bool changingBasis;
  final String? basisError;
  final CompanyDetail detail;
  final CompanyFinancials? financials;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final company = detail.company;
    final fin = financials;
    final hasFinancials =
        fin != null && (fin.periods.isNotEmpty || fin.market != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double textWidth(String text, TextStyle style) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              final width = painter.width;
              painter.dispose();
              return width;
            }

            final stackName = constraints.maxWidth < 900;
            final titleStyle = t.display(
              stackName ? 26 : 30,
              color: c.textPrimary,
            );
            final actionStyle = t.body(13, weight: FontWeight.w600);
            final actionWidth =
                textWidth('관심등록됨', actionStyle) +
                54 +
                (onCompare == null
                    ? 0
                    : textWidth('기업비교', actionStyle) + 54 + AppSpace.sm);
            final compact =
                constraints.maxWidth <
                textWidth(company.name, titleStyle) + actionWidth + AppSpace.md;
            final name = stackName
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: titleStyle,
                      ),
                      if (company.nameEng?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          company.nameEng!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.body(12, color: c.textSecondary),
                        ),
                      ],
                    ],
                  )
                : Wrap(
                    spacing: AppSpace.lg,
                    runSpacing: AppSpace.sm,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        company.name,
                        style: t.display(30, color: c.textPrimary),
                      ),
                      if (company.nameEng != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            company.nameEng!,
                            style: t.body(13.5, color: c.textSecondary),
                          ),
                        ),
                    ],
                  );
            final actions = Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              alignment: WrapAlignment.end,
              children: [
                WatchlistButton(corpCode: company.corpCode, compact: compact),
                if (onCompare != null)
                  ShadButton.raw(
                    onPressed: onCompare,

                    variant: ShadButtonVariant.outline,
                    size: (compact)
                        ? ShadButtonSize.sm
                        : ShadButtonSize.regular,
                    leading: Icon(Icons.compare_arrows_outlined, size: 16),
                    child: Flexible(child: Text('기업비교')),
                  ),
              ],
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: name),
                const SizedBox(width: AppSpace.md),
                actions,
              ],
            );
          },
        ),
        CompanyBasicInfo(detail: detail),
        const SizedBox(height: AppSpace.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (fin?.fsDiv != null)
                  Text(
                    '${fsDivLabel(fin!.fsDiv!)} 기준',
                    style: t.body(12, color: c.textMuted),
                  ),
                if (fin != null &&
                    fin.availableFsDivs.isNotEmpty &&
                    onBasisChanged != null)
                  AppSelect<String>(
                    value: selectedBasis?.name ?? 'auto',
                    placeholder: '계산 기준',
                    allowClear: false,
                    options: {
                      'auto': '자동',
                      for (final div in fin.availableFsDivs)
                        div.name: fsDivLabel(div),
                    },
                    onChanged: (value) => onBasisChanged!(
                      value == null || value == 'auto'
                          ? null
                          : FsDiv.values.byName(value),
                    ),
                  ),
                if (changingBasis)
                  Text('불러오는 중…', style: t.body(12, color: c.textMuted)),
              ],
            ),
            if (basisError != null)
              Text(basisError!, style: t.body(12, color: c.textSecondary)),
            const SizedBox(height: AppSpace.xs),
            if (hasFinancials)
              _KeyStats(
                metrics: FinancialView(fin).metrics(),
                industryCode: company.industryCode,
                companyName: company.name,
                basisReason: fin.basisReason,
                corpCode: company.corpCode,
                fsDiv: fin.fsDiv,
              )
            else
              Text(
                '수집된 재무·시세가 없습니다.',
                style: t.body(13, color: c.textMuted),
              ),
          ],
        ),
      ],
    );
  }
}

class _KeyStats extends StatefulWidget {
  const _KeyStats({
    required this.metrics,
    required this.corpCode,
    required this.fsDiv,
    required this.industryCode,
    required this.companyName,
    required this.basisReason,
  });

  final String corpCode;
  final FsDiv? fsDiv;
  final List<DerivedMetric> metrics;
  final String? industryCode;
  final String companyName;
  final String? basisReason;

  @override
  State<_KeyStats> createState() => _KeyStatsState();
}

class _KeyStatsState extends State<_KeyStats> {
  bool _showAll = false;
  PeerComparison? _peers;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _KeyStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.fsDiv != widget.fsDiv) {
      if (oldWidget.corpCode != widget.corpCode) _showAll = false;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    _peers = null;
    try {
      final peers = await client.screen.peers(widget.corpCode);
      if (mounted && request == _request) setState(() => _peers = peers);
    } catch (_) {
      if (mounted && request == _request) setState(() => _peers = null);
    }
  }

  Widget _benchmark(BuildContext context, String key) {
    final peers = _peers;
    if (peers == null || peers.fsDiv != widget.fsDiv) {
      return const SizedBox.shrink();
    }
    final metric = peers.metrics
        .where((m) => m.key == key && m.value != null && m.median != null)
        .firstOrNull;
    if (metric == null) return const SizedBox.shrink();
    final unit = key == 'per' || key == 'pbr' ? '배' : '%';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: ShadTooltip(
        builder: (_) => Text(
          '${peers.label} · 유효값 ${metric.ranked ?? peers.peerCount}개사 · ${peers.fsDiv == null ? '자동' : fsDivLabel(peers.fsDiv!)} 기준\n평균이 아닌 중앙값입니다. 같은 산업분류이며 직접 경쟁사 비교는 아닙니다.',
        ),
        child: Semantics(
          tooltip:
              '${peers.label} · 유효값 ${metric.ranked ?? peers.peerCount}개사 · ${peers.fsDiv == null ? '자동' : fsDivLabel(peers.fsDiv!)} 기준\n평균이 아닌 중앙값입니다. 같은 산업분류이며 직접 경쟁사 비교는 아닙니다.',
          child: Text(
            '업종 중앙 ${metric.median!.toStringAsFixed(1)}$unit',
            style: context.typo.body(11, color: context.colors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final profile = MetricProfile.forCompany(
      widget.industryCode,
      widget.companyName,
      widget.metrics,
    );
    final keys = _showAll
        ? {...profile.keys, ...widget.metrics.map((metric) => metric.key)}
        : profile.select(widget.metrics).map((metric) => metric.key);
    final metrics = [
      for (final key in keys)
        ...widget.metrics.where(
          (m) =>
              m.key == key &&
              metricApplies(key, widget.industryCode, widget.companyName),
        ),
    ];
    final hasMore = widget.metrics.any(
      (m) =>
          !profile.keys.contains(m.key) &&
          metricApplies(m.key, widget.industryCode, widget.companyName),
    );
    if (metrics.isEmpty && !hasMore) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.border),
              bottom: BorderSide(color: c.border),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 600
                  ? 2
                  : constraints.maxWidth < 1100
                  ? 3
                  : 6;
              final cell = constraints.maxWidth / columns;
              return Wrap(
                children: [
                  for (final m in metrics)
                    HoverBuilder(
                      onTap: () => showAdaptiveDetail(
                        context: context,
                        builder: (detailContext) => MetricFormulaCard(
                          metric: m,
                          fsDiv: widget.fsDiv,
                          basisReason: widget.basisReason,
                          framed: MediaQuery.sizeOf(detailContext).width >= 600,
                          onClose: () => Navigator.of(detailContext).pop(),
                        ),
                      ),
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
                              color: Colors.transparent,
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
                            if (m.derived.value != null)
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
                            if (m.derived.value == null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpace.xs,
                                ),
                                child: Text(
                                  m.derived.missing ?? '계산에 필요한 자료 부족',
                                  style: t.body(12, color: c.textSecondary),
                                ),
                              )
                            else
                              _benchmark(context, m.key),
                            if (const {
                                  'cash',
                                  'shortTermDeposits',
                                  'cashAndDeposits',
                                }.contains(m.key) &&
                                m.derived.inputs.isNotEmpty)
                              Text(
                                '${m.derived.inputs.first.basis.split(' · ').first} 기말',
                                style: t.body(11, color: c.textSecondary),
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
        if (hasMore)
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.ghost(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Flexible(child: Text(_showAll ? '핵심 지표만 보기' : '전체 지표 보기')),
            ),
          ),
      ],
    );
  }
}
