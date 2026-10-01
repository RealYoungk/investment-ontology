import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'financial_metrics.dart';

/// Uses only retained filings published BEFORE the quote date. Corrections are
/// not backdated. This is a conservative reconstruction, not a backtest feed.
DerivedValue historicalMultiple(
  CompanyFinancials data,
  CompanyMarketCap market,
  String key,
) {
  final periods = data.periods
      .where(
        (p) =>
            p.receivedDate != null && p.receivedDate!.isBefore(market.baseDate),
      )
      .toList();
  DerivedValue missing(String reason) => DerivedValue(
    value: null,
    formula: '해당 월 시가총액 ÷ 당시 확보 가능한 재무',
    inputs: [],
    missing: reason,
  );
  if (periods.isEmpty) return missing('시세일 이전에 접수된 재무 자료 미확보');
  final view = FinancialView(data.copyWith(periods: periods, market: market));
  final latest = view.latest;
  if (latest == null) return missing('재무 자료 미확보');
  final month = switch (latest.reportCode) {
    FinancialReportCode.annual => 12,
    FinancialReportCode.q1 => 3,
    FinancialReportCode.halfYear => 6,
    FinancialReportCode.q3 => 9,
  };
  // Do not carry an old statement indefinitely through collection gaps.
  final end = DateTime.utc(latest.bsnsYear, month + 1, 0);
  if (end.isAfter(market.baseDate) ||
      market.baseDate.difference(end).inDays > 550) {
    return missing('해당 시점 재무 기간 미확보 또는 18개월 초과');
  }
  final metrics = view.metrics();
  if (key == 'pfcf') {
    final yieldValue = metrics.firstWhere((m) => m.key == 'fcfYield').derived;
    return DerivedValue(
      value: yieldValue.value != null && yieldValue.value! > 0
          ? 1 / yieldValue.value!
          : null,
      formula: 'P/FCF = 시가총액 ÷ 최근 12개월 잉여현금흐름\n잉여현금흐름 = 영업현금흐름 − 유형자산 취득',
      inputs: yieldValue.inputs,
      missing:
          yieldValue.missing ??
          (yieldValue.value == null || yieldValue.value! <= 0
              ? '잉여현금흐름 0 이하 또는 시가총액 미확보'
              : null),
    );
  }
  return metrics.firstWhere((m) => m.key == key).derived;
}

class ValuationHistory extends StatefulWidget {
  const ValuationHistory({super.key, required this.data, this.dataVersion = 0});
  final CompanyFinancials data;
  final int dataVersion;
  @override
  State<ValuationHistory> createState() => _ValuationHistoryState();
}

class _ValuationHistoryState extends State<ValuationHistory> {
  List<CompanyMarketCap>? _history;
  bool _failed = false;
  int _seq = 0;
  int _years = 3;
  String _key = 'per';
  static const labels = {
    'per': 'PER',
    'pbr': 'PBR',
    'psr': 'PSR',
    'por': 'POR',
    'pfcf': 'P/FCF',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ValuationHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.corpCode != widget.data.corpCode ||
        oldWidget.dataVersion != widget.dataVersion) {
      _load();
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _history = null;
      _failed = false;
    });
    try {
      final rows = await client.market.companyCapHistory(
        widget.data.corpCode,
        years: 5,
      );
      if (mounted && seq == _seq) setState(() => _history = rows);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    if (_failed) return AppButton(label: '밸류에이션 추이 다시 불러오기', onPressed: _load);
    if (history == null) return const LinearProgressIndicator(minHeight: 2);
    if (history.isEmpty) {
      return Text(
        '월별 시가총액 이력 미확보',
        style: context.typo.body(13, color: context.colors.textMuted),
      );
    }
    final end = history.last.baseDate;
    final start = DateTime.utc(end.year - _years, end.month, end.day);
    final rows = history.where((h) => !h.baseDate.isBefore(start)).toList();
    final values = [
      for (final r in rows) historicalMultiple(widget.data, r, _key),
    ];
    final available =
        values.where((v) => v.value != null).map((v) => v.value!).toList()
          ..sort();
    final median = available.isEmpty
        ? null
        : available.length.isOdd
        ? available[available.length ~/ 2]
        : (available[available.length ~/ 2 - 1] +
                  available[available.length ~/ 2]) /
              2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('실적에 비해 주가는 어느 수준이었나요?', accent: true),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            AppToggleGroup<String>(
              value: _key,
              options: labels,
              onChanged: (v) => setState(() => _key = v),
            ),
            AppToggleGroup<int>(
              value: _years,
              options: const {1: '1년', 3: '3년', 5: '5년'},
              onChanged: (v) => setState(() => _years = v),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          '${fsDivLabel(widget.data.fsDiv ?? FsDiv.consolidated)} · 월별 마지막 수집 거래일 · ${available.length}/${rows.length}개 월 계산',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.sm),
        if (available.isEmpty)
          Text(
            '해당 기간에 계산 가능한 ${labels[_key]} 자료가 없습니다.',
            style: context.typo.body(13),
          )
        else ...[
          AppLineChart(
            categories: rows.map((r) => formatDate(r.baseDate)).toList(),
            formatCategory: (date) => date.substring(2, 7),
            maxAxisLabels: 6,
            series: ChartSeries(
              label: labels[_key]!,
              color: context.colors.chartSeries1,
              values: values.map((v) => v.value).toList(),
            ),
            formatValue: (v) => '${v.toStringAsFixed(1)}배',
            height: 200,
            includeZeroBaseline: false,
          ),
          Text(
            '관측 범위 ${available.first.toStringAsFixed(1)}~${available.last.toStringAsFixed(1)}배 · 중앙값 ${median!.toStringAsFixed(1)}배',
            style: context.typo.numeric(13),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        ExpansionTile(
          title: const Text('월별 계산 근거'),
          children: [
            Text(
              '접수일이 시세일보다 앞선 보관 공시만 사용합니다. 정정 전 자료·누락 종목·양수 분모를 확보하지 못한 구간은 비웁니다. 수집된 종목 범위 기준이며 과거 공시 전체를 복원한 백테스트 자료는 아닙니다.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),

            for (var i = rows.length - 1; i >= 0; i--)
              ListTile(
                title: Text(
                  '${formatDate(rows[i].baseDate)} · ${formatTimes(values[i].value)}',
                ),
                subtitle: Text(
                  values[i].value == null
                      ? values[i].missing ?? '계산 자료 부족'
                      : '${values[i].formula}\n${values[i].inputs.map((v) => '${v.label}: ${v.amount == null
                            ? '미확보'
                            : v.currency == 'KRW'
                            ? formatKrw(v.amount)
                            : '${v.amount} ${v.currency}'} · ${v.basis}').join('\n')}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}
