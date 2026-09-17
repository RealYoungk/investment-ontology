import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../company_ledger/formatters.dart';
import 'financial_metrics.dart';
import 'financial_report_page.dart';

enum _Period { annual, quarterly }

/// 기업 카드의 재무·시세: 파생 지표(계산식 포함), 매출·영업이익 추이, 영업이익률, 출처.
class FinancialSection extends StatefulWidget {
  const FinancialSection({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<FinancialSection> {
  CompanyFinancials? _data;
  Object? _error;
  bool _loading = true;
  FsDiv? _fsDiv;
  _Period _period = _Period.annual;
  String? _openMetric;

  bool _fetching = false;
  String? _fetchMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 이 기업의 정기보고서만 찾아 바로 받는다. 끝나면 다시 불러온다.
  Future<void> _fetchCompany() async {
    setState(() {
      _fetching = true;
      _fetchMessage = null;
    });
    try {
      var job = await client.ingest.startFinancials(corpCode: widget.corpCode);
      while (job.status == IngestStatus.running && mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await client.ingest.latestOf(job.kind) ?? job;
      }
      if (!mounted) return;
      setState(() => _fetchMessage = job.message);
      await _load();
    } on IngestException catch (e) {
      if (mounted) setState(() => _fetchMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _fetchMessage = '$e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Widget _fetchButton(BuildContext context, CompanyFinancials? data) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message:
              '이 기업의 정기보고서만 DART에서 찾아 연결·별도 재무제표를 받습니다 '
              '(보고서당 호출 2회). 전체 재무 수집이 돌고 있으면 그 작업이 끝난 뒤에 할 수 있습니다.',
          child: AppButton(
            label: _fetching ? '받는 중…' : '이 기업 재무 지금 받기',
            onPressed: _fetching ? null : _fetchCompany,
          ),
        ),
        if (_fetchMessage != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(_fetchMessage!, style: t.body(12, color: c.textMuted)),
        ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await client.financial.summary(
        widget.corpCode,
        fsDiv: _fsDiv,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _fsDiv = data?.fsDiv;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final data = _data;

    Widget body;
    if (_loading && data == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: LinearProgressIndicator(minHeight: 2),
      );
    } else if (_error != null) {
      body = AppNotice(message: '재무를 불러오지 못했습니다 — $_error');
    } else if (data == null || (data.periods.isEmpty && data.market == null)) {
      body = Text(
        data == null || data.filingCount == 0
            ? '아직 재무·시세를 수집하지 않았습니다.'
            : '정기보고서 ${formatCount(data.filingCount)}건 중 '
                  '${formatCount(data.pendingFilingCount)}건을 아직 받지 않았습니다.',
        style: t.body(13, color: c.textMuted),
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: AppSpace.sm),
          _fetchButton(context, data),
        ],
      );
    } else {
      body = _content(context, FinancialView(data));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('재무 · 시세'),
        const SizedBox(height: AppSpace.sm),
        body,
      ],
    );
  }

  Widget _content(BuildContext context, FinancialView view) {
    final c = context.colors;
    final t = context.typo;
    final data = view.data;
    final metrics = view.metrics();
    final open = metrics.where((m) => m.key == _openMetric).firstOrNull;
    final points = _period == _Period.annual ? view.annual() : view.quarterly();
    final latest = view.latest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            if (data.availableFsDivs.length > 1)
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
            else if (data.fsDiv != null)
              AppTag(label: '${fsDivLabel(data.fsDiv!)}재무제표만 있음'),
            AppToggleGroup<_Period>(
              value: _period,
              options: const {_Period.annual: '연간', _Period.quarterly: '분기'},
              onChanged: (p) => setState(() => _period = p),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        _MetricGrid(
          metrics: metrics,
          open: _openMetric,
          onTap: (key) =>
              setState(() => _openMetric = _openMetric == key ? null : key),
        ),
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: open == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: _FormulaCard(metric: open),
                ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (points.isEmpty)
          Text(
            _period == _Period.annual ? '사업보고서 재무가 없습니다.' : '분기 재무가 없습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          _TrendCharts(points: points),
        if (data.pendingFilingCount > 0 || data.filingCount == 0) ...[
          const SizedBox(height: AppSpace.sm),
          if (data.pendingFilingCount > 0)
            Text(
              '정기보고서 ${formatCount(data.pendingFilingCount)}건은 아직 받지 않았습니다.',
              style: t.body(12, color: c.textMuted),
            ),
          const SizedBox(height: AppSpace.xs),
          _fetchButton(context, data),
        ],
        const SizedBox(height: AppSpace.lg),
        _Sources(view: view, latest: latest),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.metrics,
    required this.open,
    required this.onTap,
  });

  final List<DerivedMetric> metrics;
  final String? open;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpace.sm) / 2;
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final m in metrics)
              SizedBox(
                width: width,
                child: HoverBuilder(
                  onTap: () => onTap(m.key),
                  builder: (context, hovered) {
                    final active = open == m.key;
                    return AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: active
                            ? c.inverse
                            : hovered
                            ? c.surfaceHover
                            : c.background,
                        borderRadius: context.shape.borderRadius,
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m.label,
                                style: t.body(
                                  12,
                                  color: active ? c.onInverse : c.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ƒ',
                                style: t.numeric(
                                  11,
                                  color: active ? c.onInverse : c.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.body(
                              17,
                              color: active ? c.onInverse : c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 지표의 계산식, 입력 원천 값과 그 출처.
class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.metric});

  final DerivedMetric metric;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = metric.derived;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
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
          SectionLabel('계산식 · ${metric.label}', accent: true),
          const SizedBox(height: AppSpace.sm),
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
                        formatKrw(input.amount),
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

class _TrendCharts extends StatelessWidget {
  const _TrendCharts({required this.points});

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
    final notes = {for (final p in points) ?p.derivedNote};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('매출액 · 영업이익', style: t.body(13, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.xs),
        ChartLegend(series: series),
        const SizedBox(height: AppSpace.sm),
        AppColumnChart(
          categories: categories,
          series: series,
          formatValue: formatKrwShort,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          '영업이익률 = 영업이익 ÷ 매출액',
          style: t.body(13, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.sm),
        AppLineChart(
          categories: categories,
          series: ChartSeries(
            label: '영업이익률',
            color: c.chartSeries2,
            values: [for (final p in points) p.operatingMargin],
          ),
          formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
        ),
        for (final note in notes) ...[
          const SizedBox(height: AppSpace.xs),
          Text(note, style: t.body(11.5, color: c.textMuted)),
        ],
        const SizedBox(height: AppSpace.md),
        _PointTable(points: points),
      ],
    );
  }
}

/// 차트와 같은 값을 표로 (색 없이 읽을 수 있게).
class _PointTable extends StatelessWidget {
  const _PointTable({required this.points});

  final List<PeriodPoint> points;

  static String _amount(double? v) => v == null ? '—' : formatKrwShort(v);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    TableRow row(List<String> cells, {bool header = false}) => TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
      ),
      children: [
        for (final (i, cell) in cells.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              cell,
              textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              style: header
                  ? t.body(11.5, color: c.textSecondary)
                  : t.numeric(11.5, color: c.textPrimary),
            ),
          ),
      ],
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: c.border),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        dense: true,
        title: Text('표로 보기', style: t.body(12.5, color: c.textSecondary)),
        children: [
          Table(
            columnWidths: const {0: FlexColumnWidth(0.8)},
            children: [
              row(['기간', '매출액', '영업이익', '이익률'], header: true),
              for (final p in points.reversed)
                row([
                  p.label,
                  _amount(p.revenue.value),
                  _amount(p.operatingIncome.value),
                  formatPercent(p.operatingMargin),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.view, required this.latest});

  final FinancialView view;
  final FinancialPeriod? latest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final market = view.data.market;
    final annual = [
      for (final p in view.data.periods.reversed)
        if (p.reportCode == FinancialReportCode.annual) p,
    ];
    final reports = {
      ?latest,
      ?annual.firstOrNull,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('재무 · 시세 출처'),
          for (final p in reports) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '${p.reportName} · ${view.data.fsDiv == null ? '' : fsDivLabel(view.data.fsDiv!)}',
              style: t.body(12.5, weight: FontWeight.w600),
            ),
            Text(
              'DART 접수 ${p.rceptNo}'
              '${p.supersededCount > 0 ? ' · 정정 전 보고서 ${p.supersededCount}건 보존' : ''}',
              style: t.numeric(11, color: c.textSecondary),
            ),
            Wrap(
              spacing: AppSpace.md,
              children: [
                AppButton(
                  label: '재무제표 원문 표 →',
                  variant: AppButtonVariant.link,
                  tone: c.accent,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FinancialReportPage(reportId: p.reportId),
                    ),
                  ),
                ),
                AppButton(
                  label: 'DART 공시 →',
                  variant: AppButtonVariant.link,
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${p.rceptNo}',
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (market != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              market.source?.title ?? '공공데이터포털 주식시세정보',
              style: t.body(12.5, weight: FontWeight.w600),
            ),
            Text(
              '기준일 ${formatDate(market.baseDate)} · '
              '${[for (final s in market.securities) '${s.name} 종가 ${s.closePrice == null ? '—' : '${formatCount(s.closePrice!.toInt())}원'}'].join(' · ')}',
              style: t.numeric(11, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
