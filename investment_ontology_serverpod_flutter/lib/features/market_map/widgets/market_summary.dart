import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// Market scope shared by capitalization, filings and industry exploration.
class MarketSummary extends StatelessWidget {
  const MarketSummary({
    super.key,
    required this.overview,
    required this.selected,
    required this.onSelect,
    this.failed = false,
  });

  final Overview? overview;
  final bool failed;
  final Market? selected;
  final ValueChanged<Market?> onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final f in overview?.byMarket ?? <FacetCount>[]) f.code: f.count,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          title: '시장',
          subtitle: overview == null
              ? failed
                    ? '시장 요약을 불러오지 못했어요'
                    : '시장 요약 불러오는 중…'
              : '국내 상장 ${formatCount(overview!.totalListed)}개사',
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final market in <Market?>[
              null,
              Market.kospi,
              Market.kosdaq,
              Market.konex,
            ])
              IntrinsicWidth(
                child: ShadToggle.outline(
                  value: selected == market,
                  onChanged: (_) =>
                      onSelect(selected == market ? null : market),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(market == null ? '전체' : marketLabel(market)),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        (market == null
                                    ? overview?.totalListed
                                    : counts[market.name]) ==
                                null
                            ? '—'
                            : formatCount(
                                (market == null
                                    ? overview!.totalListed
                                    : counts[market.name])!,
                              ),
                        style: context.typo.numeric(
                          13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '시장 선택은 시가총액·업종 지도·최근 정기보고서에 적용됩니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
      ],
    );
  }
}
