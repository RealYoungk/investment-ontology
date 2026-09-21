import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_metrics.dart';
import '../../common/formatters.dart';
import 'business_highlights.dart';
import 'ontology_digest.dart';
import 'recent_disclosures.dart';
import 'peer_digest.dart';
import 'price_chart.dart';

/// 기업 상세의 개요 탭: 재무 요약(자세히는 재무 탭) · 기업개황 · 산업 분류 · 변경 이력 · 출처.
class CompanyOverviewTab extends StatelessWidget {
  const CompanyOverviewTab({
    super.key,
    required this.detail,
    required this.financials,
    required this.onOpenFinancials,
    required this.onOpenTab,
  });

  /// 이보다 넓으면 두 단으로 놓는다.
  static const _twoColumnWidth = 980.0;

  final CompanyDetail detail;
  final CompanyFinancials? financials;
  final VoidCallback onOpenFinancials;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final main = [
      PriceChart(corpCode: detail.company.corpCode),
      const SizedBox(height: AppSpace.section),
      _FinancialDigest(financials: financials, onOpen: onOpenFinancials),
      const SizedBox(height: AppSpace.section),
      BusinessHighlights(
        corpCode: detail.company.corpCode,
        onOpenTab: onOpenTab,
      ),
      const SizedBox(height: AppSpace.section),
      _Profile(company: detail.company),
    ];
    final side = [
      OntologyDigest(
        corpCode: detail.company.corpCode,
        onOpenTab: onOpenTab,
      ),
      const SizedBox(height: AppSpace.lg),
      PeerDigest(corpCode: detail.company.corpCode),
      const SizedBox(height: AppSpace.xl),
      if (detail.industryPath.isNotEmpty) ...[
        const SectionLabel('산업 분류 · KSIC'),
        const SizedBox(height: 10),
        _IndustryPath(path: detail.industryPath),
        const SizedBox(height: AppSpace.xxl),
      ],
      RecentDisclosures(corpCode: detail.company.corpCode),
      const SizedBox(height: AppSpace.xxl),
      _ChangeHistory(changes: detail.changes),
      const SizedBox(height: AppSpace.xxl),
      _SourceNote(
        corpCode: detail.company.corpCode,
        source: detail.profileSource,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...main,
              const SizedBox(height: AppSpace.section),
              ...side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: main,
              ),
            ),
            const SizedBox(width: AppSpace.section),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: side,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 연간 매출액·영업이익 추이. 지표·분기·재무제표는 재무 탭에서 본다.
class _FinancialDigest extends StatelessWidget {
  const _FinancialDigest({required this.financials, required this.onOpen});

  final CompanyFinancials? financials;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final fin = financials;
    final points = fin == null
        ? const <PeriodPoint>[]
        : FinancialView(fin).annual();
    final series = [
      ChartSeries(
        label: '매출액',
        color: c.chartSeries1,
        values: [for (final p in points) p.revenue.value],
      ),
      ChartSeries(
        label: '영업이익',
        color: c.chartSeries2,
        values: [for (final p in points) p.operatingIncome.value],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '재무 요약 · 연간${fin?.fsDiv == null ? '' : ' ${fsDivLabel(fin!.fsDiv!)}'}',
          trailing: AppButton(
            label: '재무 자세히 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: onOpen,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (points.isEmpty)
          Text(
            fin == null || fin.filingCount == 0
                ? '아직 재무를 수집하지 않았습니다.'
                : '사업보고서 재무가 아직 없습니다 (정기보고서 '
                      '${formatCount(fin.pendingFilingCount)}건 수집 대기).',
            style: t.body(13, color: c.textMuted),
          )
        else ...[
          ChartLegend(series: series),
          const SizedBox(height: AppSpace.sm),
          AppColumnChart(
            categories: [for (final p in points) p.label],
            series: series,
            formatValue: formatKrwShort,
          ),
        ],
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
        const SectionLabel('기업개황'),
        const SizedBox(height: 6),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (depth, industry) in path.indexed)
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  depth == 0 ? '■ ' : '└ ',
                  style: t.numeric(
                    12,
                    color: depth == path.length - 1 ? c.accent : c.textMuted,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    industry.code,
                    style: t.numeric(12.5, weight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    industry.name,
                    style: t.body(
                      13.5,
                      weight: depth == path.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        const SectionLabel('변경 이력'),
        const SizedBox(height: AppSpace.sm),
        if (changes.isEmpty)
          Text(
            '처음 수집한 뒤로 바뀐 내용이 없습니다.',
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
                        formatDateTime(change.changedAt),
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

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.corpCode, required this.source});

  final String corpCode;
  final Source? source;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final s = source;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: context.shape.borderRadius,
        border: Border.all(
          color: c.borderStrong,
          width: context.shape.strokeWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('출처', accent: true),
          const SizedBox(height: AppSpace.sm),
          Text(
            s?.title ?? '출처 기록 없음',
            style: t.body(13.5, weight: FontWeight.w600),
          ),
          if (s != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              '수집 ${formatDateTime(s.retrievedAt)}',
              style: t.numeric(12, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'DART 공시 목록 열기 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: () => launchUrl(
              Uri.parse(
                'https://dart.fss.or.kr/dsab007/main.do?autoSearch=true&option=corp&textCrpCik=$corpCode',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
