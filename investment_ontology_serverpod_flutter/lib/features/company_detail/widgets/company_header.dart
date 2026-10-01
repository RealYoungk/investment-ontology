import 'company_basic_info.dart';
import '../../financials/metric_profile.dart';
import '../../financials/metric_formula_card.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/components/adaptive_detail.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';

/// 기업 상세 머리: 이름 · 시장 · 코드 · 업종과 핵심 지표 한 줄.
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
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
              ),
            ),
            if (onCompare != null) ...[
              const SizedBox(width: AppSpace.md),
              Tooltip(
                message: '다른 기업과 비교',
                child: AppButton(
                  icon: Icons.business_outlined,
                  label: '비교',
                  onPressed: onCompare,
                ),
              ),
            ],
          ],
        ),
        CompanyBasicInfo(detail: detail),
        const SizedBox(height: AppSpace.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpace.md),
            if (fin?.fsDiv != null)
              Text(
                '${fsDivLabel(fin!.fsDiv!)} 기준',
                style: t.body(12, color: c.textMuted),
              ),
            const SizedBox(height: AppSpace.sm),
            if (fin != null &&
                fin.availableFsDivs.isNotEmpty &&
                onBasisChanged != null) ...[
              Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: '재무 계산 기준 변경',
                    initialValue: selectedBasis?.name ?? 'auto',
                    onSelected: (value) => onBasisChanged!(
                      value == 'auto' ? null : FsDiv.values.byName(value),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'auto', child: Text('자동')),
                      for (final div in fin.availableFsDivs)
                        PopupMenuItem(
                          value: div.name,
                          child: Text(fsDivLabel(div)),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xs,
                      ),
                      child: Text(
                        '계산 기준: ${selectedBasis == null ? '자동' : fsDivLabel(selectedBasis!)} ▾',
                        style: t.body(12, color: c.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  if (changingBasis)
                    Text('불러오는 중…', style: t.body(12, color: c.textMuted)),
                ],
              ),
              if (basisError != null)
                Text(basisError!, style: t.body(12, color: c.textSecondary)),
              const SizedBox(height: AppSpace.sm),
            ],
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
      child: Tooltip(
        message:
            '${peers.label} · 유효값 ${metric.ranked ?? peers.peerCount}개사 · ${peers.fsDiv == null ? '자동' : fsDivLabel(peers.fsDiv!)} 기준\n평균이 아닌 중앙값입니다. 같은 산업분류이며 직접 경쟁사 비교는 아닙니다.',
        child: Text(
          '업종 중앙 ${metric.median!.toStringAsFixed(1)}$unit',
          style: context.typo.body(11, color: context.colors.textSecondary),
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
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll ? '핵심 지표만 보기' : '전체 지표 보기'),
            ),
          ),
      ],
    );
  }
}
