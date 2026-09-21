import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../business/business_tab.dart' show documentFactKindLabel;
import '../../financials/financial_metrics.dart';

/// 개요 탭의 사업 지표 요약: 본문에서 뽑은 값 중 최근 것과 그동안의 변화.
///
/// 탭을 열지 않아도 "수주잔고가 늘었는지"가 보이게 한다. 자세한 흐름은 사업의 내용 탭.
class BusinessHighlights extends StatefulWidget {
  const BusinessHighlights({
    super.key,
    required this.corpCode,
    required this.onOpenTab,
  });

  final String corpCode;
  final ValueChanged<String> onOpenTab;

  @override
  State<BusinessHighlights> createState() => _BusinessHighlightsState();
}

class _BusinessHighlightsState extends State<BusinessHighlights> {
  List<DocumentFact> _facts = const [];

  /// 먼저 보여 줄 순서. 앞으로를 말해 주는 값부터.
  static const _order = [
    DocumentFactKind.orderBacklog,
    DocumentFactKind.investmentPlan,
    DocumentFactKind.marketShare,
    DocumentFactKind.utilization,
    DocumentFactKind.production,
    DocumentFactKind.capacity,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessHighlights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      setState(() => _facts = const []);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final f = await client.disclosure.factTrends(widget.corpCode);
      if (mounted) setState(() => _facts = f);
    } catch (_) {}
  }

  static int _year(DocumentFact f) => f.asOf?.year ?? f.bsnsYear;

  /// (항목, 구분)마다 가장 최근 값과 첫 해 대비 변화.
  List<({DocumentFact last, double? change, int firstYear})> get _rows {
    final by = <String, List<DocumentFact>>{};
    for (final f in _facts) {
      if (!_order.contains(f.kind)) continue;
      by.putIfAbsent('${f.kind.name}|${f.label}', () => []).add(f);
    }
    final rows = <({DocumentFact last, double? change, int firstYear})>[];
    for (final list in by.values) {
      list.sort((a, b) => _year(a).compareTo(_year(b)));
      final first = list.first, last = list.last;
      rows.add((
        last: last,
        change: list.length < 2 || first.value == 0
            ? null
            : 100 * (last.value - first.value) / first.value.abs(),
        firstYear: _year(first),
      ));
    }
    rows.sort((a, b) {
      final k = _order
          .indexOf(a.last.kind)
          .compareTo(_order.indexOf(b.last.kind));
      return k != 0 ? k : b.last.value.compareTo(a.last.value);
    });
    return rows.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final rows = _rows;
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '사업 지표 · 본문에서',
          trailing: AppButton(
            label: '사업의 내용 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: () => widget.onOpenTab('business'),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${documentFactKindLabel(r.last.kind)} · ${r.last.label}',
                    style: t.body(13, color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  formatUnitAmount(r.last.value, r.last.unit),
                  style: t.numeric(14, weight: FontWeight.w700),
                ),
                if (r.change case final change?) ...[
                  const SizedBox(width: AppSpace.sm),
                  SizedBox(
                    width: 96,
                    child: Text(
                      '${r.firstYear}→${_year(r.last)} '
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: t.numeric(
                        11.5,
                        color: change >= 0 ? c.success : c.accent,
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(width: 96),
              ],
            ),
          ),
      ],
    );
  }
}
