import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../financials/financial_section.dart';
import '../formatters.dart';

/// 기업 카드: 기업개황 필드 + KSIC 경로 + 변경 이력 + 출처.
class CompanyCard extends StatefulWidget {
  const CompanyCard({
    super.key,
    required this.corpCode,
    required this.onClose,
  });

  final String corpCode;
  final VoidCallback onClose;

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  late final Future<CompanyDetail?> _future = client.company.detail(
    widget.corpCode,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CompanyDetail?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final detail = snap.data;
        return _Frame(
          onClose: widget.onClose,
          child: detail != null
              ? _Body(detail: detail)
              : Text(
                  snap.hasError
                      ? '불러오지 못했습니다: ${snap.error}'
                      : '기업을 찾을 수 없습니다.',
                  style: context.typo.body(14),
                ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            '기업 카드',
            accent: true,
            trailing: IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: context.colors.textPrimary),
              tooltip: '닫기',
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final CompanyDetail detail;

  static Uri _webUri(String url) =>
      Uri.parse(url.startsWith('http') ? url : 'https://$url');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final company = detail.company;
    final homepage = company.homepageUrl;
    final ir = company.irUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(company.name, style: t.display(34, color: c.textPrimary)),
        if (company.nameEng != null) ...[
          const SizedBox(height: 6),
          Text(company.nameEng!, style: t.body(13.5, color: c.textSecondary)),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: AppSpace.sm,
          children: [
            AppTag(
              label: marketLabel(company.market),
              color: c.accent,
              filled: true,
              numeric: true,
              size: AppTagSize.medium,
            ),
            if (company.stockCode != null)
              AppTag(
                label: company.stockCode!,
                numeric: true,
                size: AppTagSize.medium,
              ),
            AppTag(
              label: 'DART ${company.corpCode}',
              numeric: true,
              size: AppTagSize.medium,
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (detail.industryPath.isNotEmpty) ...[
          const SectionLabel('산업 분류 · KSIC'),
          const SizedBox(height: 10),
          _IndustryPath(path: detail.industryPath),
          const SizedBox(height: 28),
        ],
        FinancialSection(corpCode: company.corpCode),
        const SizedBox(height: 28),
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
        const SizedBox(height: 28),
        _ChangeHistory(changes: detail.changes),
        const SizedBox(height: 28),
        _SourceNote(corpCode: company.corpCode, source: detail.profileSource),
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
