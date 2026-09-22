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
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            left: BorderSide(color: context.colors.borderStrong, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '재무 자료 범위 · $range',
              style: context.typo.body(13, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              pending > 0
                  ? '확인된 정기보고서 중 $pending건은 수집 대기 중입니다. 수집 후 과거 자료가 추가될 수 있습니다.'
                  : '현재 수집된 정기보고서 기준입니다. 상장 전 자료와 과거 공시 전체의 확보를 뜻하지 않습니다.',
              style: context.typo.body(12, color: context.colors.textSecondary),
            ),
            if (limited) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                '비교 기간이 짧아 장기 성장 추세를 판단하기 어렵습니다. 자료가 적다는 이유만으로 신규 상장 기업으로 분류하지 않습니다.',
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
