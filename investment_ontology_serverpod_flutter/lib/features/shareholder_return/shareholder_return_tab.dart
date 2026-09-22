import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
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
  const ShareholderReturnTab({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<ShareholderReturnTab> createState() => _ShareholderReturnTabState();
}

class _ShareholderReturnTabState extends State<ShareholderReturnTab> {
  ShareholderReturn? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    client.disclosure
        .shareholderReturn(widget.corpCode)
        .then((d) {
          if (mounted) setState(() => _data = d);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = _data;
    if (_error != null) {
      return AppNotice(message: '주주환원을 불러오지 못했습니다 — $_error');
    }
    if (d == null) return const LinearProgressIndicator(minHeight: 2);

    final series = dividendSeries(d.dividends);
    // 지금 해의 사업보고서가 아직 없으면 그 해를 빈 칸으로 둔다 (지우지 않는다).
    final thisYear = DateTime.now().year;
    final years = {
      for (final s in series) ...s.values.keys,
      if (series.any((s) => s.values.isNotEmpty)) thisYear,
    }.toList()..sort();
    DividendSeries? find(bool Function(DividendSeries s) test) =>
        series.where(test).firstOrNull;
    bool common(DividendSeries s) =>
        s.stockKind == null || s.stockKind!.contains('보통');
    final dps = find(
      (s) => s.item.contains('주당') && s.item.contains('현금배당금') && common(s),
    );
    final payout = find((s) => s.item.contains('현금배당성향'));
    final yieldRate = find(
      (s) => s.item.contains('현금배당수익률') && common(s),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('배당 · 배당에 관한 사항'),
        const SizedBox(height: AppSpace.xs),
        Text(
          '사업보고서마다 당기·전기·전전기 값이 있어 연도별로 모았습니다. 그 해의 사업보고서 값을 먼저 쓰고, '
          '없으면 뒤 보고서의 전기 값을 씁니다. 배당수익률은 현재 주가 기준이 아닌 공시 값입니다.',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.md),
        if (series.isEmpty)
          Text('배당 자료가 없습니다.', style: t.body(13, color: c.textMuted))
        else ...[
          LayoutBuilder(
            builder: (context, box) {
              final trends = <Widget>[
                if (dps != null)
                  _Trend(
                    title: '한 주당 받은 현금배당',
                    years: years,
                    series: dps,
                    color: c.chartSeries1,
                    bars: true,
                  ),
                if (payout != null)
                  _Trend(
                    title: '이익 중 배당한 비율',
                    years: years,
                    series: payout,
                    color: c.chartSeries2,
                  ),
                if (yieldRate != null)
                  _Trend(
                    title: '공시 기준 배당수익률',
                    years: years,
                    series: yieldRate,
                    color: c.chartSeries1,
                  ),
              ];
              final columns = box.maxWidth >= 1050
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
          const SizedBox(height: AppSpace.lg),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '배당 수치 전체 보기',
              style: t.body(14, weight: FontWeight.w600),
            ),
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
        ],
        const SizedBox(height: AppSpace.section),
        SectionLabel(
          '자기주식 · 취득 및 처분 현황${d.treasuryYear == null ? '' : ' · FY${d.treasuryYear}'}',
        ),
        const SizedBox(height: AppSpace.sm),
        if (d.treasury.isEmpty)
          Text('자기주식 자료가 없습니다.', style: t.body(13, color: c.textMuted))
        else
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '자기주식 취득·처분 상세 보기',
              style: t.body(14, weight: FontWeight.w600),
            ),
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
        const SizedBox(height: AppSpace.section),
        SectionLabel(
          '주식의 총수${d.stockTotalYear == null ? '' : ' · FY${d.stockTotalYear}'}',
        ),
        const SizedBox(height: AppSpace.sm),
        if (d.stockTotals.isEmpty)
          Text('주식 총수 자료가 없습니다.', style: t.body(13, color: c.textMuted))
        else ...[
          _StockComposition(rows: d.stockTotals),
          const SizedBox(height: AppSpace.md),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '주식 수량 상세 보기',
              style: t.body(14, weight: FontWeight.w600),
            ),
            children: [
              AppDataTable(
                columns: const [
                  AppColumn('구분', flex: true),
                  AppColumn('발행주식의 총수', numeric: true, flex: true),
                  AppColumn('자기주식수', numeric: true, flex: true),
                  AppColumn('유통주식수', numeric: true, flex: true),
                ],
                rows: [
                  for (final r in d.stockTotals)
                    AppRow(emphasized: r.kind.replaceAll(' ', '') == '합계', [
                      AppDataTable.text(context, r.kind),
                      for (final v in [r.issued, r.treasury, r.outstanding])
                        AppDataTable.text(
                          context,
                          v == null ? null : formatCount(v.toInt()),
                          numeric: true,
                        ),
                    ]),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
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
                AppButton(
                  label: 'DART →',
                  variant: AppButtonVariant.link,
                  onPressed: () => launchUrl(Uri.parse(s.url!)),
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
  });

  final String title;
  final List<int> years;
  final DividendSeries series;
  final Color color;
  final bool bars;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: t.body(13, weight: FontWeight.w600)),
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
                categories: categories,
                series: [chart],
                formatValue: format,
              )
            : AppLineChart(
                categories: categories,
                series: chart,
                formatValue: format,
              ),
      ],
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
                  child: LinearProgressIndicator(
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
        Text(
          '자기주식 보유는 소각과 다릅니다. 취득·처분·소각 수량은 상세 자료에서 구분해 확인하세요.',
          style: t.body(12, color: c.textSecondary),
        ),
      ],
    );
  }
}
