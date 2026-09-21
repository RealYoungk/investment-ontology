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
  FactPage? _facts;
  List<ReviewCheck> _checks = const [];

  /// false = 관계, true = 본문에서 뽑은 값.
  bool _showFacts = false;
  Object? _error;
  final _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (p, f, checks) = await (
        client.review.list(status: _status, predicate: _predicate, limit: 100),
        client.review.facts(status: _status, limit: 100),
        client.review.checks(),
      ).wait;
      if (mounted) {
        setState(
          () => (_page = p, _facts = f, _checks = checks, _error = null),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _decideFact(DocumentFact f, bool approve) async {
    setState(() => _busy.add(-f.id!));
    try {
      await client.review.decideFact(f.id!, approve);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(-f.id!));
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
              '사업보고서 "사업의 내용"에서 미리 뽑아 둔 관계와 값입니다. 근거 인용이 원문에 '
              '그대로 있는 것만 남겼고, 승인해야 온톨로지에 확정됩니다. 다시 뽑아도 결정은 유지됩니다.',
        ),
        const SizedBox(height: AppSpace.lg),
        _Accuracy(checks: _checks, facts: _showFacts),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppToggleGroup<bool>(
              value: _showFacts,
              options: {
                false:
                    '관계 ${_page == null ? '' : formatCount(_page!.draftCount)}',
                true:
                    '값 ${_facts == null ? '' : formatCount(_facts!.draftCount)}',
              },
              onChanged: (v) => setState(() => _showFacts = v),
            ),
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
            if (!_showFacts)
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
        else if (_showFacts)
          _FactList(
            page: _facts,
            busy: _busy,
            onDecide: _decideFact,
            status: _status,
          )
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
          LayoutBuilder(
            builder: (context, box) {
              final source = HoverBuilder(
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
              );
              final actions = <Widget>[
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
                ] else ...[
                  AppTag(
                    label: switch (r.status) {
                      RelationStatus.verified => '승인됨',
                      RelationStatus.rejected => '거절됨',
                      RelationStatus.draft => '검수 대기',
                    },
                  ),
                  // 누가 결정했는지. 사람이 누른 것은 표시하지 않는다.
                  if (r.reviewedBy != null) ...[
                    const SizedBox(width: AppSpace.xs),
                    AppTag(label: '원문 대조', color: c.textMuted),
                  ],
                ],
              ];
              // 폰에서는 출처 글이 버튼에 밀려 두 줄로 쪼개진다. 버튼을 아래 줄로 내린다.
              if (box.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    source,
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: source),
                  ...actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 확신도가 아니라 **실제로 몇 건이 맞았는지**. 근거 문장과 원문을 하나씩 대조한 기록이다.
class _Accuracy extends StatelessWidget {
  const _Accuracy({required this.checks, required this.facts});

  final List<ReviewCheck> checks;

  /// 지금 보고 있는 것이 값(true)인지 관계(false)인지.
  final bool facts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final scope = facts ? 'fact' : 'relation';
    final mine = [
      for (final x in checks)
        if (x.scope == scope) x,
    ];
    if (mine.isEmpty) return const SizedBox.shrink();
    final checked = mine.fold(0, (a, b) => a + b.checked);
    final correct = mine.fold(0, (a, b) => a + b.correct);
    final left = mine.fold(0, (a, b) => a + b.leftToPerson);
    if (checked == 0) return const SizedBox.shrink();
    final rate = 100 * correct / checked;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('대조 검수', accent: true),
          const SizedBox(height: 4),
          Text(
            '${formatCount(checked)}건을 근거 문장·원문과 하나씩 대조해 '
            '${formatCount(correct)}건이 맞았습니다 (${rate.toStringAsFixed(1)}%)'
            '${left == 0 ? '' : ' · 애매한 ${formatCount(left)}건은 사람 판단으로 남겼습니다'}.',
            style: t.body(13.5),
          ),
          const SizedBox(height: 4),
          Text(
            '모델이 스스로 매긴 확신도와 다른 숫자입니다. 대조한 것: '
            '${mine.map((x) => x.checkedBy).toSet().join(' · ')}',
            style: t.body(11.5, color: c.textMuted),
          ),
          // 기록이 쌓이면 최근 것만 (숫자는 위에서 다 합쳐 보여 준다).
          for (final x in mine.take(2))
            if (x.note case final note?) ...[
              const SizedBox(height: 4),
              Text(note, style: t.body(12, color: c.textSecondary)),
            ],
          if (mine.length > 2) ...[
            const SizedBox(height: 4),
            Text(
              '그 밖에 대조 기록 ${formatCount(mine.length - 2)}건',
              style: t.body(11.5, color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// 본문에서 뽑은 값 목록 (수주잔고·가동률·점유율 등).
class _FactList extends StatelessWidget {
  const _FactList({
    required this.page,
    required this.busy,
    required this.onDecide,
    required this.status,
  });

  final FactPage? page;
  final Set<int> busy;
  final void Function(DocumentFact, bool) onDecide;
  final RelationStatus status;

  static String kindLabel(DocumentFactKind k) => switch (k) {
    DocumentFactKind.orderTotal => '수주총액',
    DocumentFactKind.orderDelivered => '기납품액',
    DocumentFactKind.orderBacklog => '수주잔고',
    DocumentFactKind.capacity => '생산능력',
    DocumentFactKind.production => '생산실적',
    DocumentFactKind.utilization => '가동률',
    DocumentFactKind.marketShare => '시장점유율',
    DocumentFactKind.investmentPlan => '투자계획',
    DocumentFactKind.investmentActual => '투자집행',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final p = page;
    if (p == null) return const LinearProgressIndicator(minHeight: 2);
    if (p.items.isEmpty) {
      return Text(
        status == RelationStatus.draft
            ? '검수할 값이 없습니다. 사업보고서 본문을 읽어 넣으면 여기에 쌓입니다.'
            : '없습니다.',
        style: t.body(13, color: c.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${formatCount(p.total)}건 중 ${p.items.length}건 · API로는 받을 수 없고 본문에만 있는 값입니다',
          style: t.body(12, color: c.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final item in p.items)
          Container(
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
                    Text(
                      item.companyName,
                      style: t.body(14, weight: FontWeight.w700),
                    ),
                    AppTag(label: kindLabel(item.fact.kind), color: c.accent),
                    Text(item.fact.label, style: t.body(13.5)),
                    Text(
                      '${formatDecimal(item.fact.value)}${item.fact.unit}',
                      style: t.numeric(15, weight: FontWeight.w600),
                    ),
                    if (item.fact.asOf != null)
                      Text(
                        formatDate(item.fact.asOf),
                        style: t.numeric(12, color: c.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: c.background,
                    border: Border(
                      left: BorderSide(color: c.borderStrong, width: 3),
                    ),
                  ),
                  child: SelectableText(
                    '“${item.fact.evidence}”',
                    style: t
                        .body(12.5, color: c.textSecondary)
                        .copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                LayoutBuilder(
                  builder: (context, box) {
                    final source = Text(
                      'FY${item.fact.bsnsYear} 사업보고서 · 사업의 내용'
                      '${item.fact.extractorModel == null ? '' : ' · ${item.fact.extractorModel}'}',
                      style: t.body(11.5, color: c.textMuted),
                    );
                    final actions = <Widget>[
                      if (item.fact.status == RelationStatus.draft) ...[
                        AppButton(
                          label: '거절',
                          variant: AppButtonVariant.link,
                          onPressed: busy.contains(-item.fact.id!)
                              ? null
                              : () => onDecide(item.fact, false),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        AppButton(
                          label: '승인',
                          variant: AppButtonVariant.primary,
                          onPressed: busy.contains(-item.fact.id!)
                              ? null
                              : () => onDecide(item.fact, true),
                        ),
                      ] else ...[
                        AppTag(
                          label: item.fact.status == RelationStatus.verified
                              ? '승인됨'
                              : '거절됨',
                        ),
                        if (item.fact.reviewedBy != null) ...[
                          const SizedBox(width: AppSpace.xs),
                          AppTag(label: '원문 대조', color: c.textMuted),
                        ],
                      ],
                    ];
                    // 폰에서는 버튼을 아래 줄로 내린다 (출처 글이 쪼개지지 않게).
                    if (box.maxWidth < 460) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          source,
                          const SizedBox(height: AppSpace.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: source),
                        ...actions,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
