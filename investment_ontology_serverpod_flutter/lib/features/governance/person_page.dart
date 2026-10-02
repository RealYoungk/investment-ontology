import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import 'governance_view.dart';

/// 인물: 주주·임원으로 있는 기업 (각 기업의 가장 최근 사업보고서 기준).
///
/// 출생년월이 있는 임원은 확정 인물이다. 출생년월 없이 기업 묶음으로 묶은 인물은 추정이고,
/// 틀린 연결은 기업마다 끊을 수 있다.
class PersonPage extends StatefulWidget {
  const PersonPage({super.key, required this.personId});

  final int personId;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  PersonProfile? _profile;
  Object? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await client.governance.person(widget.personId);
      if (mounted) setState(() => (_profile = p, _loaded = true));
    } catch (e) {
      if (mounted) setState(() => (_error = e, _loaded = true));
    }
  }

  Future<void> _reject(PersonRole role, Person person) async {
    if (!context.ensureAdmin()) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('추정 연결 끊기'),
        content: Text(
          '${role.companyName} 주주 명단의 "${person.name}"을(를) 이 인물과 같은 사람으로 보지 않습니다. '
          '다시 계산해도 묶지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('끊기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await client.governance.rejectPersonLink(role.corpCode, person.name);
    await _load();
  }

  static String _relationLabel(PersonRole r) => switch (r.predicate) {
    RelationPredicate.shareholderOf => r.estimated ? '주주 (추정)' : '주주',
    RelationPredicate.executiveOf => '임원',
    _ => r.predicate.name,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final p = _profile;
    return PageFrame(
      maxWidth: 1080,
      children: [
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (p == null)
          (_error != null
              ? ReadFailureNotice(subject: '상세 정보', retry: _load)
              : Text(
                  '인물을 찾을 수 없습니다.',
                  style: t.body(14, color: c.textSecondary),
                ))
        else ...[
          Text(p.person.name, style: t.display(40, color: c.textPrimary)),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (p.person.birthYear != null)
                AppTag(
                  label:
                      '${p.person.birthYear}.${p.person.birthMonth.toString().padLeft(2, '0')}생',
                  numeric: true,
                  size: AppTagSize.medium,
                ),
              if (p.person.sex != null)
                AppTag(label: p.person.sex!, size: AppTagSize.medium),
              AppTag(
                label: p.person.estimated
                    ? '추정 인물 (출생년월 없음)'
                    : '임원 현황의 이름 + 출생년월로 확인',
                color: p.person.estimated ? c.accent : null,
                size: AppTagSize.medium,
              ),
            ],
          ),
          if (p.person.estimated) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              '최대주주 현황에는 이름만 있어서, 지분으로 서로 이어진 기업들의 주주 명단에 같은 이름이 '
              '나오면 같은 사람으로 추정했습니다. 틀린 연결은 오른쪽 "끊기"로 풉니다.',
              style: t.body(13, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          if (p.roles.any(
            (r) =>
                r.predicate == RelationPredicate.shareholderOf &&
                r.weight != null,
          )) ...[
            Text('어느 기업의 지분을 갖고 있나요?', style: t.display(24)),
            const SizedBox(height: AppSpace.sm),
            Text(
              '기업별 지분율 · 각 기업의 최근 사업보고서. 서로 다른 기업의 비율이므로 합산하지 않습니다.',
              style: t.body(12, color: c.textSecondary),
            ),
            const SizedBox(height: AppSpace.xl),
            for (final r in p.roles.where(
              (r) =>
                  r.predicate == RelationPredicate.shareholderOf &&
                  r.weight != null &&
                  r.weight! >= 0 &&
                  r.weight! <= 100,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xs,
                      children: [
                        AppButton(
                          label: r.companyName,
                          variant: AppButtonVariant.link,
                          onPressed: () => context.push(
                            AppRoutes.company(r.corpCode, tab: 'governance'),
                          ),
                        ),
                        Text(
                          '${formatRatio(r.weight)}${r.estimated ? ' · 추정 연결' : ''}',
                          style: t.numeric(16, color: c.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    LinearProgressIndicator(
                      value: r.weight! / 100,
                      minHeight: 10,
                      color: r.estimated ? c.chartSeries2 : c.chartSeries1,
                      backgroundColor: c.chartTile,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.xl),
          ],
          const SectionLabel('관계 · 각 기업의 최근 사업보고서'),
          const SizedBox(height: AppSpace.sm),
          LayoutBuilder(
            builder: (context, box) {
              // 좁은 화면에서는 관계·직위를 기업명 아래 줄에 넣고 사업연도는 뺀다
              // (모두 최근 사업보고서라 정보가 적다).
              final compact = box.maxWidth < 640;
              return AppDataTable(
                columns: [
                  if (compact)
                    const AppColumn('기업 · 관계', flex: true)
                  else
                    const AppColumn('기업', nowrap: true),
                  if (!compact) const AppColumn('관계', nowrap: true),
                  const AppColumn('지분율', numeric: true),
                  if (!compact) const AppColumn('직위 · 원문', flex: true),
                  if (!compact) const AppColumn('사업연도', nowrap: true),
                  const AppColumn('', width: 48),
                ],
                rows: [
                  for (final r in p.roles)
                    AppRow([
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HoverBuilder(
                            onTap: () => context.push(
                              AppRoutes.company(r.corpCode, tab: 'governance'),
                            ),
                            builder: (context, hovered) => Text(
                              r.companyName,
                              style: t
                                  .body(
                                    13,
                                    color: c.accent,
                                    weight: FontWeight.w600,
                                  )
                                  .copyWith(
                                    decoration: hovered
                                        ? TextDecoration.underline
                                        : null,
                                    decorationColor: c.accent,
                                  ),
                            ),
                          ),
                          if (compact)
                            Text(
                              [
                                _relationLabel(r),
                                ?r.position,
                                ?r.detail,
                              ].join(' · '),
                              style: t.body(12, color: c.textSecondary),
                            ),
                        ],
                      ),
                      if (!compact)
                        AppDataTable.text(context, _relationLabel(r)),
                      AppDataTable.text(
                        context,
                        r.weight == null ? null : formatRatio(r.weight),
                        numeric: true,
                      ),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          [?r.position, ?r.detail].join(' · '),
                        ),
                      if (!compact)
                        AppDataTable.text(context, 'FY${r.bsnsYear}'),
                      r.estimated
                          ? AppButton(
                              label: '끊기',
                              variant: AppButtonVariant.link,
                              tone: c.accent,
                              onPressed: () => _reject(r, p.person),
                            )
                          : const SizedBox.shrink(),
                    ]),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
