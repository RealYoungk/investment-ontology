import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/ingest_monitor.dart';
import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'financial_metrics.dart';

enum _Period { annual, quarterly }

/// 기업 상세의 재무 탭: 파생 지표(계산식 포함), 매출·영업이익 추이, 영업이익률, 출처.
class FinancialSection extends StatefulWidget {
  const FinancialSection({
    super.key,
    required this.corpCode,
    this.initialData,
    this.openMetric,
    this.onCloseMetric,
    this.dataVersion = 0,
  });

  final String corpCode;

  /// 수집이 끝날 때마다 오른다. 바뀌면 다시 읽되 고른 구분은 그대로 둔다.
  final int dataVersion;

  /// 이미 불러온 기본(연결 우선) 재무. 있으면 처음에 다시 부르지 않는다.
  final CompanyFinancials? initialData;

  /// 계산식을 펼칠 지표 ([DerivedMetric.key]). 지표는 기업 상세 머리에서 고른다.
  final String? openMetric;
  final VoidCallback? onCloseMetric;

  @override
  State<FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<FinancialSection> {
  late CompanyFinancials? _data = widget.initialData;
  Object? _error;
  late bool _loading = widget.initialData == null;
  late FsDiv? _fsDiv = widget.initialData?.fsDiv;
  _Period _period = _Period.annual;

  bool _fetching = false;
  String? _fetchMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData == null) _load();
  }

  @override
  void didUpdateWidget(covariant FinancialSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) _load();
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
      // 기업 상세 머리의 지표 등 다른 화면도 새 재무를 다시 불러오게 한다.
      IngestMonitor.instance.poke();
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
              '(보고서당 호출 2회). 전체 재무 수집이 돌고 있어도 함께 받습니다.',
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
    final open = metrics.where((m) => m.key == widget.openMetric).firstOrNull;
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
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: open == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpace.md),
                  child: _FormulaCard(
                    metric: open,
                    fsDiv: data.fsDiv,
                    onClose: widget.onCloseMetric,
                  ),
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
        // 분기 실적은 들쭉날쭉해 한 해치로 더해 놓아야 흐름이 보인다.
        () {
          final revenue = view.trailingSeries('revenue');
          final operating = view.trailingSeries('operatingIncome');
          if (revenue.length < 3) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrailingChart(revenue: revenue, operating: operating),
                const SizedBox(height: AppSpace.lg),
                _TrailingRatios(rows: view.trailingRatios()),
              ],
            ),
          );
        }(),
        if (_period == _Period.annual) ...[
          () {
            final cash = [
              for (final p in view.cashFlowAnnual())
                if (p.operating != null) p,
            ];
            if (cash.length < 2) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.xl),
              child: _CashFlowChart(points: cash),
            );
          }(),
        ],
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

/// 지표의 계산식, 입력 원천 값과 그 출처.
class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.metric, required this.fsDiv, this.onClose});

  final DerivedMetric metric;
  final FsDiv? fsDiv;
  final VoidCallback? onClose;

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
          SectionLabel(
            '계산식 · ${metric.label} = ${metric.display}'
            '${fsDiv == null ? '' : ' · ${fsDivLabel(fsDiv!)}'}',
            accent: true,
            trailing: onClose == null
                ? null
                : IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, size: 18, color: c.textPrimary),
                    tooltip: '닫기',
                  ),
          ),
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

/// 분기마다의 최근 12개월 이익률. 계절을 걷어 낸 수익성 흐름이다.
class _TrailingRatios extends StatelessWidget {
  const _TrailingRatios({required this.rows});

  final List<({String label, double? margin, double? netMargin, double? roe})>
  rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (rows.length < 3) return const SizedBox.shrink();
    final series = [
      ChartSeries(
        label: '영업이익률',
        color: c.chartSeries2,
        values: [for (final r in rows) r.margin],
      ),
      ChartSeries(
        label: '순이익률',
        color: c.chartSeries1,
        values: [for (final r in rows) r.netMargin],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '수익성 추이 · 최근 12개월끼리 나눈 값',
          style: t.body(13, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.xs),
        ChartLegend(series: series),
        const SizedBox(height: AppSpace.sm),
        AppLineChart.many(
          categories: [for (final r in rows) r.label],
          series: series,
          formatValue: (v) => '${v.toStringAsFixed(0)}%',
          height: 150,
        ),
      ],
    );
  }
}

/// 분기마다의 최근 12개월(TTM) 매출·영업이익. 계절성을 걷어 낸 흐름이다.
class _TrailingChart extends StatelessWidget {
  const _TrailingChart({required this.revenue, required this.operating});

  final List<
    ({String label, int year, FinancialReportCode code, double? value})
  >
  revenue;
  final List<
    ({String label, int year, FinancialReportCode code, double? value})
  >
  operating;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final byLabel = {for (final o in operating) o.label: o.value};
    final series = [
      ChartSeries(
        label: '매출액 (최근 12개월)',
        color: c.chartSeries1,
        values: [for (final r in revenue) r.value],
      ),
      ChartSeries(
        label: '영업이익 (최근 12개월)',
        color: c.chartSeries2,
        values: [for (final r in revenue) byLabel[r.label]],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '최근 12개월 추이 · 분기마다 앞선 네 분기를 더한 값',
          style: t.body(13, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.xs),
        ChartLegend(series: series),
        const SizedBox(height: AppSpace.sm),
        AppColumnChart(
          categories: [for (final r in revenue) r.label],
          series: series,
          formatValue: formatKrwShort,
          height: 180,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '사업보고서는 그 해 연간, 분기·반기는 전년 연간 + 올해 누적 − 전년 같은 기간 누적입니다. '
          '계절을 타는 사업도 한 해치로 더해 놓으면 늘고 줄어드는 방향이 보입니다.',
          style: t.body(11.5, color: c.textMuted),
        ),
      ],
    );
  }
}

/// 연도별 현금흐름: 영업활동으로 번 현금에서 설비에 쓴 돈을 뺀 것이 잉여현금흐름이다.
class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.points});

  final List<CashPoint> points;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '현금흐름 · 잉여현금흐름 = 영업활동 현금흐름 − 유형자산의 취득',
          style: t.body(13, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.xs),
        ChartLegend(series: series),
        const SizedBox(height: AppSpace.sm),
        AppColumnChart(
          categories: [for (final p in points) p.label],
          series: series,
          formatValue: formatKrwShort,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '유형자산 취득: ${[for (final p in points) '${p.label} ${p.capex == null ? '—' : formatKrwShort(p.capex!)}'].join(' · ')}',
          style: t.body(11.5, color: c.textMuted),
        ),
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
                  onPressed: () => context.push(AppRoutes.report(p.reportId)),
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
