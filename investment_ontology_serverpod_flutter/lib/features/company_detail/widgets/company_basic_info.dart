import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

/// 기업 이름 아래에 기본 정보를 짧게 표시한다.
class CompanyBasicInfo extends StatelessWidget {
  const CompanyBasicInfo({super.key, required this.detail});
  final CompanyDetail detail;

  @override
  Widget build(BuildContext context) {
    final company = detail.company;
    final fields = <Widget>[
      _BasicField(
        label: '시장',
        value: company.market == Market.kospi
            ? '유가증권'
            : marketLabel(company.market),
      ),
      if (company.stockCode?.trim().isNotEmpty == true)
        _BasicField(label: '종목코드', value: company.stockCode!),
      if (detail.industryPath.isNotEmpty)
        _BasicField(label: '업종', value: detail.industryPath.last.name),
      if (company.ceoName?.trim().isNotEmpty == true)
        _BasicField(label: '대표자', value: company.ceoName!),
      if (company.establishedDate != null)
        _BasicField(label: '설립일', value: formatDate(company.establishedDate)),
      if (company.fiscalMonth != null)
        _BasicField(label: '결산월', value: '${company.fiscalMonth}월'),
      if (company.phone?.trim().isNotEmpty == true)
        _BasicField(label: '전화', value: company.phone!),
      if (company.homepageUrl?.trim().isNotEmpty == true)
        _BasicField(
          label: '홈페이지',
          value: company.homepageUrl!,
          url: company.homepageUrl,
        ),
      if (company.irUrl?.trim().isNotEmpty == true)
        _BasicField(label: 'IR', value: company.irUrl!, url: company.irUrl),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650 ? 3 : 2;
            final width =
                (constraints.maxWidth - AppSpace.lg * (columns - 1)) / columns;
            return Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.md,
              children: [
                for (final field in fields)
                  SizedBox(width: width, child: field),
              ],
            );
          },
        ),
        if (company.address?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpace.md),
          _BasicField(label: '주소', value: company.address!),
        ],
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.xs,
          children: [
            if (company.jurirNo?.trim().isNotEmpty == true)
              Text(
                '법인등록번호 ${company.jurirNo}',
                style: context.typo.body(11, color: context.colors.textMuted),
              ),
            if (company.bizrNo?.trim().isNotEmpty == true)
              Text(
                '사업자등록번호 ${company.bizrNo}',
                style: context.typo.body(11, color: context.colors.textMuted),
              ),
            if (detail.industryPath.isNotEmpty)
              Tooltip(
                message: detail.industryPath
                    .map((item) => item.name)
                    .join(' › '),
                child: Text(
                  'KSIC ${detail.industryPath.last.code}',
                  style: context.typo.body(11, color: context.colors.textMuted),
                ),
              ),
          ],
        ),
        if (detail.changes.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '기본정보 변경 기록',
              style: context.typo.body(11, color: context.colors.textMuted),
            ),
            children: [_ChangeHistory(changes: detail.changes)],
          ),
      ],
    );
  }
}

class _BasicField extends StatelessWidget {
  const _BasicField({required this.label, required this.value, this.url});
  final String label;
  final String value;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final display = url == null
        ? value
        : value
              .trim()
              .replaceFirst(RegExp(r'^https?://'), '')
              .replaceFirst(RegExp(r'/$'), '');
    final text = Text(
      display,
      style: context.typo
          .body(13, color: context.colors.textPrimary)
          .copyWith(
            decoration: url == null ? null : TextDecoration.underline,
          ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
        const SizedBox(height: AppSpace.xs),
        if (url == null)
          text
        else
          Semantics(
            link: true,
            child: InkWell(
              onTap: () => launchUrl(
                Uri.parse(
                  url!.trim().startsWith('http')
                      ? url!.trim()
                      : 'https://${url!.trim()}',
                ),
              ),
              child: text,
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
