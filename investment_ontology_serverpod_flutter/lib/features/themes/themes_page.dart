import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import '../common/formatters.dart';
import '../financials/financial_metrics.dart';

/// 테마 목록 (5단계): 사용자가 정의한 투자 주제. 편입 기업 시가총액이 큰 순서.
class ThemesPage extends StatefulWidget {
  const ThemesPage({super.key});

  @override
  State<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> {
  List<ThemeSummary>? _themes;
  Object? _error;
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _createError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await client.theme.list();
      if (mounted) setState(() => (_themes = t, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _create() async {
    if (!context.ensureAdmin()) return;
    try {
      final theme = await client.theme.create(
        _name.text,
        description: _description.text,
      );
      if (!mounted) return;
      _name.clear();
      _description.clear();
      setState(() => _createError = null);
      context.push(AppRoutes.theme(theme.id!));
      await _load();
    } on IngestException catch (e) {
      if (mounted) setState(() => _createError = e.message);
    } catch (e) {
      // 연결 오류도 화면에 보여 준다 (조용히 사라지면 만들어진 줄 안다).
      if (mounted) setState(() => _createError = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final themes = _themes;
    return PageFrame(
      children: [
        const PageHeading(
          eyebrow: 'INVESTMENT ONTOLOGY · 테마',
          title: '테마',
          subtitle:
              '직접 정의하는 투자 주제입니다. 기업을 넣을 때 왜 넣었는지 메모를 남기고, '
              '편입은 사용자 입력(manual)으로 출처가 남습니다.',
        ),
        const SizedBox(height: AppSpace.xl),
        if (!context.isAdmin)
          const AppNotice(message: '읽기 전용 계정입니다. 테마를 만들거나 고치려면 관리자 권한이 필요합니다.')
        else
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _name,
                  style: t.body(14),
                  decoration: const InputDecoration(hintText: '새 테마 이름'),
                  onSubmitted: (_) => _create(),
                ),
              ),
              SizedBox(
                width: 360,
                child: TextField(
                  controller: _description,
                  style: t.body(14),
                  decoration: const InputDecoration(hintText: '설명 (선택)'),
                  onSubmitted: (_) => _create(),
                ),
              ),
              AppButton(
                label: '테마 만들기',
                variant: AppButtonVariant.primary,
                onPressed: _create,
              ),
              if (_createError != null)
                Text(_createError!, style: t.body(13, color: c.accent)),
            ],
          ),
        const SizedBox(height: AppSpace.xl),
        if (_error != null)
          AppNotice(message: '테마를 불러오지 못했습니다 — $_error')
        else if (themes == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (themes.isEmpty)
          Text(
            '아직 테마가 없습니다. 위에서 만들고, 기업 상세의 "테마에 추가"로 기업을 넣을 수 있습니다.',
            style: t.body(13, color: c.textMuted),
          )
        else
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              for (final s in themes)
                HoverBuilder(
                  onTap: () async {
                    await context.push(AppRoutes.theme(s.theme.id!));
                    await _load();
                  },
                  builder: (context, hovered) => AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 300,
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
                          s.theme.name,
                          style: t.body(18, weight: FontWeight.w700),
                        ),
                        if (s.theme.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.theme.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.body(12.5, color: c.textSecondary),
                          ),
                        ],
                        const SizedBox(height: AppSpace.md),
                        Text(
                          '${formatCount(s.memberCount)}개사 · 시가총액 ${formatKrw(s.marketCap)}',
                          style: t.numeric(13, weight: FontWeight.w600),
                        ),
                        if (s.topNames.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.topNames.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.body(12, color: c.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
