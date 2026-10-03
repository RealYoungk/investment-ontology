import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'financial_metrics.dart' show formatKrwLong;

class RetrospectiveFundCard extends StatelessWidget {
  const RetrospectiveFundCard({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final validation = row['validation'] as Map;
    return ShadAccordion<int>(
      maintainState: true,
      children: [
        ShadAccordionItem<int>(
          value: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row['periodStart']} ~ ${row['periodEnd']} · 단일 펀드',
                style: context.typo.body(14),
              ),
              Text(
                '자체 ${row['periodKind'] == 'ownSixMonthFiscalYear' ? '6' : '12'}개월 회계연도 · 후속 투자설명서의 상세표 일부',
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadAlert(
                description: Text(
                  '${row['publishedAt']} 정정 투자설명서에 실린 과거 기간입니다. 당해 감사보고서 원문을 확보한 것으로 표시하지 않습니다. 이 설명서는 이지회계법인의 적정 의견을 기재합니다. 상세표 일부와 요약표 사이 12개 충돌을 보존했습니다.',
                ),
              ),
              ShadAlert(
                description: Text(
                  '모든 항목이 숫자인 검산 ${validation['fullyNumericEquationCount']}개, 대시·빈칸을 제외한 부분합 검산 ${validation['missingWitnessSubtotalCount']}개입니다. 빈칸은 0원 금액이나 완전한 등식 검증이 아닙니다. 주석·전체 원문·전체 재무제표는 미검증이며 TTM에 합산하지 않습니다.',
                ),
              ),
              for (final a in row['accounts'] as List)
                ShadTooltip(
                  builder: (_) => Text(
                    '${a['printedAmount']}원 · 원본 PDF ${a['pageOrdinal']}쪽 · 추출 ${a['lineOrdinal']}행 · 열 ${a['tokenOrdinal']} · ${a['amountScope'] == 'stockAtPeriodEnd' ? '기말 시점' : '해당 회계기간'}',
                  ),
                  child: Semantics(
                    tooltip:
                        '${a['printedAmount']}원 · 원본 PDF ${a['pageOrdinal']}쪽 · 추출 ${a['lineOrdinal']}행 · 열 ${a['tokenOrdinal']} · ${a['amountScope'] == 'stockAtPeriodEnd' ? '기말 시점' : '해당 회계기간'}',
                    child: KeyValueRow(
                      label: a['accountLabel'],
                      labelWidth: 136,
                      value: formatKrwLong(double.parse(a['amountInteger'])),
                      numeric: true,
                    ),
                  ),
                ),
              ShadAccordion<int>(
                maintainState: true,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Text(
                      '요약표와 상세표의 원문 충돌 12개',
                      style: context.typo.body(13),
                    ),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in row['sourceConflicts'] as List)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.xs,
                            ),
                            child: Text(
                              '${c['period']} ${c['accountLabel']} · 요약 ${c['summary']['printedAmount']}원 (265쪽) / 상세 ${c['detailed']['printedAmount']}원 (${c['detailed']['pageOrdinal']}쪽)',
                              style: context.typo.body(
                                12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const ShadAlert(
                description: Text(
                  '2022년 상반기 자체 6개월 회계연도는 이 재무 절에 자본변동표가 없어 미등록입니다. 2021년 하반기 자체 6개월 회계연도는 자본변동표 누락 및 현금유출 구성항목 합계와 인쇄 총액의 3,672,767,716원 차이로 현금흐름표를 격리했습니다. 두 기간의 금액을 이 목록에 넣거나 12개월로 합산하지 않습니다.',
                ),
              ),
              ShadButton.ghost(
                onPressed: () => launchUrl(
                  Uri.parse(row['officialUrl']),
                  mode: LaunchMode.externalApplication,
                ),
                child: Flexible(child: const Text('공식 정정 투자설명서 PDF 보기')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
