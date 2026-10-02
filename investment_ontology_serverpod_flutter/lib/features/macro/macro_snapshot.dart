import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'macro_basics.dart';
import 'macro_metrics.dart';
import 'macro_page.dart';

/// Small entry point on the market page. One independent request, no polling.
class MacroSnapshot extends StatefulWidget {
  const MacroSnapshot({super.key});
  @override
  State<MacroSnapshot> createState() => _MacroSnapshotState();
}

class _MacroSnapshotState extends State<MacroSnapshot> {
  List<MacroSeriesView>? _data;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final data = await client.macro.overview();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.md,
          children: [
            Text('기업을 둘러싼 시장 지표', style: t.body(19, weight: FontWeight.w600)),
            AppButton(
              label: '전체 지표와 해석 →',
              variant: AppButtonVariant.link,
              onPressed: () => context.go(macroLocation()),
            ),
          ],
        ),
        Text(
          '직전 관측 대비 변화 · 공식 일별 자료 · 지표별 기준일 상이',
          style: t.body(12, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        if (_data == null && !_failed)
          Text('시장 지표 불러오는 중…', style: t.body(13, color: c.textMuted)),
        if (_failed) ReadFailureNotice(subject: '시장 지표', retry: _load),
        if (_data != null)
          LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth >= 850
                  ? (box.maxWidth - 2 * AppSpace.md) / 3
                  : box.maxWidth >= 500
                  ? (box.maxWidth - AppSpace.md) / 2
                  : box.maxWidth;
              return Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final s in _data!)
                    SizedBox(
                      width: width,
                      child: HoverBuilder(
                        onTap: () =>
                            context.go(macroLocation(series: s.seriesId)),
                        builder: (context, hovered) {
                          final last = s.points.lastOrNull;
                          final delta = MacroMetrics.change(
                            s,
                            MacroMetrics.base(s.points, 0),
                          );
                          return Container(
                            padding: const EdgeInsets.all(AppSpace.lg),
                            decoration: BoxDecoration(
                              color: hovered ? c.surfaceHover : c.surface,
                              border: Border.all(color: c.border),
                              borderRadius: context.shape.borderRadius,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        MacroBasics.name(s.seriesId, s.name),
                                        style: t.body(
                                          13,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: c.textMuted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(
                                  MacroBasics.forSeries(s.seriesId).summary,
                                  style: t.body(12, color: c.textSecondary),
                                ),
                                const SizedBox(height: AppSpace.sm),
                                Wrap(
                                  spacing: AppSpace.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      last == null
                                          ? '자료 미확보'
                                          : MacroMetrics.value(last.value),
                                      style: t.numeric(
                                        24,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      MacroMetrics.delta(s, delta),
                                      style: t.numeric(
                                        12,
                                        color: c.marketChange(delta),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(
                                  '${s.unit} · ${last == null ? '기준일 없음' : formatDate(last.date)}${s.status == 'stale' ? ' · 이전 자료' : ''}',
                                  style: t.body(11, color: c.textMuted),
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
          ),
      ],
    );
  }
}
