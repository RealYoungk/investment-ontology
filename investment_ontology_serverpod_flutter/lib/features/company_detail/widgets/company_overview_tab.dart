import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import 'business_guide_panel.dart';
import 'business_operating_section.dart';
import 'revenue_composition.dart';
import 'company_news_section.dart';
import '../../../design/tokens.dart';

/// 개요는 사업 이해와 규모 파악, 재무 탭은 기간별 분석을 담당한다.
class CompanyOverviewTab extends StatelessWidget {
  const CompanyOverviewTab({
    super.key,
    required this.detail,
    this.latestReport,
    this.dataVersion = 0,
    this.businessDetail = false,
  });

  final bool businessDetail;
  final CompanyDetail detail;
  final FinancialPeriod? latestReport;
  final int dataVersion;

  @override
  Widget build(BuildContext context) {
    final business = <Widget>[
      BusinessGuidePanel(
        corpCode: detail.company.corpCode,
        latestReport: latestReport,
        afterRevenue: BusinessOperatingSection(
          corpCode: detail.company.corpCode,
          dataVersion: dataVersion,
          latestReport: latestReport,
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (businessDetail)
          ...business
        else ...[
          RevenueComposition(
            corpCode: detail.company.corpCode,
            showTrends: false,
            compact: true,
          ),
          const SizedBox(height: AppSpace.lg),
          CompanyNewsSection(corpCode: detail.company.corpCode, compact: true),
        ],
      ],
    );
  }
}
