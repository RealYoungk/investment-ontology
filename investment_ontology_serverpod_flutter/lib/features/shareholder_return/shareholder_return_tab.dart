import '../research/treasury_movement.dart';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../app/ingest_monitor.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart' show formatKrwLong;

/// 배당 항목 하나의 연도별 값.
class DividendSeries {
  DividendSeries(this.item, this.stockKind, this.unit);

  final String item;
  final String? stockKind;
  final String? unit;

  /// 사업연도 → 값. 그 해 사업보고서의 당기 값이 있으면 그것, 없으면 뒤 보고서의 전기·전전기 값.
  final values = <int, double?>{};

  String get label => stockKind == null ? item : '$item · $stockKind';
}

/// 사업보고서마다 당기·전기·전전기가 있는 배당 행을 연도별로 모은다.
List<DividendSeries> dividendSeries(List<DividendEntry> entries) {
  final byKey = <String, DividendSeries>{};
  final order = [...entries]
    ..sort((a, b) {
      final y = b.bsnsYear.compareTo(a.bsnsYear);
      return y != 0 ? y : a.ord.compareTo(b.ord);
    });
  for (final e in order) {
    byKey.putIfAbsent(
      '${e.item}|${e.stockKind}',
      () => DividendSeries(e.item, e.stockKind, e.unit),
    );
  }
  // 1) 각 해의 사업보고서 당기 값 → 2) 뒤 보고서의 전기 값 → 3) 전전기 값.
  for (final pass in [0, 1, 2]) {
    for (final e in order) {
      final s = byKey['${e.item}|${e.stockKind}']!;
      final year = e.bsnsYear - pass;
      final v = switch (pass) {
        0 => e.current,
        1 => e.prior,
        _ => e.beforePrior,
      };
      if (v != null && !s.values.containsKey(year)) s.values[year] = v;
    }
  }
  return byKey.values.toList();
}

String formatDividendValue(double? v, String? unit) {
  if (v == null) return '—';
  final text = v == v.roundToDouble()
      ? formatCount(v.round())
      : v.toStringAsFixed(2);
  return switch (unit) {
    '%' => '$text%',
    // 큰 금액은 자릿수 세지 않고 읽게 조·억·만원으로 (값은 공시 단위 그대로).
    '원' => v.abs() >= 10000 ? formatKrwLong(v) : '$text원',
    '백만원' => formatKrwLong(v * 1000000),
    _ => text,
  };
}

/// 기업 상세의 주주환원 탭: 배당 추이 · 자기주식 · 주식 총수.
class ShareholderReturnTab extends StatefulWidget {
  const ShareholderReturnTab({super.key, required this.corpCode, this.loader});

  final String corpCode;
  final Future<ShareholderReturn?> Function(String)? loader;

  @override
  State<ShareholderReturnTab> createState() => _ShareholderReturnTabState();
}

class _InterimReturnCard extends StatelessWidget {
  const _InterimReturnCard({required this.data});
  final ShareholderReturn data;
  @override
  Widget build(BuildContext context) {
    final d = data;
    final interim = d.latestReportName?.contains('사업보고서') != true;
    if (!interim) return const SizedBox.shrink();
    String state(String? status) => switch (status) {
      'stored' => '공시 항목 확인',
      'noData' => 'DART API 응답 자료 없음',
      'failed' => '수집 실패 · 재시도 필요',
      _ => '자료 수집 대기',
    };
    final rows = (d.interimDividends ?? [])
        .where(
          (e) =>
              e.item.contains('현금배당금') ||
              e.item.contains('현금배당수익률') ||
              e.item.contains('현금배당성향'),
        )
        .toList();
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompanySectionHeading('최근 중간보고서 · ${d.latestReportName}'),
          const SizedBox(height: AppSpace.sm),
          Text(
            '분기·반기 공시의 현재 기간 값입니다. 연간 확정 배당 추이에 합치거나 연환산하지 않습니다. —는 미확인 값입니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          const SizedBox(height: AppSpace.md),
          AppDataTable(
            columns: const [
              AppColumn('배당 항목'),
              AppColumn('공시 수치', numeric: true),
            ],
            rows: [
              if (rows.isEmpty)
                for (final label in ['주당 현금배당금', '현금배당수익률', '현금배당성향'])
                  AppRow([
                    AppDataTable.text(context, label),
                    AppDataTable.text(context, '—', numeric: true),
                  ]),
              for (final e in rows)
                AppRow([
                  AppDataTable.text(
                    context,
                    e.stockKind == null ? e.item : '${e.item} · ${e.stockKind}',
                  ),
                  AppDataTable.text(
                    context,
                    formatDividendValue(e.current, e.unit),
                    numeric: true,
                  ),
                ]),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '배당: ${state(d.latestDividendStatus)}${d.interimReportName == null ? '' : ' · ${d.interimReportName}'}',
            style: context.typo.body(12),
          ),
          Text(
            '자기주식: ${state(d.latestTreasuryStatus)}',
            style: context.typo.body(12),
          ),
          Text(
            '주식 총수: ${state(d.latestStockTotalStatus)}',
            style: context.typo.body(12),
          ),
        ],
      ),
    );
  }
}

class _ShareholderReturnTabState extends State<ShareholderReturnTab> {
  ShareholderReturn? _data;
  Object? _error;
  int? _year;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShareholderReturnTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.corpCode != oldWidget.corpCode) {
      _year = null;
      _data = null;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = widget.loader != null
          ? await widget.loader!(widget.corpCode)
          : await client.disclosure.shareholderReturn(
              widget.corpCode,
              bsnsYear: _year,
            );
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = _data;
    if (_error != null) {
      return ReadFailureNotice(subject: '주주환원', retry: _load);
    }
    if (d == null) return const ShadProgress(minHeight: 2);

    final series = dividendSeries(d.dividends);
    final end =
        d.annualEndYear ??
        series
            .expand((s) => s.values.keys)
            .fold<int?>(null, (a, b) => a == null || b > a ? b : a);
    final years = end == null
        ? <int>[]
        : [for (var y = end - 4; y <= end; y++) y];
    DividendSeries? find(bool Function(DividendSeries s) test) =>
        series.where(test).firstOrNull;
    bool common(DividendSeries s) =>
        s.stockKind == null || s.stockKind!.contains('보통');
    final dps = find(
      (s) => s.item.contains('주당') && s.item.contains('현금배당금') && common(s),
    );
    final yield = find(
      (s) => s.item.contains('현금배당수익률') && common(s),
    );
    final payout = find((s) => s.item.contains('현금배당성향'));

    bool hasValues(DividendSeries? value) =>
        value != null && value.values.values.any((v) => v != null);
    final emptyDividendMetrics = [
      if (!hasValues(dps)) '주당 현금배당금',
      if (!hasValues(yield)) '배당수익률',
      if (!hasValues(payout)) '배당성향',
    ];
    final treasuryHasValues = d.treasury.any(
      (r) => [
        r.sharesBegin,
        r.acquired,
        r.disposed,
        r.retired,
        r.sharesEnd,
      ].any((v) => v != null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.latestReportName != null) ...[
          _InterimReturnCard(data: d),
          const SizedBox(height: AppSpace.lg),
        ],
        if (widget.loader == null) ...[
          Text('자기주식·주식 수 기준 연도', style: t.body(13)),
          const SizedBox(height: AppSpace.sm),
          ShadSelect<int>(
            key: ValueKey('return-year-${_year ?? d.stockTotalYear}'),
            initialValue: _year ?? d.stockTotalYear,
            selectedOptionBuilder: (_, y) => Text('$y년'),
            options: [
              for (final y in ({
                ...?(d.availableYears),
                for (final e in d.dividends) e.bsnsYear,
                if (d.stockTotalYear != null) d.stockTotalYear!,
              }.toList()..sort()).reversed)
                ShadOption(value: y, child: Text('$y년')),
            ],
            onChanged: (y) {
              if (y == null || y == _year) return;
              setState(() {
                _year = y;
                _data = null;
              });
              _load();
            },
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        if (series.isEmpty)
          Text('배당 자료가 없습니다.', style: t.body(13, color: c.textMuted))
        else ...[
          LayoutBuilder(
            builder: (context, box) {
              final trends = <Widget>[
                if (hasValues(yield))
                  _Trend(
                    title: '배당수익률 · 주가 대비 (공시 기준)',
                    help: '주당 현금배당금 ÷ 주가 × 100입니다. 아래 값과 추이는 공시 당시 기준이며 최신 주가로 계산한 수익률은 아닙니다.',
                    years: years,
                    series: yield!,
                    color: c.chartSeries3,
                  ),
                if (hasValues(dps))
                  _Trend(
                    title: '한 주당 받은 현금배당',
                    years: years,
                    series: dps!,
                    color: c.chartSeries1,
                    bars: true,
                  ),
                if (hasValues(payout))
                  _Trend(
                    title: '배당성향 · 이익 대비',
                    years: years,
                    series: payout!,
                    color: c.chartSeries2,
                  ),
              ];
              final columns = box.maxWidth >= 920
                  ? 3
                  : box.maxWidth >= 680
                  ? 2
                  : 1;
              final width =
                  (box.maxWidth - AppSpace.xl * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpace.xl,
                runSpacing: AppSpace.xl,
                children: [
                  for (final trend in trends)
                    SizedBox(width: width, child: trend),
                ],
              );
            },
          ),
          if (emptyDividendMetrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                '${emptyDividendMetrics.join(' · ')}: 수집한 배당 공시 표에 수치가 표시되지 않았습니다. 미배당 등으로 해당하지 않을 수 있어, 빈 차트 대신 원문에서 확인할 수 있습니다. 공시의 빈 값은 0으로 해석하지 않습니다.',
                style: t.body(13, color: c.textSecondary).copyWith(height: 1.6),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          ShadAccordion<int>(
            maintainState: false,
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: Text(
                  '배당 수치 전체 보기',
                  style: t.body(14, weight: FontWeight.w600),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDataTable(
                      columns: [
                        const AppColumn('항목'),
                        for (final y in years.reversed)
                          AppColumn(
                            series.any((s) => s.values.containsKey(y))
                                ? 'FY$y'
                                : 'FY$y 없음',
                            numeric: true,
                          ),
                      ],
                      rows: [
                        for (final s in series)
                          AppRow([
                            AppDataTable.text(context, s.label),
                            for (final y in years.reversed)
                              AppDataTable.text(
                                context,
                                s.values[y] == null
                                    ? null
                                    : formatDividendValue(s.values[y], s.unit),
                                numeric: true,
                              ),
                          ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: treasuryHasValues ? AppSpace.section : AppSpace.lg),
        if (treasuryHasValues)
          CompanyDataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompanySectionHeading(
                  '자기주식${d.treasuryReportName != null
                      ? ' · ${d.treasuryReportName}'
                      : d.treasuryYear == null
                      ? ''
                      : ' · ${d.treasuryYear}년'}',
                  help: '취득은 회사가 자기 주식을 사들이는 것, 처분은 팔거나 이전하는 것, 소각은 주식을 없애는 것입니다. 처분과 소각은 다릅니다.\n\n이 차트는 해당 기간의 실제 보유량 변화를 보여줍니다.',
                ),
                const SizedBox(height: AppSpace.md),
                TreasuryMovement(rows: d.treasury),
              ],
            ),
          ),
        if (!treasuryHasValues)
          Text(
            d.latestTreasuryStatus == 'noData' &&
                    (_year == null || _year == d.latestYear)
                ? '자기주식 취득·처분: 최신 보고서 DART API 응답에 자료가 없습니다. 공시 원문 부재나 보유량 0을 뜻하지 않습니다.'
                : '${_year == null ? '' : '$_year년 '}자기주식 취득·처분: 표시할 수량 내역이 없습니다. 해당사항 없음 또는 미수집 여부는 아래 공시 원문에서 확인할 수 있습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          ShadAccordion<int>(
            maintainState: false,
            children: [
              ShadAccordionItem<int>(
                value: 0,
                title: Text(
                  '자기주식 취득·처분 상세 보기',
                  style: t.body(14, weight: FontWeight.w600),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDataTable(
                      columns: const [
                        AppColumn('취득방법'),
                        AppColumn(''),
                        AppColumn(''),
                        AppColumn('주식 종류'),
                        AppColumn('기초', numeric: true),
                        AppColumn('취득', numeric: true),
                        AppColumn('처분', numeric: true),
                        AppColumn('소각', numeric: true),
                        AppColumn('기말', numeric: true),
                        AppColumn('비고'),
                      ],
                      rows: [
                        for (final r in d.treasury)
                          AppRow(emphasized: r.isTotal, [
                            AppDataTable.text(context, r.method1),
                            AppDataTable.text(context, r.method2),
                            AppDataTable.text(context, r.method3),
                            AppDataTable.text(context, r.stockKind),
                            for (final v in [
                              r.sharesBegin,
                              r.acquired,
                              r.disposed,
                              r.retired,
                              r.sharesEnd,
                            ])
                              AppDataTable.text(
                                context,
                                v == null ? null : formatCount(v.toInt()),
                                numeric: true,
                              ),
                            AppDataTable.text(context, r.remark),
                          ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: treasuryHasValues ? AppSpace.section : AppSpace.lg),
        CompanyDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanySectionHeading(
                '주식 수 현황${d.stockTotalReportName != null
                    ? ' · ${d.stockTotalReportName}'
                    : d.stockTotalYear == null
                    ? ''
                    : ' · FY${d.stockTotalYear}'}',
              ),
              const SizedBox(height: AppSpace.sm),
              if (d.stockTotals.isEmpty)
                Text('주식 총수 자료가 없습니다.', style: t.body(13, color: c.textMuted))
              else ...[
                _StockComposition(rows: d.stockTotals),
                const SizedBox(height: AppSpace.md),
                ShadAccordion<int>(
                  children: [
                    ShadAccordionItem<int>(
                      value: 0,
                      title: const Text('주식 수량 상세 보기'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpace.sm),
                          AppDataTable(
                            columns: const [
                              AppColumn('구분', flex: true),
                              AppColumn('발행 가능한 총수', numeric: true),
                              AppColumn('발행주식의 총수', numeric: true),
                              AppColumn('자기주식수', numeric: true, flex: true),
                              AppColumn('유통주식수', numeric: true, flex: true),
                            ],
                            rows: [
                              for (final r in d.stockTotals)
                                AppRow(
                                  emphasized:
                                      r.kind.replaceAll(' ', '') == '합계',
                                  [
                                    AppDataTable.text(context, r.kind),
                                    for (final v in [
                                      r.authorized,
                                      r.issued,
                                      r.treasury,
                                      r.outstanding,
                                    ])
                                      AppDataTable.text(
                                        context,
                                        v == null
                                            ? null
                                            : formatCount(v.toInt()),
                                        numeric: true,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          Text(
                            '발행 가능한 총수는 정관상 한도입니다. 추가 발행 예정 물량이나 현재 CB·BW 잔액을 뜻하지 않습니다.',
                            style: t.body(12, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        ShadAccordion<int>(
          maintainState: false,
          children: [
            ShadAccordionItem<int>(
              value: 0,
              title: const Text('출처와 집계 기준'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '배당수익률은 현재 주가가 아닌 공시 기준입니다. 같은 연도는 해당 사업보고서 값을 우선 사용합니다.',
                    style: t.body(12, color: c.textMuted),
                  ),
                  for (final s in d.sources)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.title} · 접수 ${s.reference ?? ''}',
                            style: t.body(11.5, color: c.textMuted),
                          ),
                        ),
                        if (s.url != null)
                          ShadButton.raw(
                            onPressed: () => launchUrl(Uri.parse(s.url!)),
                            variant: ShadButtonVariant.link,
                            child: Flexible(child: Text('DART →')),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({
    required this.title,
    required this.years,
    required this.series,
    required this.color,
    this.bars = false,
    this.help,
  });

  final String title;
  final List<int> years;
  final DividendSeries series;
  final Color color;
  final bool bars;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final latestYear = years.reversed
        .where((y) => series.values[y] != null)
        .firstOrNull;
    final chart = ChartSeries(
      label: series.label,
      color: color,
      values: [for (final y in years) series.values[y]],
    );
    final categories = [
      for (final y in years) series.values.containsKey(y) ? 'FY$y' : 'FY$y 없음',
    ];
    String format(double v) => formatDividendValue(v, series.unit);
    return CompanyDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompanySectionHeading(title, help: help),
          const SizedBox(height: AppSpace.sm),
          if (latestYear != null) ...[
            Text(
              format(series.values[latestYear]!),
              style: t.numeric(28, weight: FontWeight.w600),
            ),
            Text(
              'FY$latestYear · ${series.label}',
              style: t.body(12, color: context.colors.textSecondary),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          bars
              ? AppColumnChart(
                  height: 210,
                  categories: categories,
                  series: [chart],
                  formatValue: format,
                )
              : AppLineChart(
                  height: 210,
                  categories: categories,
                  series: chart,
                  formatValue: format,
                ),
        ],
      ),
    );
  }
}

/// 발행주식 중 자기주식의 비중. 합계를 다시 합산하지 않고 주식 종류별로 그린다.
class _StockComposition extends StatelessWidget {
  const _StockComposition({required this.rows});
  final List<StockTotalRow> rows;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final valid = rows.where(
      (r) =>
          r.kind.replaceAll(' ', '') != '합계' &&
          r.issued != null &&
          r.issued! > BigInt.zero &&
          r.treasury != null &&
          r.treasury! >= BigInt.zero &&
          r.treasury! <= r.issued!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in valid)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${row.kind} · 자기주식 ${(row.treasury!.toDouble() / row.issued!.toDouble() * 100).toStringAsFixed(2)}%',
                  style: t.body(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.md),
                Semantics(
                  label: '${row.kind} 발행주식 중 자기주식 비중',
                  child: ShadProgress(
                    value: row.treasury!.toDouble() / row.issued!.toDouble(),
                    minHeight: 18,
                    color: c.chartSeries2,
                    backgroundColor: c.chartTile,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '발행 ${formatCount(row.issued!.toInt())}주 중 자기주식 ${formatCount(row.treasury!.toInt())}주',
                  style: t.body(12, color: c.textSecondary),
                ),
              ],
            ),
          ),
        for (final row in rows.where(
          (r) =>
              r.kind.replaceAll(' ', '') != '합계' &&
              r.issued != null &&
              r.treasury == null,
        )) ...[
          Text(
            '${row.kind} · 발행 ${formatCount(row.issued!.toInt())}주',
            style: t.numeric(18),
          ),
          if (row.outstanding != null)
            Text(
              '유통 ${formatCount(row.outstanding!.toInt())}주',
              style: t.body(13, color: c.textSecondary),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          valid.isEmpty
              ? '자기주식 수는 미확인입니다. 공시의 빈값을 0으로 바꾸거나 발행·유통주식 차이로 보유량을 추정하지 않습니다.'
              : '자기주식 보유는 소각과 다릅니다. 취득·처분·소각 수량은 상세 자료에서 구분해 확인하세요.',
          style: t.body(12, color: c.textSecondary),
        ),
      ],
    );
  }
}
