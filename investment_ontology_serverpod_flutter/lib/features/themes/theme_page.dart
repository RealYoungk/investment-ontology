import 'dart:async';

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

/// 테마 상세: 편입 기업 시가총액 지도 · 편입 기업 표 · 기업 추가.
class ThemePage extends StatefulWidget {
  const ThemePage({super.key, required this.themeId});

  final int themeId;

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  ThemeDetail? _detail;
  Object? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await client.theme.detail(widget.themeId);
      if (mounted) setState(() => (_detail = d, _loaded = true, _error = null));
    } catch (e) {
      if (mounted) setState(() => (_error = e, _loaded = true));
    }
  }

  Future<void> _edit(ThemeDetail d) async {
    if (!context.ensureAdmin()) return;
    final name = TextEditingController(text: d.theme.name);
    final description = TextEditingController(text: d.theme.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 고치기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: '설명'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await client.theme.update(
        widget.themeId,
        name.text,
        description: description.text,
      );
      await _load();
    }
  }

  Future<void> _delete(ThemeDetail d) async {
    if (!context.ensureAdmin()) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 지우기'),
        content: Text(
          '"${d.theme.name}"과 편입 기록 ${d.members.length}건을 지웁니다. 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await client.theme.delete(widget.themeId);
    if (mounted) {
      context.canPop() ? context.pop() : context.go('/themes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final d = _detail;
    return PageFrame(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: '테마 목록',
            variant: AppButtonVariant.link,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/themes'),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (d == null)
          Text(
            _error != null ? '불러오지 못했습니다: $_error' : '테마를 찾을 수 없습니다.',
            style: t.body(14, color: c.textSecondary),
          )
        else ...[
          Wrap(
            spacing: AppSpace.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(d.theme.name, style: t.display(40, color: c.textPrimary)),
              if (context.isAdmin) ...[
                AppButton(
                  label: '고치기',
                  variant: AppButtonVariant.link,
                  onPressed: () => _edit(d),
                ),
                AppButton(
                  label: '지우기',
                  variant: AppButtonVariant.link,
                  tone: c.accent,
                  onPressed: () => _delete(d),
                ),
              ],
            ],
          ),
          if (d.theme.description != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              d.theme.description!,
              style: t.body(14, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Text(
            '${formatCount(d.members.length)}개사 · 시가총액 합 ${formatKrw(_total(d))}'
            '${d.baseDate == null ? '' : ' · 기준일 ${formatDate(d.baseDate)}'}',
            style: t.numeric(13, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.xl),
          if (d.members.any((m) => m.marketCap != null)) ...[
            AppTreemap<String>(
              height: 320,
              items: [
                for (final m in d.members)
                  if (m.marketCap != null && m.marketCap! > BigInt.zero)
                    TreemapItem(
                      id: m.company.corpCode,
                      label: m.company.name,
                      detail: formatKrw(m.marketCap),
                      value: m.marketCap!.toDouble(),
                      tooltip:
                          '${m.company.name}\n시가총액 ${formatKrw(m.marketCap)}'
                          '${m.member.note == null ? '' : '\n${m.member.note}'}\n눌러서 기업 상세',
                    ),
              ],
              onTap: (item) => context.push(AppRoutes.company(item.id)),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          _Members(detail: d, onChanged: _load),
          const SizedBox(height: AppSpace.section),
          if (context.isAdmin)
            _AddCompany(themeId: widget.themeId, onAdded: _load)
          else
            const AppNotice(message: '읽기 전용 계정입니다. 기업을 넣고 빼려면 관리자 권한이 필요합니다.'),
        ],
      ],
    );
  }

  static BigInt? _total(ThemeDetail d) {
    final caps = [for (final m in d.members) ?m.marketCap];
    return caps.isEmpty ? null : caps.reduce((a, b) => a + b);
  }
}

class _Members extends StatelessWidget {
  const _Members({required this.detail, required this.onChanged});

  final ThemeDetail detail;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final total = detail.members.fold(
      BigInt.zero,
      (s, m) => s + (m.marketCap ?? BigInt.zero),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('편입 기업'),
        const SizedBox(height: AppSpace.sm),
        if (detail.members.isEmpty)
          Text(
            '아직 기업이 없습니다. 아래에서 찾아 넣으세요.',
            style: t.body(13, color: c.textMuted),
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              // 좁은 화면(폰)에서는 기업명 아래 줄에 메모를 넣고 시가총액만 옆에 둔다.
              final compact = box.maxWidth < 720;
              return AppDataTable(
                columns: [
                  if (compact)
                    const AppColumn('기업 · 메모', flex: true)
                  else
                    const AppColumn('기업', nowrap: true, width: 120),
                  if (!compact) const AppColumn('시장', nowrap: true, width: 56),
                  if (!compact)
                    const AppColumn('업종', nowrap: true, minWidth: 120),
                  AppColumn(
                    '시가총액',
                    numeric: true,
                    nowrap: true,
                    width: compact ? 96 : 130,
                  ),
                  if (!compact)
                    const AppColumn(
                      '비중',
                      numeric: true,
                      nowrap: true,
                      width: 64,
                    ),
                  if (!compact) const AppColumn('메모 (왜 이 테마인가)', flex: true),
                  if (!compact) const AppColumn('편입일', nowrap: true, width: 96),
                  const AppColumn('', nowrap: true, width: 48),
                ],
                rows: [
                  for (final m in detail.members)
                    AppRow([
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HoverBuilder(
                            onTap: () => context.push(
                              AppRoutes.company(m.company.corpCode),
                            ),
                            builder: (context, hovered) => Text(
                              m.company.name,
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
                            if (m.member.note case final note?)
                              Text(
                                note,
                                style: t.body(12, color: c.textSecondary),
                              ),
                        ],
                      ),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          marketLabel(m.company.market),
                          nowrap: true,
                        ),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          m.industryName,
                          nowrap: true,
                        ),
                      AppDataTable.text(
                        context,
                        m.marketCap == null
                            ? null
                            : compact
                            ? formatKrwShort(m.marketCap!.toDouble())
                            : formatKrw(m.marketCap),
                        numeric: true,
                        nowrap: true,
                      ),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          m.marketCap == null || total == BigInt.zero
                              ? null
                              : '${(m.marketCap!.toDouble() / total.toDouble() * 100).toStringAsFixed(1)}%',
                          numeric: true,
                        ),
                      if (!compact) AppDataTable.text(context, m.member.note),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          formatDate(m.member.createdAt),
                          nowrap: true,
                        ),
                      AppButton(
                        label: '빼기',
                        variant: AppButtonVariant.link,
                        onPressed: () async {
                          if (!context.ensureAdmin()) return;
                          await client.theme.removeCompany(
                            detail.theme.id!,
                            m.company.corpCode,
                          );
                          await onChanged();
                        },
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

/// 기업을 찾아 테마에 넣는다.
class _AddCompany extends StatefulWidget {
  const _AddCompany({required this.themeId, required this.onAdded});

  final int themeId;
  final Future<void> Function() onAdded;

  @override
  State<_AddCompany> createState() => _AddCompanyState();
}

class _AddCompanyState extends State<_AddCompany> {
  final _query = TextEditingController();
  final _note = TextEditingController();
  List<CompanyListItem> _results = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _note.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (q.trim().isEmpty) {
        setState(() => _results = const []);
        return;
      }
      final page = await client.company.list(query: q.trim(), limit: 8);
      if (mounted) setState(() => _results = page.items);
    });
  }

  Future<void> _add(CompanyListItem item) async {
    if (!context.ensureAdmin()) return;
    await client.theme.addCompany(
      widget.themeId,
      item.corpCode,
      note: _note.text,
    );
    _note.clear();
    await widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('기업 넣기'),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _query,
                onChanged: _search,
                style: t.body(14),
                decoration: InputDecoration(
                  hintText: '회사명 · 종목코드',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: TextField(
                controller: _note,
                style: t.body(14),
                decoration: const InputDecoration(
                  hintText: '메모: 왜 이 테마인가 (선택)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        for (final item in _results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.stockCode ?? '',
                    style: t.numeric(12, color: c.textSecondary),
                  ),
                ),
                Expanded(child: Text(item.name, style: t.body(13.5))),
                AppButton(
                  label: '넣기',
                  variant: AppButtonVariant.link,
                  tone: c.accent,
                  onPressed: () => _add(item),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
