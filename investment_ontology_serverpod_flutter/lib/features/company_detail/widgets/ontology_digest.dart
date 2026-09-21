import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../app/router.dart';
import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../governance/governance_view.dart';
import '../../review/review_page.dart';

/// 개요 탭의 온톨로지 요약: 최대주주 · 임원 · 출자 · 승인된 AI 관계. 각 탭과 관계망으로 건너간다.
class OntologyDigest extends StatefulWidget {
  const OntologyDigest({
    super.key,
    required this.corpCode,
    required this.onOpenTab,
  });

  final String corpCode;

  /// 탭 이름(`governance`, `business`)을 받아 그 탭을 연다.
  final ValueChanged<String> onOpenTab;

  @override
  State<OntologyDigest> createState() => _OntologyDigestState();
}

class _OntologyDigestState extends State<OntologyDigest> {
  CompanyGovernance? _gov;
  List<ReviewItem> _ai = const [];
  CompanyGroup? _group;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (gov, ai, group) = await (
        client.governance.summary(widget.corpCode),
        client.review.forCompany(widget.corpCode),
        client.group.of(widget.corpCode),
      ).wait;
      if (mounted) {
        setState(() => (_gov = gov, _ai = ai, _group = group, _loaded = true));
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (!_loaded) return const SizedBox.shrink();
    final gov = _gov;
    final hasGov = gov != null && gov.bsnsYear != null;
    final verified = [
      for (final i in _ai)
        if (i.relation.status == RelationStatus.verified) i,
    ];
    if (!hasGov && verified.isEmpty) return const SizedBox.shrink();

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: t.body(12.5, color: c.textSecondary)),
          ),
          Expanded(child: Text(value, style: t.body(13))),
        ],
      ),
    );

    final lines = <Widget>[];
    if (hasGov) {
      final view = GovernanceView(gov);
      final holders = view.holders();
      final investments = view.investments();
      final listed = investments.where((n) => n.corpCode != null).length;
      lines
        ..add(
          line(
            '최대주주',
            holders.isEmpty
                ? '—'
                : '${holders.first.name} ${formatRatio(holders.first.weight)}'
                      ' · 특수관계인 합 ${formatRatio(view.holderTotal())}',
          ),
        )
        ..add(line('임원', '${gov.executives.length}명'))
        ..add(
          line('출자', '${investments.length}곳 (상장사 $listed곳)'),
        );
      if (gov.investors.isNotEmpty) {
        lines.add(
          line(
            '출자받음',
            gov.investors.take(3).map((l) => l.name).join(' · ') +
                (gov.investors.length > 3
                    ? ' 외 ${gov.investors.length - 3}곳'
                    : ''),
          ),
        );
      }
    }
    final byPredicate = <RelationPredicate, int>{};
    for (final i in verified) {
      byPredicate[i.relation.predicate] =
          (byPredicate[i.relation.predicate] ?? 0) + 1;
    }
    if (byPredicate.isNotEmpty) {
      lines.add(
        line(
          '본문 관계',
          [
            for (final e in byPredicate.entries)
              '${predicateLabel(e.key)} ${e.value}',
          ].join(' · '),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            '온톨로지${hasGov ? ' · FY${gov.bsnsYear}' : ''}',
            accent: true,
          ),
          const SizedBox(height: AppSpace.sm),
          ...lines,
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.md,
            children: [
              if (hasGov)
                AppButton(
                  label: '지배구조 →',
                  variant: AppButtonVariant.link,
                  onPressed: () => widget.onOpenTab('governance'),
                ),
              if (_group case final g?)
                AppButton(
                  label: '${g.anchor.name} 묶음 ${g.members.length}개사 →',
                  variant: AppButtonVariant.link,
                  onPressed: () =>
                      context.push(AppRoutes.group(widget.corpCode)),
                ),
              AppButton(
                label: '관계망 →',
                variant: AppButtonVariant.link,
                tone: c.accent,
                onPressed: () => context.go(AppRoutes.graph(widget.corpCode)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
