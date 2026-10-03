import '../../shareholder_rights/shareholder_rights_card.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import 'business_guide_panel.dart';
import 'company_news_section.dart';
import 'price_chart.dart';
import 'business_operating_section.dart';
import '../../macro/macro_page.dart';

/// 개요는 사업 이해와 규모 파악, 재무 탭은 기간별 분석을 담당한다.
class CompanyOverviewTab extends StatelessWidget {
  const CompanyOverviewTab({
    super.key,
    required this.detail,
    this.latestReport,
    this.dataVersion = 0,
  });

  final CompanyDetail detail;
  final FinancialPeriod? latestReport;
  final int dataVersion;

  @override
  Widget build(BuildContext context) {
    final main = [
      BusinessGuidePanel(
        corpCode: detail.company.corpCode,
        latestReport: latestReport,
      ),
      BusinessOperatingSection(
        corpCode: detail.company.corpCode,
        dataVersion: dataVersion,
        latestReport: latestReport,
      ),
      CompanyDataCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시장 환경도 함께 확인하세요',
              style: context.typo.body(16, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '원유·환율·금리가 원가와 수요에 전달되는 경로를 보고, 이 기업의 공시에서 실제 영향을 확인할 수 있습니다.',
              style: context.typo.body(13, color: context.colors.textSecondary),
            ),
            const SizedBox(height: AppSpace.md),
            ShadButton.raw(
              onPressed: () =>
                  context.push(macroLocation(company: detail.company.corpCode)),
              variant: ShadButtonVariant.outline,
              child: Flexible(child: Text('시장 지표 살펴보기 →')),
            ),
          ],
        ),
      ),
      ShareholderRightsCard(
        key: ValueKey('rights-$dataVersion'),
        corpCode: detail.company.corpCode,
      ),
      CompanyDataCard(
        child: PriceChart(corpCode: detail.company.corpCode),
      ),
      const SizedBox(height: AppSpace.sm),
      CompanyNewsSection(corpCode: detail.company.corpCode),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...main,
      ],
    );
  }
}
