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
    var expanded = false;
    return StatefulBuilder(
      key: ValueKey(company.corpCode),
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final labels = [
                if (company.homepageUrl?.trim().isNotEmpty == true) '홈페이지',
                if (company.phone?.trim().isNotEmpty == true) '전화',
                if (company.address?.trim().isNotEmpty == true) '본사 위치',
                expanded ? '기본정보 접기' : '기본정보 더보기',
              ];
              var requiredWidth = AppSpace.sm * (labels.length - 1);
              for (final label in labels) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: context.typo.body(12)),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                requiredWidth += painter.width + 50;
                painter.dispose();
              }
              final compact = constraints.maxWidth < requiredWidth;
              return Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (company.homepageUrl?.trim().isNotEmpty == true)
                    _QuickLink(
                      label: '홈페이지',
                      icon: Icons.language_outlined,
                      compact: compact,
                      hint: company.homepageUrl!,
                      uri: Uri.parse(
                        company.homepageUrl!.trim().startsWith('http')
                            ? company.homepageUrl!.trim()
                            : 'https://${company.homepageUrl!.trim()}',
                      ),
                    ),
                  if (company.phone?.trim().isNotEmpty == true)
                    _QuickLink(
                      label: '전화',
                      icon: Icons.call_outlined,
                      compact: compact,
                      hint: company.phone!,
                      uri: Uri(
                        scheme: 'tel',
                        path: company.phone!.replaceAll(RegExp(r'[^0-9+]'), ''),
                      ),
                    ),
                  if (company.address?.trim().isNotEmpty == true)
                    _QuickLink(
                      label: '본사 위치',
                      icon: Icons.location_on_outlined,
                      compact: compact,
                      hint: company.address!,
                      uri: Uri.parse(
                        'https://map.naver.com/p/search/${Uri.encodeComponent(company.address!.trim())}',
                      ),
                    ),
                  if (compact)
                    Semantics(
                      container: true,
                      label: expanded ? '기본정보 접기' : '기본정보 더보기',
                      button: true,
                      enabled: true,
                      onTap: () => setState(() => expanded = !expanded),
                      child: ExcludeSemantics(
                        child: ShadIconButton.ghost(
                          onPressed: () => setState(() => expanded = !expanded),
                          icon: Icon(
                            expanded ? Icons.expand_less : Icons.info_outline,
                          ),
                          semanticLabel: expanded ? '기본정보 접기' : '기본정보 더보기',
                          foregroundColor: context.colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ShadButton.ghost(
                      onPressed: () => setState(() => expanded = !expanded),
                      leading: Icon(
                        expanded ? Icons.expand_less : Icons.info_outline,
                        size: 18,
                      ),
                      child: Flexible(
                        child: Text(
                          expanded ? '기본정보 접기' : '기본정보 더보기',
                          style: context.typo.body(
                            12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (expanded) ...[
            const SizedBox(height: AppSpace.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 650
                    ? 3
                    : constraints.maxWidth >= 400
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - AppSpace.lg * (columns - 1)) /
                    columns;
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
              _BasicField(
                label: '주소 · 네이버지도',
                value: company.address!,
                url:
                    'https://map.naver.com/p/search/${Uri.encodeComponent(company.address!.trim())}',
              ),
            ],
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.xs,
              children: [
                if (company.jurirNo?.trim().isNotEmpty == true)
                  ShadTooltip(
                    builder: (_) => Text('인터넷등기소에서 법인등록번호로 검색해 주세요.'),
                    child: Semantics(
                      tooltip: '인터넷등기소에서 법인등록번호로 검색해 주세요.',
                      child: _BasicField(
                        label: '법인등록번호 · 인터넷등기소',
                        value: company.jurirNo!,
                        url: 'https://www.iros.go.kr/',
                      ),
                    ),
                  ),
                if (company.bizrNo?.trim().isNotEmpty == true)
                  Text(
                    '사업자등록번호 ${company.bizrNo}',
                    style: context.typo.body(
                      11,
                      color: context.colors.textMuted,
                    ),
                  ),
                if (detail.industryPath.isNotEmpty)
                  ShadTooltip(
                    builder: (_) => Text(
                      detail.industryPath.map((item) => item.name).join(' › '),
                    ),
                    child: Semantics(
                      tooltip: detail.industryPath
                          .map((item) => item.name)
                          .join(' › '),
                      child: Text(
                        'KSIC ${detail.industryPath.last.code}',
                        style: context.typo.body(
                          11,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (detail.changes.isNotEmpty)
              ShadAccordion<int>(
                maintainState: false,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Text(
                      '기본정보 변경 기록',
                      style: context.typo.body(
                        11,
                        color: context.colors.textMuted,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_ChangeHistory(changes: detail.changes)],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.label,
    required this.hint,
    required this.uri,
    required this.icon,
    required this.compact,
  });
  final String label;
  final String hint;
  final Uri uri;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Future<bool> onPressed() =>
        launchUrl(uri, mode: LaunchMode.externalApplication);
    return Semantics(
      link: true,
      child: compact
          ? Semantics(
              container: true,
              label: '$label · $hint',
              button: true,
              enabled: true,
              onTap: onPressed,
              child: ExcludeSemantics(
                child: ShadIconButton.ghost(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  semanticLabel: '$label · $hint',
                  foregroundColor: context.colors.textSecondary,
                ),
              ),
            )
          : ShadTooltip(
              builder: (_) => Text(hint),
              child: Semantics(
                tooltip: hint,
                child: ShadButton.ghost(
                  onPressed: onPressed,
                  leading: Icon(icon, size: 18),
                  child: Flexible(
                    child: Text(
                      label,
                      style: context.typo.body(
                        12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
            child: ShadButton.ghost(
              height: 0,
              width: double.infinity,
              padding: EdgeInsets.zero,
              onPressed: () => launchUrl(
                Uri.parse(
                  url!.trim().startsWith('http')
                      ? url!.trim()
                      : 'https://${url!.trim()}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: text,
                ),
              ),
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
