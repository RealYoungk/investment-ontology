import 'package:shad/shad.dart';
import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/tokens.dart';

/// 보유 자료의 범위와 수집 대기를 구분한다. 상장일을 추정하지 않는다.
class FinancialCoverage extends StatelessWidget {
  const FinancialCoverage({super.key, required this.data});
  final CompanyFinancials data;

  @override
  Widget build(BuildContext context) {
    final years = data.periods.map((p) => p.bsnsYear).toSet().toList()..sort();
    if (years.isEmpty) return const SizedBox.shrink();
    final limited = years.length < 3;
    final range = years.length == 1
        ? '${years.first}년만 제공'
        : '${years.first}–${years.last}년 · ${years.length}개 연도';
    final pending = data.pendingFilingCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: ShadAccordion<int>(
        maintainState: false,
        children: [
          ShadAccordionItem<int>(
            value: 0,
            title: Text(
              '수집 자료 · $range${pending > 0 ? ' · $pending건 대기' : ''}',
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '수집된 정기보고서 기준이며 전체 공시 이력을 뜻하지 않습니다.'
                    '${limited ? ' 비교 기간이 짧아 장기 추세 해석에 주의가 필요합니다.' : ''}',
                    style: context.typo.body(
                      12,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
