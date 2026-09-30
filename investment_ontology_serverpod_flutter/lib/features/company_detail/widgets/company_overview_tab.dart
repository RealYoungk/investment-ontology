import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';
import 'business_guide_panel.dart';
import 'company_news_section.dart';
import 'price_chart.dart';

/// 개요는 사업 이해와 규모 파악, 재무 탭은 기간별 분석을 담당한다.
class CompanyOverviewTab extends StatelessWidget {
  const CompanyOverviewTab({
    super.key,
    required this.detail,
  });

  final CompanyDetail detail;

  @override
  Widget build(BuildContext context) {
    final main = [
      BusinessGuidePanel(
        corpCode: detail.company.corpCode,
      ),
      const SectionLabel('주가는 어떻게 움직였나요?', accent: true),
      const SizedBox(height: AppSpace.md),
      Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: context.colors.border),
          borderRadius: context.shape.borderRadius,
        ),
        child: PriceChart(corpCode: detail.company.corpCode),
      ),
      const SizedBox(height: AppSpace.xl),
      CompanyNewsSection(corpCode: detail.company.corpCode),
      const SizedBox(height: AppSpace.xl),
      const SectionLabel('어떤 기업인가요?', accent: true),
      const SizedBox(height: AppSpace.md),
      _CompanyInfoCard(
        title: Text(
          '기업 정보',
          style: context.typo.body(18, weight: FontWeight.w700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: _Profile(company: detail.company),
          ),
          if (detail.industryPath.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            _IndustryPath(path: detail.industryPath),
          ],
          if (detail.changes.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              title: Text(
                '정보 변경 기록 · ${detail.changes.length}건',
                style: context.typo.body(
                  13,
                  color: context.colors.textSecondary,
                ),
              ),
              children: [_ChangeHistory(changes: detail.changes)],
            ),
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...main,
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.company});

  final Company company;

  static Uri _webUri(String url) =>
      Uri.parse(url.startsWith('http') ? url : 'https://$url');

  @override
  Widget build(BuildContext context) {
    final homepage = company.homepageUrl;
    final ir = company.irUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyValueRow(label: '대표자', value: company.ceoName),
        KeyValueRow(
          label: '설립일',
          value: company.establishedDate == null
              ? null
              : formatDate(company.establishedDate),
        ),
        KeyValueRow(
          label: '결산월',
          value: company.fiscalMonth == null ? null : '${company.fiscalMonth}월',
        ),
        KeyValueRow(label: '법인등록번호', value: company.jurirNo, numeric: true),
        KeyValueRow(label: '사업자등록번호', value: company.bizrNo, numeric: true),
        KeyValueRow(label: '주소', value: company.address),
        KeyValueRow(label: '전화', value: company.phone, numeric: true),
        KeyValueRow(
          label: '홈페이지',
          value: homepage,
          onTap: homepage == null ? null : () => launchUrl(_webUri(homepage)),
        ),
        KeyValueRow(
          label: 'IR',
          value: ir,
          onTap: ir == null ? null : () => launchUrl(_webUri(ir)),
        ),
      ],
    );
  }
}

class _IndustryPath extends StatelessWidget {
  const _IndustryPath({required this.path});

  final List<Industry> path;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (path.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(path.last.name, style: t.body(15, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.xs),
        Text(
          'KSIC ${path.last.code}',
          style: t.numeric(12, color: c.textMuted),
        ),
        if (path.length > 1) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            path.take(path.length - 1).map((p) => p.name).join(' › '),
            style: t.body(12, color: c.textSecondary).copyWith(height: 1.6),
          ),
        ],
      ],
    );
  }
}

class _ChangeHistory extends StatelessWidget {
  const _ChangeHistory({required this.changes});

  final List<CompanyChange> changes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('기본정보 변경 기록'),
        const SizedBox(height: AppSpace.sm),
        if (changes.isEmpty)
          Text(
            '기록된 기본정보 변경이 없습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          for (final change in changes)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        companyFieldLabel(change.field),
                        style: t.body(13, weight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        formatDate(change.changedAt),
                        style: t.numeric(11.5, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: change.oldValue ?? '없음',
                          style: t
                              .body(13, color: c.textMuted)
                              .copyWith(decoration: TextDecoration.lineThrough),
                        ),
                        TextSpan(
                          text: '  →  ',
                          style: t.body(13, color: c.textMuted),
                        ),
                        TextSpan(
                          text: change.newValue ?? '없음',
                          style: t.body(13, color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({required this.title, required this.children});
  final Widget title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: context.shape.borderRadius,
      side: BorderSide(color: context.colors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpace.sm),
          ...children,
        ],
      ),
    ),
  );
}
