import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';

String predicateLabel(RelationPredicate p) => switch (p) {
  RelationPredicate.shareholderOf => '주주',
  RelationPredicate.executiveOf => '임원',
  RelationPredicate.investsIn => '출자',
  RelationPredicate.produces => '제품',
  RelationPredicate.suppliesTo => '공급',
  RelationPredicate.competesWith => '경쟁',
};

/// 검수 큐 (4단계): AI가 사업보고서 본문에서 뽑은 관계를 근거 인용을 보고 승인·거절한다.
class ReviewQueuePage extends StatefulWidget {
  const ReviewQueuePage({super.key});

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage> {
  RelationStatus _status = RelationStatus.draft;
  RelationPredicate? _predicate;
  ReviewPage? _page;
  Object? _error;
  final _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await client.review.list(
        status: _status,
        predicate: _predicate,
        limit: 100,
      );
      if (mounted) setState(() => (_page = p, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _decide(OntologyRelation r, bool approve) async {
    setState(() => _busy.add(r.id!));
    try {
      await client.review.decide(r.id!, approve);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final page = _page;
    return PageFrame(
      maxWidth: 1080,
      children: [
        const PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 검수',
          title: '검수',
          subtitle:
              'AI가 사업보고서 "사업의 내용"에서 뽑은 관계입니다. 근거 인용이 원문에 그대로 있는 것만 '
              '남겼고, 승인해야 온톨로지에 확정됩니다. 다시 추출해도 결정은 유지됩니다.',
        ),
        const SizedBox(height: AppSpace.xl),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppToggleGroup<RelationStatus>(
              value: _status,
              options: {
                RelationStatus.draft:
                    '검수 대기 ${page == null ? '' : formatCount(page.draftCount)}',
                RelationStatus.verified:
                    '승인 ${page == null ? '' : formatCount(page.verifiedCount)}',
                RelationStatus.rejected:
                    '거절 ${page == null ? '' : formatCount(page.rejectedCount)}',
              },
              onChanged: (s) {
                setState(() => _status = s);
                _load();
              },
            ),
            AppToggleGroup<RelationPredicate?>(
              label: '종류',
              value: _predicate,
              options: const {
                null: '전체',
                RelationPredicate.suppliesTo: '공급',
                RelationPredicate.competesWith: '경쟁',
                RelationPredicate.produces: '제품',
              },
              onChanged: (p) {
                setState(() => _predicate = p);
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (_error != null)
          AppNotice(message: '검수 큐를 불러오지 못했습니다 — $_error')
        else if (page == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (page.items.isEmpty)
          Text(
            _status == RelationStatus.draft
                ? '검수할 관계가 없습니다. 데이터 화면에서 AI 관계 추출을 시작하세요 (Anthropic 키 필요).'
                : '없습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else ...[
          Text(
            '${formatCount(page.total)}건 중 ${page.items.length}건 · 확신도 높은 순',
            style: t.body(12, color: c.textMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final item in page.items)
            ReviewCard(
              item: item,
              busy: _busy.contains(item.relation.id),
              onDecide: item.relation.status == RelationStatus.draft
                  ? (approve) => _decide(item.relation, approve)
                  : null,
            ),
        ],
      ],
    );
  }
}

/// 관계 하나: 주어 —종류→ 목적어, 근거 인용, 원문 기업, 승인·거절.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.item,
    this.onDecide,
    this.busy = false,
  });

  final ReviewItem item;
  final ValueChanged<bool>? onDecide;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final r = item.relation;
    Widget node(String name, String? corpCode) => HoverBuilder(
      onTap: corpCode == null
          ? null
          : () => context.push(AppRoutes.company(corpCode)),
      builder: (context, hovered) => Text(
        name,
        style: t
            .body(
              14,
              color: corpCode == null ? c.textPrimary : c.accent,
              weight: FontWeight.w700,
            )
            .copyWith(
              decoration: hovered ? TextDecoration.underline : null,
              decorationColor: c.accent,
            ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              node(r.subjectName, item.subjectCorpCode),
              AppTag(label: predicateLabel(r.predicate), color: c.accent),
              node(r.objectName, item.objectCorpCode),
              if (r.confidence != null)
                Text(
                  '확신도 ${(r.confidence! * 100).round()}%',
                  style: t.numeric(11.5, color: c.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.background,
              border: Border(left: BorderSide(color: c.borderStrong, width: 3)),
            ),
            child: SelectableText(
              '“${r.evidence ?? ''}”',
              style: t.body(13, color: c.textSecondary).copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: HoverBuilder(
                  onTap: () => context.push(
                    AppRoutes.company(item.companyCorpCode, tab: 'business'),
                  ),
                  builder: (context, hovered) => Text(
                    '원문: ${item.companyName} FY${r.bsnsYear} 사업보고서 · 사업의 내용'
                    '${r.extractorModel == null ? '' : ' · ${r.extractorModel}'}',
                    style: t
                        .body(11.5, color: c.textMuted)
                        .copyWith(
                          decoration: hovered ? TextDecoration.underline : null,
                        ),
                  ),
                ),
              ),
              if (onDecide != null) ...[
                AppButton(
                  label: '거절',
                  variant: AppButtonVariant.link,
                  onPressed: busy ? null : () => onDecide!(false),
                ),
                const SizedBox(width: AppSpace.sm),
                AppButton(
                  label: '승인',
                  variant: AppButtonVariant.primary,
                  onPressed: busy ? null : () => onDecide!(true),
                ),
              ] else
                AppTag(
                  label: switch (r.status) {
                    RelationStatus.verified => '승인됨',
                    RelationStatus.rejected => '거절됨',
                    RelationStatus.draft => '검수 대기',
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
