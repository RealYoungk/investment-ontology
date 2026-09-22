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
          title: '지분 묶음',
          subtitle:
              '한 기업의 주가는 그 기업만으로 움직이지 않습니다. 지주사·계열사의 지분 매각, 합병, 상속, '
              '순환출자 해소, 계열사 부실 지원 같은 사건은 지분으로 이어진 다른 상장사의 주가로 번집니다. '
              '이 화면은 그 전파 경로를 미리 그려 둔 것입니다 — 어떤 기업을 볼 때 "같이 봐야 할 기업"이 '
              '무엇인지, 지주사 할인·계열 리스크가 어디서 오는지 찾는 데 씁니다.\n'
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
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 1020
                  ? 3
                  : box.maxWidth >= 680
                  ? 2
                  : 1;
              final width =
                  (box.maxWidth - AppSpace.md * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final g in groups)
                    SizedBox(
                      width: width,
                      child: _GroupCard(group: g),
                    ),
                ],
              );
            },
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

        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: hovered ? c.surfaceHover : c.surface,
          borderRadius: context.shape.borderRadius,
          border: Border.all(color: c.border),
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
                '여러 곳의 주주: ${g.sharedPersons.take(4).map(personLabel).join(' · ')}',
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

/// 같은 이름의 다른 사람이 섞여 보이지 않게, 출생년도나 추정 여부를 덧붙인다.
String personLabel(GroupPerson p) => switch ((p.birthYear, p.estimated)) {
  (final int year, _) => '${p.name}($year년생)',
  (_, true) => '${p.name}(추정)',
  _ => p.name,
};
