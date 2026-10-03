import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import '../common/formatters.dart';

String predicateLabel(RelationPredicate p) => switch (p) {
  RelationPredicate.shareholderOf => '주주',
  RelationPredicate.executiveOf => '임원',
  RelationPredicate.investsIn => '출자',
  RelationPredicate.produces => '제품',
  RelationPredicate.suppliesTo => '공급',
  RelationPredicate.competesWith => '경쟁',
};

String factKindLabel(DocumentFactKind k) => switch (k) {
  DocumentFactKind.orderTotal => '수주총액',
  DocumentFactKind.orderDelivered => '기납품액',
  DocumentFactKind.orderBacklog => '수주잔고',
  DocumentFactKind.capacity => '생산능력',
  DocumentFactKind.production => '생산실적',
  DocumentFactKind.utilization => '가동률',
  DocumentFactKind.marketShare => '시장점유율',
  DocumentFactKind.investmentPlan => '투자계획',
  DocumentFactKind.investmentActual => '투자집행',
  DocumentFactKind.segmentRevenue => '부문 매출',
  DocumentFactKind.rndExpense => '연구개발비',
  DocumentFactKind.rndRatio => '연구개발비 비율',
  DocumentFactKind.segmentOperatingRevenue => '부문 손익표 매출',
  DocumentFactKind.segmentOperatingProfit => '부문 영업이익',
  DocumentFactKind.geographicRevenue => '지역별 매출',
};

/// 검수 큐: 사업보고서 본문에서 뽑아 둔 관계·값 가운데 사람 판단이 필요한 것.
///
/// 사람이 가장 느린 고리라, 화면은 한 건을 결정하는 데 드는 시간을 줄이는 데 맞춘다.
/// - 근거 문장을 원문 앞뒤와 함께 그 자리에서 펼쳐 본다 (원문 탭으로 가지 않는다).
/// - 대조한 쪽이 남긴 추천과 이유가 먼저 보이고, "추천대로 적용"으로 한 번에 끝낼 수 있다.
/// - 키보드: J/↓ 다음 · K/↑ 이전 · A 승인 · R 거절 · C 원문 맥락 펼치기.
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
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// 키보드로 고른 항목 (목록 안 순서).
  int _selected = 0;

  /// 원문 맥락을 펼친 항목의 열쇠 ("relation:12" · "fact:7").
  final _open = <String>{};
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (p, f, checks) = await (
        client.review.list(status: _status, predicate: _predicate, limit: 100),
        client.review.facts(status: _status, limit: 100),
        client.review.checks(),
      ).wait;
      if (mounted) {
        setState(() {
          _page = p;
          _facts = f;
          _checks = checks;
          _error = null;
          _selected = _selected.clamp(0, (_count - 1).clamp(0, 1 << 20));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  int get _count =>
      _showFacts ? (_facts?.items.length ?? 0) : (_page?.items.length ?? 0);

  String _keyOf(int index) => _showFacts
      ? 'fact:${_facts!.items[index].fact.id}'
      : 'relation:${_page!.items[index].relation.id}';

  Future<void> _decideFact(DocumentFact f, bool approve) async {
    if (!context.ensureAdmin()) return;
    setState(() => _busy.add(-f.id!));
    try {
      await client.review.decideFact(f.id!, approve);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(-f.id!));
    }
  }

  Future<void> _decide(OntologyRelation r, bool approve) async {
    if (!context.ensureAdmin()) return;
    setState(() => _busy.add(r.id!));
    try {
      await client.review.decide(r.id!, approve);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _applyRecommended() async {
    if (!context.ensureAdmin()) return;
    final scope = _showFacts ? 'fact' : 'relation';
    final n = await client.review.applyRecommended(scope);
    if (!mounted) return;
    ShadToaster.of(
      context,
    ).show(
      ShadToast(
        description: Text('추천대로 ${formatCount(n)}건을 결정했습니다.'),
      ),
    );
    await _load();
  }

  void _decideSelected(bool approve) {
    if (_status != RelationStatus.draft || _count == 0) return;
    if (_showFacts) {
      _decideFact(_facts!.items[_selected].fact, approve);
    } else {
      _decide(_page!.items[_selected].relation, approve);
    }
  }

  void _move(int delta) {
    if (_count == 0) return;
    setState(() => _selected = (_selected + delta).clamp(0, _count - 1));
    final key = _keys[_keyOf(_selected)];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: AppMotion.fast,
      );
    }
  }

  void _toggleContext(String key) => setState(() {
    if (!_open.remove(key)) _open.add(key);
  });

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.keyJ || k == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (k == LogicalKeyboardKey.keyK ||
        k == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (k == LogicalKeyboardKey.keyA) {
      _decideSelected(true);
    } else if (k == LogicalKeyboardKey.keyR) {
      _decideSelected(false);
    } else if (k == LogicalKeyboardKey.keyC) {
      if (_count > 0) _toggleContext(_keyOf(_selected));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// 추천이 있는 검수 대기 항목 수 (지금 목록 기준).
  int get _recommended => _showFacts
      ? (_facts?.items
                .where(
                  (i) =>
                      i.fact.status == RelationStatus.draft &&
                      i.fact.recommendation != null,
                )
                .length ??
            0)
      : (_page?.items
                .where(
                  (i) =>
                      i.relation.status == RelationStatus.draft &&
                      i.relation.recommendation != null,
                )
                .length ??
            0);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final page = _page;
    final facts = _facts;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focus.requestFocus(),
        child: PageFrame(
          maxWidth: 1080,
          controller: _scroll,
          children: [
            const PageHeading(
              title: '검수',
              subtitle:
                  '사업보고서 "사업의 내용"에서 미리 뽑아 둔 관계와 값입니다. 근거 인용이 원문에 그대로 있는 것만 남겼고, '
                  '대부분은 원문 대조를 거쳐 이미 확정했습니다. 여기에는 판단이 갈리는 것만 남고, 대조한 쪽의 추천과 이유가 붙어 있습니다.',
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '키보드: J·↓ 다음 · K·↑ 이전 · A 승인 · R 거절 · C 원문 맥락',
              style: t.body(12, color: c.textMuted),
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
                        '관계 ${page == null ? '' : formatCount(page.draftCount)}',
                    true:
                        '값 ${facts == null ? '' : formatCount(facts.draftCount)}',
                  },
                  onChanged: (v) => setState(() {
                    _showFacts = v;
                    _selected = 0;
                  }),
                ),
                AppToggleGroup<RelationStatus>(
                  value: _status,
                  options: {
                    RelationStatus.draft:
                        '검수 대기 ${_showFacts ? (facts == null ? '' : formatCount(facts.draftCount)) : (page == null ? '' : formatCount(page.draftCount))}',
                    RelationStatus.verified:
                        '승인 ${_showFacts ? (facts == null ? '' : formatCount(facts.verifiedCount)) : (page == null ? '' : formatCount(page.verifiedCount))}',
                    RelationStatus.rejected:
                        '거절 ${_showFacts ? (facts == null ? '' : formatCount(facts.rejectedCount)) : (page == null ? '' : formatCount(page.rejectedCount))}',
                  },
                  onChanged: (s) {
                    setState(() {
                      _status = s;
                      _selected = 0;
                    });
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
                      setState(() {
                        _predicate = p;
                        _selected = 0;
                      });
                      _load();
                    },
                  ),
                if (_status == RelationStatus.draft && _recommended > 0)
                  ShadButton.raw(
                    onPressed: _applyRecommended,

                    variant: ShadButtonVariant.primary,
                    child: Flexible(
                      child: Text('추천대로 ${formatCount(_recommended)}건 적용'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (_error != null)
              ReadFailureNotice(subject: '검수 큐', retry: _load)
            else if (_showFacts) ...[
              if (facts == null)
                const ShadProgress(minHeight: 2)
              else if (facts.items.isEmpty)
                Text(
                  _status == RelationStatus.draft
                      ? '검수할 값이 없습니다. 사업보고서 본문을 읽어 넣으면 판단이 갈리는 것만 여기 쌓입니다.'
                      : '없습니다.',
                  style: t.body(13, color: c.textMuted),
                )
              else ...[
                Text(
                  '${formatCount(facts.total)}건 중 ${facts.items.length}건 · API로는 받을 수 없고 본문에만 있는 값입니다',
                  style: t.body(12, color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final (i, item) in facts.items.indexed)
                  FactCard(
                    key: _keys.putIfAbsent(
                      'fact:${item.fact.id}',
                      GlobalKey.new,
                    ),
                    item: item,
                    selected: i == _selected,
                    contextOpen: _open.contains('fact:${item.fact.id}'),
                    onToggleContext: () =>
                        _toggleContext('fact:${item.fact.id}'),
                    onSelect: () => setState(() => _selected = i),
                    busy: _busy.contains(-item.fact.id!),
                    onDecide: item.fact.status == RelationStatus.draft
                        ? (approve) => _decideFact(item.fact, approve)
                        : null,
                  ),
              ],
            ] else if (page == null)
              const ShadProgress(minHeight: 2)
            else if (page.items.isEmpty)
              Text(
                _status == RelationStatus.draft
                    ? '남은 관계가 없습니다. 새 본문이 들어오면 서버 밖에서 읽어 넣은 뒤 판단이 갈리는 것만 여기 남깁니다.'
                    : '없습니다.',
                style: t.body(13, color: c.textMuted),
              )
            else ...[
              Text(
                '${formatCount(page.total)}건 중 ${page.items.length}건 · 확신도 높은 순',
                style: t.body(12, color: c.textMuted),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final (i, item) in page.items.indexed)
                ReviewCard(
                  key: _keys.putIfAbsent(
                    'relation:${item.relation.id}',
                    GlobalKey.new,
                  ),
                  item: item,
                  selected: i == _selected,
                  contextOpen: _open.contains('relation:${item.relation.id}'),
                  onToggleContext: () =>
                      _toggleContext('relation:${item.relation.id}'),
                  onSelect: () => setState(() => _selected = i),
                  busy: _busy.contains(item.relation.id),
                  onDecide: item.relation.status == RelationStatus.draft
                      ? (approve) => _decide(item.relation, approve)
                      : null,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 관계 하나: 주어 —종류→ 목적어, 추천과 이유, 근거 인용(원문 맥락 펼치기), 승인·거절.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.item,
    this.onDecide,
    this.busy = false,
    this.selected = false,
    this.contextOpen = false,
    this.onToggleContext,
    this.onSelect,
  });

  final ReviewItem item;
  final ValueChanged<bool>? onDecide;
  final bool busy;
  final bool selected;
  final bool contextOpen;
  final VoidCallback? onToggleContext;
  final VoidCallback? onSelect;

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
    return _CardFrame(
      selected: selected,
      onSelect: onSelect,
      head: Wrap(
        spacing: AppSpace.sm,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          node(r.subjectName, item.subjectCorpCode),
          ShadBadge.raw(
            variant: ShadBadgeVariant.outline,
            foregroundColor: c.accent,
            child: Text(
              predicateLabel(r.predicate),
              maxLines: 1,
              softWrap: false,
            ),
          ),
          node(r.objectName, item.objectCorpCode),
          if (r.confidence != null)
            Text(
              '확신도 ${(r.confidence! * 100).round()}%',
              style: t.numeric(11.5, color: c.textMuted),
            ),
        ],
      ),
      recommendation: r.recommendation,
      reviewNote: r.reviewNote,
      evidence: r.evidence ?? '',
      scope: 'relation',
      id: r.id!,
      contextOpen: contextOpen,
      onToggleContext: onToggleContext,
      source: HoverBuilder(
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
      status: r.status,
      reviewedBy: r.reviewedBy,
      busy: busy,
      onDecide: onDecide,
    );
  }
}

/// 값 하나: 기업 · 종류 · 값, 추천과 이유, 근거(원문 맥락), 승인·거절.
class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.item,
    this.onDecide,
    this.busy = false,
    this.selected = false,
    this.contextOpen = false,
    this.onToggleContext,
    this.onSelect,
  });

  final FactItem item;
  final ValueChanged<bool>? onDecide;
  final bool busy;
  final bool selected;
  final bool contextOpen;
  final VoidCallback? onToggleContext;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final f = item.fact;
    return _CardFrame(
      selected: selected,
      onSelect: onSelect,
      head: Wrap(
        spacing: AppSpace.sm,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          HoverBuilder(
            onTap: () => context.push(AppRoutes.company(item.corpCode)),
            builder: (context, hovered) => Text(
              item.companyName,
              style: t
                  .body(14, weight: FontWeight.w700, color: c.accent)
                  .copyWith(
                    decoration: hovered ? TextDecoration.underline : null,
                    decorationColor: c.accent,
                  ),
            ),
          ),
          ShadBadge.raw(
            variant: ShadBadgeVariant.outline,
            foregroundColor: c.accent,
            child: Text(factKindLabel(f.kind), maxLines: 1, softWrap: false),
          ),
          Text(f.label, style: t.body(13.5)),
          Text(
            '${formatDecimal(f.value)}${f.unit}',
            style: t.numeric(15, weight: FontWeight.w600),
          ),
          if (f.asOf != null)
            Text(formatDate(f.asOf), style: t.numeric(12, color: c.textMuted)),
        ],
      ),
      recommendation: f.recommendation,
      reviewNote: f.reviewNote,
      evidence: f.evidence,
      scope: 'fact',
      id: f.id!,
      contextOpen: contextOpen,
      onToggleContext: onToggleContext,
      source: Text(
        'FY${f.bsnsYear} 사업보고서 · 사업의 내용'
        '${f.extractorModel == null ? '' : ' · ${f.extractorModel}'}',
        style: t.body(11.5, color: c.textMuted),
      ),
      status: f.status,
      reviewedBy: f.reviewedBy,
      busy: busy,
      onDecide: onDecide,
    );
  }
}

/// 관계·값 카드의 공통 틀.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.head,
    required this.recommendation,
    required this.reviewNote,
    required this.evidence,
    required this.scope,
    required this.id,
    required this.contextOpen,
    required this.onToggleContext,
    required this.source,
    required this.status,
    required this.reviewedBy,
    required this.busy,
    required this.onDecide,
    required this.selected,
    required this.onSelect,
  });

  final Widget head;
  final RelationStatus? recommendation;
  final String? reviewNote;
  final String evidence;
  final String scope;
  final int id;
  final bool contextOpen;
  final VoidCallback? onToggleContext;
  final Widget source;
  final RelationStatus status;
  final String? reviewedBy;
  final bool busy;
  final ValueChanged<bool>? onDecide;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final rec = recommendation;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: context.shape.borderRadius,
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            // 추천이 있으면 근거보다 먼저 — 사람은 추천이 맞는지만 확인하면 된다.
            if (rec != null && status == RelationStatus.draft) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShadBadge.raw(
                    variant: ShadBadgeVariant.primary,
                    foregroundColor: rec == RelationStatus.verified
                        ? c.success
                        : c.textSecondary,
                    backgroundColor: rec == RelationStatus.verified
                        ? c.success
                        : c.textSecondary.withValues(alpha: 0.12),
                    child: Text(
                      rec == RelationStatus.verified ? '추천: 승인' : '추천: 거절',
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  if (reviewNote case final note?) ...[
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        note,
                        style: t
                            .body(13, color: c.textPrimary)
                            .copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (reviewNote case final note?) ...[
              const SizedBox(height: AppSpace.sm),
              Text(note, style: t.body(12.5, color: c.textSecondary)),
            ],
            const SizedBox(height: AppSpace.sm),
            _Evidence(
              evidence: evidence,
              scope: scope,
              id: id,
              open: contextOpen,
              onToggle: onToggleContext,
            ),
            const SizedBox(height: AppSpace.sm),
            LayoutBuilder(
              builder: (context, box) {
                final actions = <Widget>[
                  if (onDecide != null) ...[
                    ShadButton.raw(
                      onPressed: busy ? null : () => onDecide!(false),
                      enabled: (busy ? null : () => onDecide!(false)) != null,
                      variant: ShadButtonVariant.link,
                      child: Flexible(child: Text('거절 (R)')),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    ShadButton.raw(
                      onPressed: busy ? null : () => onDecide!(true),
                      enabled: (busy ? null : () => onDecide!(true)) != null,
                      variant: ShadButtonVariant.primary,
                      child: Flexible(child: Text('승인 (A)')),
                    ),
                  ] else ...[
                    ShadBadge.raw(
                      variant: ShadBadgeVariant.outline,
                      child: Text(
                        switch (status) {
                          RelationStatus.verified => '승인됨',
                          RelationStatus.rejected => '거절됨',
                          RelationStatus.draft => '검수 대기',
                        },
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    // 누가 결정했는지. 사람이 하나씩 누른 것은 표시하지 않는다.
                    if (reviewedBy case final by?) ...[
                      const SizedBox(width: AppSpace.xs),
                      ShadBadge.raw(
                        variant: ShadBadgeVariant.outline,
                        foregroundColor: c.textMuted,
                        child: Text(
                          by.startsWith('표 규칙')
                              ? '표 규칙'
                              : by.startsWith('추천대로')
                              ? '추천대로 일괄'
                              : '원문 대조',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
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
      ),
    );
  }
}

/// 근거 인용. 펼치면 원문 앞뒤 몇백 자를 받아 근거를 강조해 보여 준다.
class _Evidence extends StatefulWidget {
  const _Evidence({
    required this.evidence,
    required this.scope,
    required this.id,
    required this.open,
    required this.onToggle,
  });

  final String evidence;
  final String scope;
  final int id;
  final bool open;
  final VoidCallback? onToggle;

  @override
  State<_Evidence> createState() => _EvidenceState();
}

class _EvidenceState extends State<_Evidence> {
  ReviewContext? _context;
  bool _loading = false;
  Object? _error;

  @override
  void didUpdateWidget(covariant _Evidence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open && _context == null) _load();
  }

  @override
  void initState() {
    super.initState();
    if (widget.open) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ctx = await client.review.context(
        widget.scope,
        widget.id,
        around: 500,
      );
      if (mounted) {
        setState(() => (_context = ctx, _error = null, _loading = false));
      }
    } catch (e) {
      if (mounted) setState(() => (_error = e, _loading = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final ctx = _context;
    final body = t.body(13, color: c.textSecondary).copyWith(height: 1.6);
    final mark = t
        .body(13, color: c.textPrimary, weight: FontWeight.w600)
        .copyWith(height: 1.6, backgroundColor: c.accentSubtle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: c.background,
            border: Border(left: BorderSide(color: c.borderStrong, width: 3)),
          ),
          child: !widget.open || ctx == null
              ? SelectableText('“${widget.evidence}”', style: body)
              : SelectableText.rich(
                  TextSpan(
                    children: [
                      if (ctx.heading case final h?)
                        TextSpan(
                          text: '$h\n',
                          style: t.body(11.5, color: c.textMuted),
                        ),
                      if (ctx.found) ...[
                        TextSpan(text: '…${ctx.before}', style: body),
                        TextSpan(text: ctx.evidence, style: mark),
                        TextSpan(text: '${ctx.after}…', style: body),
                      ] else
                        TextSpan(
                          text:
                              '“${ctx.evidence}”\n(원문에서 이 문장을 찾지 못했습니다 — 본문이 다시 수집됐을 수 있습니다)',
                          style: body,
                        ),
                    ],
                  ),
                ),
        ),
        Row(
          children: [
            ShadButton.raw(
              onPressed: widget.onToggle,

              variant: ShadButtonVariant.link,
              child: Flexible(
                child: Text(
                  widget.open
                      ? '원문 맥락 접기 (C)'
                      : _loading
                      ? '원문 맥락 여는 중…'
                      : '원문 맥락 펼치기 (C)',
                ),
              ),
            ),
            if (_error != null)
              Expanded(
                child: ShadButton.ghost(
                  onPressed: _loading ? null : _load,
                  enabled: (_loading ? null : _load) != null,
                  child: Flexible(child: const Text('원문 맥락 다시 불러오기')),
                ),
              ),
          ],
        ),
      ],
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
