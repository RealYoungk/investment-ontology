import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final p = _profile;
    return PageFrame(
      maxWidth: 1080,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: '← 뒤로',
            variant: AppButtonVariant.link,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/companies'),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (p == null)
          Text(
            _error != null ? '불러오지 못했습니다: $_error' : '인물을 찾을 수 없습니다.',
            style: t.body(14, color: c.textSecondary),
          )
        else ...[
          const SectionLabel('INVESTMENT ONTOLOGY · 인물', accent: true),
          const SizedBox(height: AppSpace.sm),
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
          const SectionLabel('관계 · 각 기업의 최근 사업보고서'),
          const SizedBox(height: AppSpace.sm),
          AppDataTable(
            columns: const [
              AppColumn('기업'),
              AppColumn('관계'),
              AppColumn('지분율 (보통주)', numeric: true),
              AppColumn('직위 · 원문'),
              AppColumn('사업연도'),
              AppColumn(''),
            ],
            rows: [
              for (final r in p.roles)
                AppRow([
                  HoverBuilder(
                    onTap: () => context.push(
                      AppRoutes.company(r.corpCode, tab: 'governance'),
                    ),
                    builder: (context, hovered) => Text(
                      r.companyName,
                      style: t
                          .body(13, color: c.accent, weight: FontWeight.w600)
                          .copyWith(
                            decoration: hovered
                                ? TextDecoration.underline
                                : null,
                            decorationColor: c.accent,
                          ),
                    ),
                  ),
                  AppDataTable.text(
                    context,
                    switch (r.predicate) {
                      RelationPredicate.shareholderOf =>
                        r.estimated ? '주주 (추정)' : '주주',
                      RelationPredicate.executiveOf => '임원',
                      RelationPredicate.investsIn => '출자',
                    },
                  ),
                  AppDataTable.text(
                    context,
                    r.weight == null ? null : formatRatio(r.weight),
                    numeric: true,
                  ),
                  AppDataTable.text(
                    context,
                    [?r.position, ?r.detail].join(' · '),
                  ),
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
          ),
        ],
      ],
    );
  }
}
