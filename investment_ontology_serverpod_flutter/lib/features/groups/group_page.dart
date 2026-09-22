import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';
import 'groups_page.dart' show personLabel;

/// 지분 묶음 상세: 시가총액 지도, 묶음 안 지분 연결, 여러 곳의 주주인 인물.
class GroupPage extends StatefulWidget {
  const GroupPage({super.key, required this.corpCode});

  /// 묶음에 속한 아무 기업.
  final String corpCode;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  CompanyGroup? _group;
  Object? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GroupPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) _load();
  }

  Future<void> _load() async {
    try {
      final g = await client.group.of(widget.corpCode);
      if (mounted) setState(() => (_group = g, _loaded = true, _error = null));
    } catch (e) {
      if (mounted) setState(() => (_error = e, _loaded = true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final g = _group;
    return PageFrame(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: '← 지분 묶음',
            variant: AppButtonVariant.link,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/groups'),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (g == null)
          Text(
            _error != null
                ? '불러오지 못했습니다: $_error'
                : '이 기업은 아직 어느 지분 묶음에도 없습니다.',
            style: t.body(14, color: c.textSecondary),
          )
        else ...[
          const SectionLabel('INVESTMENT ONTOLOGY · 지분 묶음', accent: true),
          const SizedBox(height: AppSpace.sm),
          Text('${g.anchor.name} 묶음', style: t.display(40)),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${formatCount(g.members.length)}개사 · 시가총액 합 ${formatKrw(g.totalMarketCap)}'
                '${g.baseDate == null ? '' : ' · 기준일 ${formatDate(g.baseDate)}'}',
                style: t.numeric(13, color: c.textSecondary),
              ),
              AppButton(
                label: '관계망에서 보기 →',
                variant: AppButtonVariant.link,
                tone: c.accent,
                onPressed: () =>
                    context.push(AppRoutes.graph(g.anchor.corpCode)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          if (g.members.any((m) => m.marketCap != null)) ...[
            AppTreemap<String>(
              height: 320,
              items: [
                for (final m in g.members)
                  if (m.marketCap != null && m.marketCap! > BigInt.zero)
                    TreemapItem(
                      id: m.company.corpCode,
                      label: m.company.name,
                      detail: formatKrw(m.marketCap),
                      value: m.marketCap!.toDouble(),
                      tooltip:
                          '${m.company.name}\n시가총액 ${formatKrw(m.marketCap)}\n눌러서 기업 상세',
                    ),
              ],
              onTap: (item) => context.push(AppRoutes.company(item.id)),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          if (g.sharedPersons.isNotEmpty) ...[
            const SectionLabel('여러 곳의 주주인 인물'),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final p in g.sharedPersons)
                  HoverBuilder(
                    onTap: () => context.push(AppRoutes.person(p.personId)),
                    builder: (context, hovered) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hovered ? c.surfaceHover : c.surface,
                        borderRadius: context.shape.borderRadius,
                        border: Border.all(color: c.borderStrong),
                      ),
                      child: Text(
                        '${personLabel(p)} · ${p.companyCount}곳',
                        style: t.body(13),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          _Edges(group: g),
        ],
      ],
    );
  }
}

class _Edges extends StatelessWidget {
  const _Edges({required this.group});

  final CompanyGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final byId = {for (final m in group.members) m.company.id: m.company};
    final edges = [...group.edges]
      ..sort((a, b) => (b.ratio ?? 0).compareTo(a.ratio ?? 0));
    Widget company(int id) {
      final ref = byId[id];
      if (ref == null) return AppDataTable.text(context, '—');
      return HoverBuilder(
        onTap: () => context.push(AppRoutes.company(ref.corpCode)),
        builder: (context, hovered) => Text(
          ref.name,
          style: t
              .body(13, color: c.accent, weight: FontWeight.w600)
              .copyWith(
                decoration: hovered ? TextDecoration.underline : null,
                decorationColor: c.accent,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('묶음 안 지분 연결'),
        const SizedBox(height: AppSpace.xs),
        Text(
          '지분율이 높은 쪽부터. 가진 쪽의 지분 매각·합병·상속은 가진 기업의 주가에, 가진 기업의 '
          '실적·배당은 가진 쪽의 지분법 이익과 배당 수입에 닿습니다.',
          style: t.body(12.5, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, box) {
            // 좁은 화면에서는 근거를 짧게 (주주/출자 · 연도) 적어 표가 폭 안에 들게 한다.
            final compact = box.maxWidth < 640;
            return AppDataTable(
              columns: const [
                AppColumn('가진 쪽'),
                AppColumn('가진 기업'),
                AppColumn('지분율', numeric: true),
                AppColumn('근거', flex: true),
              ],
              rows: [
                for (final e in edges)
                  AppRow([
                    company(e.fromCompanyId),
                    company(e.toCompanyId),
                    AppDataTable.text(
                      context,
                      e.ratio == null
                          ? null
                          : '${e.ratio!.toStringAsFixed(2)}%',
                      numeric: true,
                    ),
                    AppDataTable.text(
                      context,
                      e.predicate == RelationPredicate.shareholderOf
                          ? (compact ? '주주 명단' : '최대주주 명단')
                          : (compact ? '타법인출자' : '타법인출자 (경영참여)'),
                      nowrap: true,
                    ),
                  ]),
              ],
            );
          },
        ),
      ],
    );
  }
}
