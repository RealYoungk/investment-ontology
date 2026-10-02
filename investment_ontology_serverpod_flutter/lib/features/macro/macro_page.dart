import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'macro_basics.dart';
import 'macro_guide.dart';
import 'macro_metrics.dart';

String macroLocation({
  String series = 'DCOILBRENTEU',
  int days = 365,
  String? company,
}) => Uri(
  path: '/market/indicators',
  queryParameters: {'series': series, 'days': '$days', 'company': ?company},
).toString();

class MacroPage extends StatefulWidget {
  const MacroPage({super.key, required this.query, this.load});
  final Map<String, String> query;
  final Future<List<MacroSeriesView>> Function()? load;
  @override
  State<MacroPage> createState() => _MacroPageState();
}

class _MacroPageState extends State<MacroPage> {
  List<MacroSeriesView>? _data;
  bool _loading = true, _failed = false;
  int _seq = 0;
  String get _selected => widget.query['series'] == 'DEXKOUS'
      ? 'EXIM_USDKRW'
      : widget.query['series'] ?? 'DCOILBRENTEU';
  int get _days {
    final requested = int.tryParse(widget.query['days'] ?? '');
    return const [30, 90, 365, 1095].contains(requested) ? requested! : 365;
  }

  String? get _company {
    final code = widget.query['company'];
    return code != null && RegExp(r'^\d{8}$').hasMatch(code) ? code : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await (widget.load?.call() ?? client.macro.overview());
      if (mounted && seq == _seq) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _pick(String series, int days) =>
      context.go(macroLocation(series: series, days: days, company: _company));

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final data = _data;
    final selected =
        data?.where((s) => s.seriesId == _selected).firstOrNull ??
        data?.firstOrNull;
    return PageFrame(
      allowLeading: false,
      children: [
        AppButton(
          label: '시장으로',
          variant: AppButtonVariant.link,
          onPressed: () => context.go('/market'),
        ),
        const SizedBox(height: AppSpace.md),
        const PageHeading(
          title: '시장 지표',
          subtitle: '가격의 변화에서 기업의 원가·수요·금융환경까지 살펴보세요.',
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '공식 일별 자료 · 실시간 시세 아님 · 지표별 기준일 상이',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.xl),
        if (_loading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpace.sm),
          Text('공식 지표 불러오는 중…', style: t.body(13, color: c.textSecondary)),
        ],
        if (_failed) ReadFailureNotice(subject: '시장 지표', retry: _load),
        if (!_loading && !_failed && (data == null || data.isEmpty))
          const AppNotice(message: '표시할 지표 자료가 없습니다.'),
        if (data != null && selected != null)
          LayoutBuilder(
            builder: (context, box) {
              final list = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in ['원자재', '환율', '금리']) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.sm,
                      ),
                      child: Text(
                        group,
                        style: t.label(color: c.textSecondary),
                      ),
                    ),
                    for (final s in data.where((s) => s.group == group))
                      _SeriesRow(
                        series: s,
                        active: s.seriesId == selected.seriesId,
                        onTap: () => _pick(s.seriesId, _days),
                      ),
                  ],
                ],
              );
              final detail = MacroDetail(
                series: selected,
                days: _days,
                company: _company,
                onDays: (days) => _pick(selected.seriesId, days),
              );
              if (box.maxWidth < 850) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSelect<String>(
                      label: '지표',
                      options: {
                        for (final s in data)
                          s.seriesId: MacroBasics.name(s.seriesId, s.name),
                      },
                      value: selected.seriesId,
                      allowClear: false,
                      placeholder: '지표 선택',
                      onChanged: (id) {
                        if (id != null) _pick(id, _days);
                      },
                    ),
                    const SizedBox(height: AppSpace.xl),
                    detail,
                    const SizedBox(height: AppSpace.xl),
                    ExpansionTile(
                      title: Text('전체 지표 비교', style: t.body(14)),
                      children: [list],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: list),
                  const SizedBox(width: AppSpace.xxl),
                  Expanded(child: detail),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({
    required this.series,
    required this.active,
    required this.onTap,
  });
  final MacroSeriesView series;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final last = series.points.lastOrNull;
    final change = MacroMetrics.change(
      series,
      MacroMetrics.base(series.points, 0),
    );
    return Semantics(
      selected: active,
      child: HoverBuilder(
        onTap: onTap,
        builder: (context, hovered) => Container(
          padding: const EdgeInsets.all(AppSpace.md),
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          decoration: BoxDecoration(
            color: active
                ? c.accentSubtle
                : hovered
                ? c.surfaceHover
                : c.surface,
            borderRadius: context.shape.borderRadius,
            border: Border.all(color: active ? c.accent : c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      MacroBasics.name(series.seriesId, series.name),
                      style: t.body(13, weight: FontWeight.w600),
                    ),
                  ),
                  if (active)
                    Icon(Icons.check_circle_outline, size: 16, color: c.accent),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      last == null ? '자료 미확보' : MacroMetrics.value(last.value),
                      style: t.numeric(21, weight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    MacroMetrics.delta(series, change),
                    style: t.numeric(12, color: c.marketChange(change)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${series.unit} · ${last == null ? '기준일 없음' : formatDate(last.date)}${series.status == 'stale' ? ' · 이전 자료' : ''}',
                style: t.body(11, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MacroDetail extends StatelessWidget {
  const MacroDetail({
    super.key,
    required this.series,
    required this.days,
    required this.onDays,
    this.company,
  });
  final MacroSeriesView series;
  final int days;
  final ValueChanged<int> onDays;
  final String? company;
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final guide = MacroGuide.forSeries(series.seriesId);
    final basics = MacroBasics.forSeries(series.seriesId);
    final last = series.points.lastOrNull;
    final from = last?.date.subtract(Duration(days: days));
    final points = [
      for (final p in series.points)
        if (from != null && !p.date.isBefore(from)) p,
    ];
    final change = MacroMetrics.change(
      series,
      MacroMetrics.base(series.points, days),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MacroBasics.name(series.seriesId, series.name),
          style: t.display(24),
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              last == null ? '자료 미확보' : MacroMetrics.value(last.value),
              style: t.numeric(34, weight: FontWeight.w600),
            ),
            Text(series.unit, style: t.body(13, color: c.textSecondary)),
            Text(
              '선택 기간 ${MacroMetrics.delta(series, change)}',
              style: t.numeric(13, color: c.marketChange(change)),
            ),
          ],
        ),
        if (last != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            '관측 기준 ${formatDate(last.date)}',
            style: t.body(12, color: c.textMuted),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        _Explanation(title: '어떤 지표인가요?', body: basics.definition),
        _Explanation(title: '숫자는 이렇게 읽어요', body: basics.reading),
        if (series.rate) ...[
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: context.shape.borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '금리와 채권 가격은 반대로 움직여요',
                  style: t.body(15, weight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '금리 상승 → 기존 고정금리 채권 가격 하락\n금리 하락 → 기존 고정금리 채권 가격 상승',
                  style: t.body(14, color: c.accent),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '다른 조건이 같을 때의 관계입니다. 새 채권의 금리가 높아지면, 이자를 덜 주는 기존 채권은 가격이 낮아져야 매력적이 됩니다. 기존 채권의 약정 이자가 자동으로 바뀌는 것은 아닙니다.',
                  style: t.body(13, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '예시: 4.00% → 4.50%는 +0.50%p입니다. 금리가 올랐다는 표시를 채권 가격이 올랐다는 뜻으로 읽으면 안 됩니다.',
                  style: t.body(13, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        AppToggleGroup<int>(
          options: const {30: '1개월', 90: '3개월', 365: '1년', 1095: '3년'},
          value: days,
          onChanged: onDays,
        ),
        const SizedBox(height: AppSpace.lg),
        if (series.message != null) ...[
          AppNotice(message: series.message!),
          const SizedBox(height: AppSpace.md),
        ],
        if (points.length >= 2)
          AppLineChart(
            categories: [for (final p in points) formatDate(p.date)],
            series: ChartSeries(
              label: MacroBasics.name(series.seriesId, series.name),
              color: c.chartSeries1,
              values: [for (final p in points) p.value],
            ),
            formatCategory: (date) => date.substring(2),
            formatValue: MacroMetrics.value,
            height: 240,
            includeZeroBaseline: false,
            maxAxisLabels: 5,
          )
        else
          Text(
            '선택 기간의 차트 자료가 부족합니다.',
            style: t.body(13, color: c.textSecondary),
          ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.xl,
          runSpacing: AppSpace.sm,
          children: [
            for (final item in [
              (label: '직전 관측', days: 0),
              (label: '1개월', days: 30),
              (label: '1년', days: 365),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: t.body(12, color: c.textSecondary)),
                  Text(
                    MacroMetrics.delta(
                      series,
                      MacroMetrics.change(
                        series,
                        MacroMetrics.base(series.points, item.days),
                      ),
                    ),
                    style: t.numeric(14, weight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Text(guide.question, style: t.body(18, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: c.accentSubtle,
            borderRadius: context.shape.borderRadius,
          ),
          child: Text(
            guide.path,
            style: t.body(14, color: c.accent, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        _Explanation(title: '올라갈 때', body: guide.up),
        _Explanation(title: '내려갈 때', body: guide.down),
        const SizedBox(height: AppSpace.md),
        Text('기업에서 확인할 것', style: t.body(15, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.sm),
        for (final (i, check) in guide.checks.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Text(
              '${i + 1}. $check',
              style: t.body(13, color: c.textSecondary),
            ),
          ),
        const SizedBox(height: AppSpace.md),
        Text(
          '일반적인 전달 경로입니다. 개별 기업의 실제 노출과 영향 크기는 공시에서 확인하세요.',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            if (company != null) ...[
              AppButton(
                label: '이 기업의 사업 확인',
                onPressed: () => context.push('/company/$company?tab=overview'),
              ),
              AppButton(
                label: '이 기업의 재무 확인',
                onPressed: () =>
                    context.push('/company/$company?tab=financials'),
              ),
            ] else
              AppButton(
                label: '기업 찾아 적용하기',
                icon: Icons.arrow_forward,
                onPressed: () => context.go('/companies'),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('기준·계산·출처', style: t.body(13, color: c.textSecondary)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.note, style: t.body(12, color: c.textSecondary)),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '관측일 ${last == null ? '없음' : formatDate(last.date)} · ${series.source?.title ?? '출처 자료 미확보'}',
                    style: t.body(12, color: c.textSecondary),
                  ),
                  if (series.source != null)
                    Text(
                      '수신 ${series.source!.retrievedAt.toLocal()} · 서버 캐시 1시간',
                      style: t.body(11, color: c.textMuted),
                    ),
                  Text(
                    series.rate
                        ? '변화 = 최신 금리 − 비교 금리 (%p)'
                        : '변화 = (최신 값 ÷ 비교 값 − 1) × 100 (%)',
                    style: t.body(12, color: c.textSecondary),
                  ),
                  Text(
                    '기간 비교는 최신 관측일에서 해당 일수를 뺀 날짜 이전의 가장 가까운 관측값(7일 이내)을 사용합니다. 차트는 관측된 날짜만 연결합니다.',
                    style: t.body(12, color: c.textSecondary),
                  ),
                  for (final d in {days, 0, 30, 365})
                    Text(
                      '${d == 0 ? '직전 관측' : '$d일 비교'} 기준: ${MacroMetrics.base(series.points, d) == null ? '자료 부족' : '${formatDate(MacroMetrics.base(series.points, d)!.date)} · ${MacroMetrics.value(MacroMetrics.base(series.points, d)!.value)}'}',
                      style: t.body(11, color: c.textMuted),
                    ),
                  if (series.source?.url != null)
                    AppButton(
                      label: '공식 원자료 열기 ↗',
                      variant: AppButtonVariant.link,
                      onPressed: () =>
                          launchUrl(Uri.parse(series.source!.url!)),
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

class _Explanation extends StatelessWidget {
  const _Explanation({required this.title, required this.body});
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.typo.body(13, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.xs),
        Text(
          body,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
      ],
    ),
  );
}
