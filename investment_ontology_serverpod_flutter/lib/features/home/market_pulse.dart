import 'package:shad/shad.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/tokens.dart';
import '../../design/components/data_panel.dart';
import '../common/formatters.dart';

typedef MarketPulseLoad = Future<List<IndexHistory>> Function();

class MarketPulse extends StatefulWidget {
  const MarketPulse({super.key, this.load});
  final MarketPulseLoad? load;
  @override
  State<MarketPulse> createState() => _MarketPulseState();
}

class _MarketPulseState extends State<MarketPulse> {
  List<IndexHistory>? _items;
  bool _failed = false;
  int _seq = 0;
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

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _failed = false);
    try {
      final result =
          await (widget.load?.call() ??
              Future.wait([
                for (final name in ['코스피', '코스닥'])
                  client.market.indexHistory(name, days: 30),
              ]));
      if (mounted && seq == _seq) {
        setState(() => _items = result.whereType<IndexHistory>().toList());
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final items = _items?.where((h) => h.points.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('시장 한눈에', style: t.body(16, weight: FontWeight.w600)),
            const Spacer(),
            ShadButton.ghost(
              onPressed: () => context.go('/market'),
              child: Flexible(child: const Text('시장 전체 →')),
            ),
          ],
        ),
        if (_failed)
          ShadButton.ghost(
            onPressed: _load,
            child: Flexible(child: const Text('시장 자료를 불러오지 못했어요 · 다시 시도')),
          )
        else if (items == null)
          const ShadProgress(minHeight: 2)
        else if (items.isEmpty)
          Text('수집된 지수 자료가 아직 없습니다.', style: t.body(13, color: c.textSecondary))
        else
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final h in items)
                  SizedBox(
                    width: box.maxWidth < 450
                        ? box.maxWidth
                        : (box.maxWidth - AppSpace.md) / 2,
                    child: DataPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                h.name,
                                style: t.body(13, weight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                h.lastChangeRate == null
                                    ? '등락 자료 없음'
                                    : '${h.lastChangeRate! > 0 ? '+' : ''}${h.lastChangeRate!.toStringAsFixed(2)}%',
                                style: t.numeric(
                                  13,
                                  color: c.marketChange(h.lastChangeRate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            formatDecimal(h.points.last.value),
                            style: t.numeric(27, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          if (h.dayBase != null) ...[
                            Text(
                              '${h.points.last.value - h.dayBase!.value > 0 ? '+' : ''}${formatDecimal(h.points.last.value - h.dayBase!.value)}pt · 전일 대비',
                              style: t.numeric(
                                13,
                                color: c.marketChange(
                                  h.points.last.value - h.dayBase!.value,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.sm),
                          ],
                          Text(
                            '${formatDate(h.points.last.date)} 종가 · 전일 대비',
                            style: t.body(11, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '금융위원회 지수시세정보 · 다음 영업일 13시 이후 공개되는 일별 종가입니다.',
          style: t.body(11, color: c.textSecondary),
        ),
      ],
    );
  }
}
