import 'statement_conflict_notice.dart';
import 'statement_availability_notice.dart';
import 'split_plan_source_registry.dart';
import 'split_plan_documents_section.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/components/adaptive_detail.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'financial_metrics.dart';
import 'metric_profile.dart';
import 'issuer_financials_section.dart';
import 'issuer_financial_source_registry.dart';

String _financialAmount(double value, String currency) => currency == 'KRW'
    ? formatKrwShort(value)
    : '${formatKrwShort(value).replaceAll('원', '')} $currency';

enum _Period { annual, quarterly }

/// 기업 상세의 재무 탭: 실적·수익성·현금흐름 추이와 원천 보고서.
class FinancialSection extends StatefulWidget {
  const FinancialSection({
    super.key,
    required this.corpCode,
    this.initialData,
    this.industryCode,
    this.companyName = '',
    this.dataVersion = 0,
    this.showBasisSelector = true,
  });

  final String corpCode;
  final String? industryCode;
  final String companyName;
  final bool showBasisSelector;

  /// 수집이 끝날 때마다 오른다. 바뀌면 다시 읽되 고른 구분은 그대로 둔다.
  final int dataVersion;

  /// 이미 불러온 기본(연결 우선) 재무. 있으면 처음에 다시 부르지 않는다.
  final CompanyFinancials? initialData;

  @override
  State<FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<FinancialSection> {
  late CompanyFinancials? _data = widget.initialData;
  Object? _error;
  late bool _loading = widget.initialData == null;
  late FsDiv? _fsDiv = widget.initialData?.fsDiv;
  _Period _period = _Period.annual;

  @override
  void initState() {
    super.initState();
    if (widget.initialData == null) _load();
  }

  @override
  void didUpdateWidget(covariant FinancialSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData &&
        widget.initialData != null) {
      _seq++;
      _data = widget.initialData;
      _fsDiv = _data?.fsDiv;
      _loading = false;
      _error = null;
    } else if (oldWidget.dataVersion != widget.dataVersion) {
      _load();
    }
  }

  /// 늦게 온 응답이 새 응답을 덮지 않게 하는 요청 번호 (연결↔별도를 빨리 누를 때).
  int _seq = 0;

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final data = await client.financial.summary(
        widget.corpCode,
        fsDiv: _fsDiv,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _data = data;
        _fsDiv = data?.fsDiv;
        _error = null;
      });
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final data = _data;
    final sourceConflict =
        data?.statementAvailabilitySources?.any(
          (s) => StatementConflictNotice.evidence(s, widget.corpCode) != null,
        ) ??
        false;
    final sourceNotPresented =
        data?.statementAvailabilitySources?.any(
          (s) =>
              StatementAvailabilityNotice.evidence(s, widget.corpCode) != null,
        ) ??
        false;

    Widget body;
    if (_loading && data == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: LinearProgressIndicator(minHeight: 2),
      );
    } else if (_error != null) {
      body = ReadFailureNotice(subject: '재무', retry: _load);
    } else if (data == null || (data.periods.isEmpty && data.market == null)) {
      body = Text(
        data == null || data.filingCount == 0
            ? (IssuerFinancialSourceRegistry.supportsCorp(widget.corpCode) ||
                      SplitPlanSourceRegistry.supports(widget.corpCode))
                  ? '정기보고서 API 재무 데이터는 아직 없습니다.'
                  : '아직 재무·시세를 수집하지 않았습니다.'
            : sourceConflict
            ? '공식 원문을 확인했지만 당기 수치·기간 표기의 충돌로 재무 숫자를 저장하지 않았습니다.'
            : sourceNotPresented
            ? '공식 원문을 확인했지만 해당 기간의 당기 재무 숫자는 제시되지 않았습니다.'
            : '정기보고서 ${formatCount(data.filingCount)}건 중 '
                  '${formatCount(data.pendingFilingCount)}건을 아직 받지 않았습니다.',
        style: t.body(13, color: c.textMuted),
      );
    } else {
      body = _content(context, FinancialView(data));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data != null)
          StatementAvailabilityNotice(
            corpCode: widget.corpCode,
            sources: data.statementAvailabilitySources ?? const [],
          ),
        body,
        SplitPlanDocumentsSection(
          corpCode: widget.corpCode,
          dataVersion: widget.dataVersion,
        ),
        IssuerFinancialsSection(
          corpCode: widget.corpCode,
          dataVersion: widget.dataVersion,
        ),
        IssuerFinancialsSection(
          corpCode: widget.corpCode,
          dataVersion: widget.dataVersion,
          ownAnnual: true,
        ),
      ],
    );
  }

  Widget _content(BuildContext context, FinancialView view) {
    final c = context.colors;
    final t = context.typo;
    final data = view.data;
    final points = _period == _Period.annual ? view.annual() : view.quarterly();
    final currencies = {
      for (final p in data.periods)
        for (final l in p.lines) l.currency ?? 'KRW',
    };
    final currency = currencies.firstOrNull ?? 'KRW';
    if (currencies.length > 1) {
      return AppNotice(
        message: '${currencies.join("·")} 표시 통화가 달라 추이를 합산하지 않습니다.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            if (widget.showBasisSelector && data.availableFsDivs.length > 1)
              AppToggleGroup<FsDiv>(
                value: data.fsDiv ?? FsDiv.consolidated,
                options: {
                  for (final d in data.availableFsDivs) d: fsDivLabel(d),
                },
                onChanged: (d) {
                  if (d == _fsDiv) return;
                  _fsDiv = d;
                  _load();
                },
              )
            else if (widget.showBasisSelector && data.fsDiv != null)
              AppTag(label: '${fsDivLabel(data.fsDiv!)}재무제표만 있음'),
            AppToggleGroup<_Period>(
              value: _period,
              options: const {_Period.annual: '연간', _Period.quarterly: '분기'},
              onChanged: (p) => setState(() => _period = p),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        if (points.isEmpty)
          Text(
            _period == _Period.annual ? '사업보고서 재무가 없습니다.' : '분기 재무가 없습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          _TrendCharts(
            points: points,
            isQuarterly: _period == _Period.quarterly,
            currency: currency,
            showMargin: metricApplies(
              'operatingMargin',
              widget.industryCode,
              widget.companyName,
            ),
          ),
        // 분기 실적은 들쭉날쭉해 한 해치로 더해 놓아야 흐름이 보인다.
        () {
          final revenue = view.trailingSeries('revenue');
          final operating = view.trailingSeries('operatingIncome');
          if (revenue.length < 3) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpace.xl),
            child: _TrailingChart(
              revenue: revenue,
              operating: operating,
              net: view.trailingSeries('netIncome'),
              showMargin: metricApplies(
                'operatingMargin',
                widget.industryCode,
                widget.companyName,
              ),
              currency: currency,
            ),
          );
        }(),
        if (metricApplies(
          'freeCashFlow',
          widget.industryCode,
          widget.companyName,
        )) ...[
          () {
            final cash = _period == _Period.quarterly
                ? view.cashFlowQuarterly()
                : [
                    for (final p in view.cashFlowAnnual())
                      if (p.operating != null || p.label.endsWith('없음')) p,
                  ];
            if (cash.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.xl),
              child: _CashFlowChart(
                points: cash,
                currency: currency,
                isQuarterly: _period == _Period.quarterly,
              ),
            );
          }(),
        ],
      ],
    );
  }
}

/// 지표의 계산식, 입력 원천 값과 그 출처.
class _TrendCharts extends StatelessWidget {
  final String currency;
  const _TrendCharts({
    required this.points,
    this.isQuarterly = false,
    this.showMargin = true,
    this.currency = 'KRW',
  });
  final bool showMargin;
  final bool isQuarterly;

  final List<PeriodPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final categories = [for (final p in points) p.label];
    final series = [
      ChartSeries(
        label: '매출액',
        color: c.chartSeries1,
        values: [for (final p in points) p.revenue.value],
      ),
      ChartSeries(
        label: '영업이익',
        color: c.chartSeries2,
        values: [for (final p in points) p.operatingIncome.value],
      ),
    ];
    final margin = ChartSeries(
      label: '영업이익률',
      color: c.chartSeries2,
      values: [for (final p in points) p.operatingMargin],
      isLine: true,
    );
    final netMargin = ChartSeries(
      label: '순이익률',
      color: c.chartSeries3,
      values: [for (final p in points) p.netMargin],
      isLine: true,
      isDashed: true,
    );
    final notes = {for (final p in points) ?p.derivedNote};

    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isQuarterly
                ? '분기 실적 · 계절성'
                : showMargin
                ? '매출액 · 이익률'
                : '매출액 · 영업이익',
            style: t.body(13, weight: FontWeight.w600),
          ),
          if (isQuarterly) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              '매년 어느 분기에 매출과 이익이 몰리는지 비교합니다.',
              style: t.body(12, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          ChartLegend(
            series: showMargin
                ? [
                    ChartSeries(
                      label: '매출액 · 왼쪽',
                      color: series.first.color,
                      values: series.first.values,
                    ),
                    ChartSeries(
                      label: '영업이익률 · 오른쪽 %',
                      color: margin.color,
                      values: margin.values,
                      isLine: true,
                    ),
                    ChartSeries(
                      label: '순이익률 · 오른쪽 %',
                      color: netMargin.color,
                      values: netMargin.values,
                      isLine: true,
                      isDashed: true,
                    ),
                  ]
                : series,
          ),
          const SizedBox(height: AppSpace.sm),
          if (showMargin)
            AppComboChart(
              categories: categories,
              columnSeries: series.first,
              lineSeries: margin,
              additionalLineSeries: [netMargin],
              extraTooltipSeries: [
                ChartSeries(
                  label: '영업이익',
                  color: c.textSecondary,
                  values: series[1].values,
                ),
                ChartSeries(
                  label: '당기순이익',
                  color: c.chartSeries3,
                  values: [for (final p in points) p.netIncome?.value],
                ),
              ],
              formatValue: (v) => _financialAmount(v, currency),
              formatLineValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
            )
          else
            AppColumnChart(
              categories: categories,
              series: series,
              formatValue: (v) => _financialAmount(v, currency),
            ),
          _FinancialTable(
            currency: currency,
            labels: [for (final p in points) p.label],
            columns: [
              '매출액',
              '영업이익',
              '당기순이익',
              if (showMargin) '영업이익률',
              if (showMargin) '순이익률',
            ],
            values: [
              for (final p in points)
                [
                  p.revenue.value,
                  p.operatingIncome.value,
                  p.netIncome?.value,
                  if (showMargin) p.operatingMargin,
                  if (showMargin) p.netMargin,
                ],
            ],
            percentColumns: showMargin ? const {3, 4} : const {},
            note: isQuarterly
                ? '각 분기 3개월 실적 · 4분기는 연간 − 3분기 누적으로 계산합니다.'
                : '각 사업연도의 연간 실적입니다.',
          ),
          for (final note in notes) ...[
            const SizedBox(height: AppSpace.xs),
            Text(note, style: t.body(11.5, color: c.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// 분기마다의 최근 12개월(TTM) 매출·영업이익. 계절성을 걷어 낸 흐름이다.
class _TrailingChart extends StatelessWidget {
  final String currency;
  const _TrailingChart({
    required this.revenue,
    required this.operating,
    required this.net,
    required this.showMargin,
    this.currency = 'KRW',
  });

  final List<
    ({String label, int year, FinancialReportCode code, double? value})
  >
  revenue;
  final List<
    ({String label, int year, FinancialReportCode code, double? value})
  >
  operating;
  final List<
    ({String label, int year, FinancialReportCode code, double? value})
  >
  net;
  final bool showMargin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final byLabel = {for (final o in operating) o.label: o.value};
    final netByLabel = {for (final n in net) n.label: n.value};
    double? ratio(double? income, double? sales) =>
        income == null || sales == null || sales <= 0 ? null : income / sales;
    final margins = [
      ChartSeries(
        label: '영업이익률',
        color: c.chartSeries2,
        values: [for (final r in revenue) ratio(byLabel[r.label], r.value)],
        isLine: true,
      ),
      ChartSeries(
        label: '순이익률',
        color: c.chartSeries3,
        values: [for (final r in revenue) ratio(netByLabel[r.label], r.value)],
        isLine: true,
        isDashed: true,
      ),
    ];
    final series = [
      ChartSeries(
        label: '매출액',
        color: c.chartSeries1,
        values: [for (final r in revenue) r.value],
      ),
      ChartSeries(
        label: '영업이익',
        color: c.chartSeries2,
        values: [for (final r in revenue) byLabel[r.label]],
        isLine: true,
      ),
    ];
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '최근 12개월 · 계절 변동을 줄인 실적',
                  style: t.body(13, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: c.textMuted),
                tooltip: '최근 12개월 실적 읽는 법',
                onPressed: () => showAdaptiveDetail(
                  context: context,
                  builder: (context) => const _TrailingExplanation(),
                ),
              ),
            ],
          ),
          Text(
            '분기별 등락보다 매출과 수익성의 큰 흐름을 봅니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.xs),
          ChartLegend(
            series: showMargin
                ? [
                    ChartSeries(
                      label: '매출액 · 왼쪽',
                      color: series.first.color,
                      values: series.first.values,
                    ),
                    for (final m in margins)
                      ChartSeries(
                        label: '${m.label} · 오른쪽 %',
                        color: m.color,
                        values: m.values,
                        isLine: true,
                        isDashed: m.isDashed,
                      ),
                  ]
                : series,
          ),
          const SizedBox(height: AppSpace.sm),
          if (showMargin)
            AppComboChart(
              categories: [for (final r in revenue) r.label],
              columnSeries: series.first,
              lineSeries: margins.first,
              additionalLineSeries: [margins.last],
              extraTooltipSeries: [
                series[1],
                ChartSeries(
                  label: '당기순이익',
                  color: c.chartSeries3,
                  values: [for (final r in revenue) netByLabel[r.label]],
                ),
              ],
              formatValue: (v) => _financialAmount(v, currency),
              formatLineValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
              height: 220,
            )
          else
            AppLineChart.many(
              categories: [for (final r in revenue) r.label],
              series: series,
              formatValue: (v) => _financialAmount(v, currency),
              height: 180,
            ),
          _FinancialTable(
            currency: currency,
            labels: [for (final r in revenue) r.label],
            columns: [
              '매출액',
              '영업이익',
              '당기순이익',
              if (showMargin) '영업이익률',
              if (showMargin) '순이익률',
            ],
            values: [
              for (final r in revenue)
                [
                  r.value,
                  byLabel[r.label],
                  netByLabel[r.label],
                  if (showMargin) ratio(byLabel[r.label], r.value),
                  if (showMargin) ratio(netByLabel[r.label], r.value),
                ],
            ],
            percentColumns: showMargin ? const {3, 4} : const {},
            note: '각 시점까지 최근 12개월(TTM) 실적입니다.',
          ),
        ],
      ),
    );
  }
}

class _TrailingExplanation extends StatelessWidget {
  const _TrailingExplanation();

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '최근 12개월 실적 읽는 법',
                  style: t.body(16, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            '각 시점까지의 1년치 실적입니다. 계절에 따른 분기 변동을 줄여 흐름을 볼 수 있습니다.',
            style: t.body(13),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('매출액 · 사업 규모가 커지는지', style: t.body(13)),
          const SizedBox(height: AppSpace.sm),
          Text('영업이익률 · 본업의 수익성이 좋아지는지', style: t.body(13)),
          const SizedBox(height: AppSpace.sm),
          Text('순이익률 · 영업 외 손익과 세금까지 반영한 수익성', style: t.body(13)),
          const SizedBox(height: AppSpace.xl),
          Text('계산 기준', style: t.body(12, weight: FontWeight.w600)),
          const SizedBox(height: AppSpace.sm),
          Text(
            '분기·반기: 전년 연간 + 올해 누적 − 전년 같은 기간 누적\n'
            '연말: 해당 연도의 연간 실적',
            style: t.body(12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 현금흐름: 영업활동으로 번 현금에서 설비에 쓴 돈을 뺀 것이 잉여현금흐름이다.
class _CashFlowChart extends StatelessWidget {
  final String currency;
  const _CashFlowChart({
    required this.points,
    this.currency = 'KRW',
    this.isQuarterly = false,
  });

  final List<CashPoint> points;
  final bool isQuarterly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final series = [
      ChartSeries(
        label: '영업활동 현금흐름',
        color: c.chartSeries1,
        values: [for (final p in points) p.operating],
      ),
      ChartSeries(
        label: '잉여현금흐름',
        color: c.chartSeries2,
        values: [for (final p in points) p.free],
      ),
    ];
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('현금흐름', style: t.body(13, weight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18, color: c.textMuted),
                tooltip: '현금흐름 읽는 법',
                onPressed: () => showAdaptiveDetail(
                  context: context,
                  builder: (context) =>
                      _CashFlowExplanation(isQuarterly: isQuarterly),
                ),
              ),
            ],
          ),
          Text(
            isQuarterly
                ? '각 분기 3개월 동안, 투자 후에도 현금이 남았는지 봅니다.'
                : '투자 후에도 현금이 남는지, 여러 해의 흐름을 봅니다.',
            style: t.body(12, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.xs),
          ChartLegend(
            series: [
              ChartSeries(
                label: '사업에서 들어온 현금',
                color: series[0].color,
                values: series[0].values,
              ),
              ChartSeries(
                label: '설비 투자 후 남은 현금',
                color: series[1].color,
                values: series[1].values,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (!points.any((p) => p.operating != null || p.free != null))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Text(
                points.map((p) => p.missing).nonNulls.firstOrNull ??
                    '현금흐름 계정이 없습니다.',
                style: t.body(12, color: c.textSecondary),
              ),
            )
          else
            AppColumnChart(
              categories: [for (final p in points) p.label],
              series: series,
              categoryNotes: [for (final p in points) p.missing],
              extraTooltipSeries: [
                ChartSeries(
                  label: '설비 투자 · 유형자산 취득',
                  color: c.textSecondary,
                  values: [for (final p in points) p.capex],
                ),
              ],
              formatValue: (v) => _financialAmount(v, currency),
            ),
          _FinancialTable(
            currency: currency,
            labels: [for (final p in points) p.label],
            columns: const ['영업활동 현금흐름', '유형자산 취득', '잉여현금흐름'],
            values: [
              for (final p in points) [p.operating, p.capex, p.free],
            ],
            note: isQuarterly
                ? '각 분기 3개월 금액 · 누적값에서 직전 누적값을 차감합니다.'
                : '각 사업연도의 연간 금액입니다.',
            missingNotes: {
              for (final p in points)
                if (p.missing != null) '${p.label}: ${p.missing}',
            }.toList(),
          ),
        ],
      ),
    );
  }
}

class _CashFlowExplanation extends StatelessWidget {
  const _CashFlowExplanation({this.isQuarterly = false});

  final bool isQuarterly;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '현금흐름 읽는 법',
                  style: t.body(16, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            '사업에서 들어온 현금 · 영업활동 현금흐름',
            style: t.body(13, weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '판매대금에서 원가·인건비·세금 등 영업 지출을 반영한 현금입니다. 음수면 영업에서 현금이 더 많이 나갔다는 뜻입니다.',
            style: t.body(13),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            '설비 투자 후 남은 현금 · 잉여현금흐름',
            style: t.body(13, weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '영업현금에서 유형자산 취득에 쓴 돈을 뺀 값입니다. 남은 현금은 빚을 갚거나 배당할 여력을 보여줍니다.',
            style: t.body(13),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            '두 막대의 차이는 설비 투자액입니다. 잉여현금이 음수라면 영업에서 현금이 부족했는지, 설비 투자가 늘었는지 나누어 봅니다.',
            style: t.body(13),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            '계산 기준 · 영업활동 현금흐름 − 유형자산 취득액',
            style: t.body(12, color: c.textSecondary),
          ),
          if (isQuarterly) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '분기는 해당 누적값에서 직전 분기 누적값을 뺀 3개월 금액입니다. '
              '1분기는 공시값, 4분기는 연간 − 3분기 누적값을 사용합니다.',
              style: t.body(12, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 차트와 동일한 계산 결과를 일정한 단위로 비교한다.
class _FinancialTable extends StatelessWidget {
  const _FinancialTable({
    required this.currency,
    required this.labels,
    required this.columns,
    required this.values,
    required this.note,
    this.percentColumns = const {},
    this.missingNotes = const [],
  });

  final String currency;
  final List<String> labels;
  final List<String> columns;
  final List<List<double?>> values;
  final String note;
  final Set<int> percentColumns;
  final List<String> missingNotes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpace.sm),
        title: Text(
          '표로 보기',
          style: context.typo.body(12, color: c.textSecondary),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$note\n단위: ${currency == 'KRW' ? '백만원' : currency} · —는 해당 기간의 값 미확보 · 금액은 소수 첫째 자리 반올림',
              style: context.typo.body(11.5, color: c.textMuted),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          AppDataTable(
            columns: [
              const AppColumn('기간', minWidth: 90),
              for (final column in columns)
                AppColumn(column, numeric: true, minWidth: 115),
            ],
            rows: [
              for (final (rowIndex, label) in labels.indexed)
                AppRow([
                  AppDataTable.text(context, label, nowrap: true),
                  for (final (columnIndex, value) in values[rowIndex].indexed)
                    value == null
                        ? AppDataTable.text(context, null, numeric: true)
                        : Tooltip(
                            message: percentColumns.contains(columnIndex)
                                ? formatPercent(value)
                                : formatSourceAmount(
                                    value,
                                    currency == 'KRW' ? '원' : currency,
                                  ),
                            child: AppDataTable.text(
                              context,
                              percentColumns.contains(columnIndex)
                                  ? formatPercent(value)
                                  : (value / (currency == 'KRW' ? 1000000 : 1))
                                        .toStringAsFixed(1)
                                        .replaceAllMapped(
                                          RegExp(r'\B(?=(\d{3})+(?!\d))'),
                                          (_) => ',',
                                        ),
                              numeric: true,
                              nowrap: true,
                            ),
                          ),
                ]),
            ],
          ),
          for (final missing in missingNotes)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                missing,
                style: context.typo.body(11.5, color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
