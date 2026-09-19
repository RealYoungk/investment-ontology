import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';

/// 지분 묶음: 지분으로 이어진 상장사 묶음. 시가총액 합이 큰 순서.
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<CompanyGroup>? _groups;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await client.group.list();
      if (mounted) setState(() => (_groups = g, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final groups = _groups;
    return PageFrame(
      children: [
        PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 지분 묶음',
          title: '지분 묶음',
          subtitle:
              '최대주주 명단의 법인 주주와 경영참여 목적 15% 이상 출자로 이어진 상장사 묶음입니다. '
              '각 기업의 가장 최근 사업보고서 기준으로 계산하며, 공정위 기업집단 지정과는 다릅니다.'
              '${groups == null ? '' : ' · ${formatCount(groups.length)}개 묶음'}',
        ),
        const SizedBox(height: AppSpace.xl),
        if (_error != null)
          AppNotice(message: '묶음을 불러오지 못했습니다 — $_error')
        else if (groups == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (groups.isEmpty)
          Text(
            '아직 묶음이 없습니다. 주요정보(최대주주·타법인출자)가 쌓이면 생깁니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [for (final g in groups) _GroupCard(group: g)],
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final CompanyGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final g = group;
    final others = [for (final m in g.members.skip(1)) m.company.name];
    return HoverBuilder(
      onTap: () => context.push(AppRoutes.group(g.anchor.corpCode)),
      builder: (context, hovered) => AnimatedContainer(
        duration: AppMotion.fast,
        width: 340,
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : c.surface,
          borderRadius: context.shape.borderRadius,
          border: Border.all(color: c.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${g.anchor.name} 묶음',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.body(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '${formatCount(g.members.length)}개사 · 시가총액 ${formatKrw(g.totalMarketCap)}',
              style: t.numeric(13, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              others.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.body(12, color: c.textSecondary),
            ),
            if (g.sharedPersons.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                '여러 곳의 주주: ${g.sharedPersons.take(4).map((p) => p.name).join(' · ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.body(12, color: c.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
