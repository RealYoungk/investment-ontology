import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../app/ingest_monitor.dart';
import '../../design/components/components.dart';
import '../../design/components/charts/app_sparkline.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../macro/macro_metrics.dart';
import '../macro/macro_page.dart';
import '../watchlist/watchlist_store.dart';
import 'market_pulse.dart';
import 'daily_brief.dart';

/// Live home: public market data and account-scoped watchlist; no synthetic data.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.search,
    this.market,
    this.filings,
    this.macro,
  });
  final Widget search;
  final MarketPulseLoad? market;
  final FilingFeedLoad? filings;
  final Future<List<MacroSeriesView>> Function()? macro;
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<IndexHistory> indices = [];
  List<MacroSeriesView> macros = [];
  List<FilingFeedItem> reports = [];
  bool loading = true, corrections = false;
  int period = 30, epoch = 0;
  final store = WatchlistStore.instance;
  final quotes = <String, PriceHistory?>{};
  WatchlistView? quotedView;
  String? quoteOwner;
  int quoteEpoch = 0;
  void refreshQuotes() {
    if (quotedView == store.view && quoteOwner == store.owner) return;
    final ownerChanged = quoteOwner != store.owner;
    quotedView = store.view;
    quoteOwner = store.owner;
    final request = ++quoteEpoch;
    if (ownerChanged) {
      quotes.clear();
    } else {
      final codes = (store.view?.companies ?? <WatchlistCompanyView>[])
          .map((c) => c.corpCode)
          .toSet();
      quotes.removeWhere((code, _) => !codes.contains(code));
    }
    if (mounted) setState(() {});
    if (store.owner == null) return;
    for (final company
        in (store.view?.companies ?? <WatchlistCompanyView>[]).take(5)) {
      unawaited(() async {
        try {
          final next = await client.market.priceHistory(
            company.corpCode,
            days: 14,
          );
          if (mounted && request == quoteEpoch) {
            setState(() => quotes[company.corpCode] = next);
          }
        } catch (_) {}
      }());
    }
  }

  Widget quote(String code) {
    final points = quotes[code]?.points ?? <PricePoint>[];
    final last = points.lastOrNull;
    final previous = points.length > 1 ? points[points.length - 2] : null;
    final delta =
        last != null &&
            previous != null &&
            previous.close > 0 &&
            last.date.difference(previous.date).inDays <= 7
        ? (last.close / previous.close - 1) * 100
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          last == null ? '—' : formatDecimal(last.close.toDouble()),
          style: context.typo.numeric(14),
        ),
        Text(
          delta == null
              ? '—'
              : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}%',
          style: context.typo.numeric(
            12,
            color: context.colors.marketChange(delta),
          ),
        ),
        note(last == null ? '자료 준비 중' : formatDate(last.date)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(load);
    unawaited(load());
    store.addListener(refreshQuotes);
    refreshQuotes();
    unawaited(store.refresh());
  }

  @override
  void dispose() {
    epoch++;
    quoteEpoch++;
    store.removeListener(refreshQuotes);
    IngestMonitor.instance.dataVersion.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    final request = ++epoch;
    if (mounted) setState(() => loading = true);
    // Independent reads preserve the last good value of each section.
    await Future.wait([
      () async {
        try {
          final next =
              await (widget.market?.call() ??
                  Future.wait([
                    for (final name in ['코스피', '코스닥'])
                      client.market.indexHistory(name, days: 365),
                  ]).then((v) => v.whereType<IndexHistory>().toList()));
          if (mounted && request == epoch) setState(() => indices = next);
        } catch (_) {}
      }(),
      () async {
        try {
          final next = await (widget.macro?.call() ?? client.macro.overview());
          if (mounted && request == epoch) setState(() => macros = next);
        } catch (_) {}
      }(),
      () async {
        try {
          final next =
              await (widget.filings?.call() ??
                  client.disclosure.recentFilings(limit: 12));
          if (mounted && request == epoch) setState(() => reports = next);
        } catch (_) {}
      }(),
    ]);
    if (mounted && request == epoch) setState(() => loading = false);
  }

  Widget note(String text) =>
      Text(text, style: context.typo.body(12, color: context.colors.textMuted));
  Widget action(String text, IconData icon, VoidCallback onTap) =>
      ShadButton.ghost(
        size: ShadButtonSize.sm,
        height: 32,
        leading: Icon(icon, size: 16),
        onPressed: onTap,
        child: Text(text),
      );
  Widget panelHeader(String text, List<Widget> actions, {Widget? subtitle}) =>
      LayoutBuilder(
        builder: (_, box) {
          final controls = Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          );
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: context.typo.display(20)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.sm),
                subtitle,
              ],
            ],
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: box.maxWidth >= 440
                ? Row(
                    children: [
                      Expanded(child: heading),
                      controls,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      const SizedBox(height: AppSpace.sm),
                      Align(alignment: Alignment.centerRight, child: controls),
                    ],
                  ),
          );
        },
      );
  Widget pair(Widget a, Widget b) => LayoutBuilder(
    builder: (_, box) => box.maxWidth >= 980
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpace.lg),
              Expanded(child: b),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              a,
              const SizedBox(height: AppSpace.lg),
              b,
            ],
          ),
  );
  List<IndexPoint> window(List<IndexPoint> points, int days) {
    if (points.isEmpty) return [];
    final since = points.last.date.subtract(Duration(days: days));
    return points.where((p) => !p.date.isBefore(since)).toList();
  }

  Widget metric(
    String name,
    List<IndexPoint> points,
    String unit,
    double? delta,
    String deltaUnit,
    VoidCallback onTap,
  ) {
    final recent = window(points, 30);
    final last = points.lastOrNull;
    final direction = recent.length < 2
        ? null
        : recent.last.value - recent.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.link(
            size: ShadButtonSize.sm,
            padding: EdgeInsets.zero,
            onPressed: onTap,
            child: Flexible(
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        Text(
          last == null
              ? '—'
              : '${MacroMetrics.value(last.value)}${unit == '%' ? '%' : ''}',
          style: context.typo.numeric(22),
        ),
        Text(
          delta == null
              ? '—'
              : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}$deltaUnit',
          style: context.typo.numeric(
            12,
            color: context.colors.marketChange(delta),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        AppSparkline(
          values: recent.map((p) => p.value).toList(),
          fill: true,
          color: context.colors.marketChange(direction),
          description:
              '$name 최근 1개월. ${last == null ? '자료 준비 중' : '${formatDate(last.date)} 기준, ${last.value} $unit'}. 항목별 독립 눈금.',
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          last == null ? '자료 준비 중' : '${formatDate(last.date)} · $unit',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
      ],
    );
  }

  Widget strip() => LayoutBuilder(
    builder: (_, box) {
      final cells = <Widget>[];
      for (final name in ['코스피', '코스닥']) {
        final h = indices.where((h) => h.name == name).firstOrNull;
        cells.add(
          metric(
            name,
            h?.points ?? [],
            '지수',
            h?.lastChangeRate,
            '%',
            () => context.go('/market'),
          ),
        );
      }
      for (final id in ['DEXKOUS', 'DGS2', 'DGS10', 'DCOILBRENTEU']) {
        final s = macros
            .where(
              (s) =>
                  s.seriesId == id ||
                  (id == 'DEXKOUS' && s.seriesId == 'EXIM_USDKRW'),
            )
            .firstOrNull;
        final name = switch (id) {
          'DEXKOUS' => '원/달러',
          'DGS2' => '미국 국채 2년',
          'DGS10' => '미국 국채 10년',
          _ => '브렌트 원유',
        };
        cells.add(
          metric(
            name,
            s?.points ?? [],
            s?.unit ??
                (id.startsWith('DGS')
                    ? '%'
                    : id == 'DEXKOUS'
                    ? '원/달러'
                    : '달러/배럴'),
            s == null
                ? null
                : MacroMetrics.change(s, MacroMetrics.base(s.points, 0)),
            s?.rate == true ? '%p' : '%',
            () => context.push(
              macroLocation(series: s?.seriesId ?? id, days: 30),
            ),
          ),
        );
      }
      final count = box.maxWidth >= 1200
          ? 6
          : box.maxWidth >= 600
          ? 3
          : box.maxWidth >= 340
          ? 2
          : 1;
      return Wrap(
        spacing: AppSpace.lg,
        runSpacing: AppSpace.lg,
        children: [
          for (final cell in cells)
            SizedBox(
              width: (box.maxWidth - AppSpace.lg * (count - 1)) / count,
              child: cell,
            ),
        ],
      );
    },
  );
  Widget marketPanel() {
    final histories = indices.where((h) => h.points.length > 1).toList();
    final dates =
        histories
            .expand((h) => window(h.points, period).map((p) => p.date))
            .toSet()
            .toList()
          ..sort();
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          panelHeader(
            '시장 흐름',
            [
              IntrinsicWidth(
                child: ShadToggleGroup<int>(
                  values: {period},
                  allowDeselection: false,
                  onChanged: (values) => setState(() => period = values.single),
                  children: [
                    for (final days in [30, 90, 365])
                      ShadToggleGroupItem(
                        value: days,
                        child: Text(
                          days == 30
                              ? '1개월'
                              : days == 90
                              ? '3개월'
                              : '1년',
                        ),
                      ),
                  ],
                ),
              ),
              action(
                '시장 상세',
                LucideIcons.arrowUpRight,
                () => context.go('/market'),
              ),
            ],
          ),
          if (dates.isEmpty)
            SizedBox(height: 220, child: Center(child: note('지수 자료 준비 중')))
          else
            AppLineChart.many(
              height: 220,
              includeZeroBaseline: false,
              categories: dates.map(formatDate).toList(),
              formatCategory: (label) {
                final index = dates.indexWhere(
                  (date) => formatDate(date) == label,
                );
                final step = (dates.length / 5).ceil();
                if (index != dates.length - 1 && index % step != 0) return '';
                final parts = label.split('.');
                return parts.length == 3
                    ? period == 365
                          ? '${parts[0].substring(2)}.${parts[1]}'
                          : '${int.parse(parts[1])}/${int.parse(parts[2])}'
                    : label;
              },
              formatValue: (v) => '${v > 0 ? "+" : ""}${v.toStringAsFixed(1)}%',
              series: [
                for (final h in histories)
                  ChartSeries(
                    label: h.name,
                    color: h.name == '코스피'
                        ? context.colors.chartSeries1
                        : context.colors.chartSeries2,
                    values: (() {
                      final selected = window(h.points, period);
                      final base = selected.firstOrNull?.value;
                      return dates.map((date) {
                        final value = selected
                            .where((p) => p.date == date)
                            .firstOrNull
                            ?.value;
                        return value == null || base == null || base <= 0
                            ? null
                            : (value / base - 1) * 100;
                      }).toList();
                    })(),
                  ),
              ],
            ),
          const SizedBox(height: AppSpace.md),
          Center(
            child: ChartLegend(
              series: [
                for (final h in histories)
                  ChartSeries(
                    label: h.name,
                    color: h.name == '코스피'
                        ? context.colors.chartSeries1
                        : context.colors.chartSeries2,
                    values: const [],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget watchPanel() => DataPanel(
    child: ListenableBuilder(
      listenable: store,
      builder: (_, _) {
        final companies = store.view?.companies ?? <WatchlistCompanyView>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            panelHeader('내 관심기업', [
              if (store.owner != null)
                action(
                  '관심 설정',
                  LucideIcons.slidersHorizontal,
                  () => context.go('/watchlist'),
                ),
            ]),
            if (store.owner == null ||
                (!store.loading &&
                    store.error == null &&
                    companies.isEmpty)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.star,
                      size: 32,
                      color: context.colors.accent,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      store.owner == null
                          ? '내가 지켜보는 기업을 한곳에'
                          : '첫 관심기업을 추가해 보세요',
                      textAlign: TextAlign.center,
                      style: context.typo.body(16, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    note(
                      store.owner == null
                          ? '로그인하면 관심기업과 새 공시를 볼 수 있습니다.'
                          : '관심기업을 담으면 새 공시를 한곳에서 볼 수 있습니다.',
                    ),
                    const SizedBox(height: AppSpace.lg),
                    ShadButton(
                      onPressed: () => context.go('/watchlist'),
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                      ),
                      trailing: const Icon(LucideIcons.arrowRight, size: 18),
                      child: Text(
                        store.owner == null ? '관심기업 시작하기' : '관심기업 추가하기',
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (store.loading && store.view == null)
              note('관심기업 불러오는 중…')
            else if (store.error != null) ...[
              note('관심기업을 확인할 수 없습니다.'),
              ShadButton.link(
                onPressed: store.refresh,
                child: const Text('다시 확인'),
              ),
            ] else if (companies.isEmpty)
              note('관심기업 불러오는 중…')
            else
              for (final company in companies.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: ShadButton.ghost(
                    onPressed: () =>
                        context.push('/company/${company.corpCode}'),
                    child: Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                note(company.stockCode ?? '종목코드 미확인'),
                              ],
                            ),
                          ),
                          quote(company.corpCode),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            company.unreadCount == 0
                                ? '새 소식 없음'
                                : '새 소식 ${company.unreadCount}',
                            style: context.typo.body(
                              12,
                              color: context.colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );
  Widget reportPanel() => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panelHeader('최근 정기공시', [
          for (final value in [false, true])
            IntrinsicWidth(
              child: ShadToggle.outline(
                height: 32,
                value: corrections == value,
                onChanged: (_) => setState(() => corrections = value),
                child: Text(value ? '정정' : '전체'),
              ),
            ),
        ]),
        if (reports.isEmpty) note(loading ? '공시 불러오는 중…' : '최근 공시 자료 준비 중'),
        for (final report
            in reports
                .where((r) => !corrections || r.reportName.contains('정정'))
                .take(4))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: note(formatDate(report.receivedDate))),
                    if (report.reportName.contains('정정'))
                      ShadBadge.outline(child: const Text('정정')),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.link(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.push(
                      '/company/${report.company.corpCode}?tab=financials',
                    ),
                    child: Flexible(
                      child: Text(
                        '${report.company.name} · ${report.reportName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (corrections &&
            reports.isNotEmpty &&
            !reports.any((r) => r.reportName.contains('정정')))
          note('조회한 최근 공시 중 정정 보고서가 없습니다.'),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => PageFrame(
    children: [
      Text('한눈에 보기', style: context.typo.display(27)),
      const SizedBox(height: AppSpace.lg),
      strip(),
      const SizedBox(height: AppSpace.xl),
      pair(marketPanel(), watchPanel()),
      const SizedBox(height: AppSpace.lg),
      reportPanel(),
      const SizedBox(height: AppSpace.lg),
      DataPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.search,
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final entry in [
                  ('관심종목 · 탑픽', '/insights'),
                  ('자동차', '/companies?section=C&division=30'),
                  ('매출이 늘어난 기업', '/screen?rgrow=10'),
                  ('이익을 남기는 기업', '/screen?margin=10'),
                  ('배당을 주는 기업', '/screen?div=3'),
                ])
                  ShadButton.outline(
                    height: 36,
                    size: ShadButtonSize.sm,
                    trailing: const Icon(LucideIcons.arrowRight, size: 14),
                    onPressed: () => context.go(entry.$2),
                    child: Text(entry.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
