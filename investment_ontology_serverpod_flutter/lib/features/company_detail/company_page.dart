import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import '../business/business_tab.dart';
import '../disclosures/disclosure_tab.dart';
import '../financials/financial_section.dart';
import '../governance/governance_tab.dart';
import '../groups/group_math.dart';
import '../financials/financial_metrics.dart' show formatKrwShort;
import '../shareholder_return/shareholder_return_tab.dart';
import 'widgets/company_header.dart';
import 'widgets/company_overview_tab.dart';

enum CompanyTab {
  overview,
  financials,
  business,
  governance,
  returns,
  disclosures,
}

/// 탭별 주요정보 항목. 이 가운데 하나라도 받았으면 탭을 보여 준다.
const _governanceSections = {
  DartSection.largestShareholders,
  DartSection.executives,
  DartSection.investments,
};
const _returnSections = {
  DartSection.dividend,
  DartSection.treasuryStock,
  DartSection.stockTotal,
};

/// 기업 상세: 헤더(이름 · 분류 · 핵심 지표) + 탭(개요 · 재무 · 지배구조 · 주주환원 · 공시 항목).
///
/// 개요는 각 탭의 요약이고 자세한 내용은 탭에서 본다. 탭은 데이터가 생기는 단계마다 늘린다
/// (3단계 지배구조 등). 빈 탭은 만들지 않는다.
class CompanyPage extends StatefulWidget {
  const CompanyPage({
    super.key,
    required this.corpCode,
    this.initialTab = CompanyTab.overview,
  });

  final String corpCode;
  final CompanyTab initialTab;

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late CompanyTab _tab = widget.initialTab;

  CompanyDetail? _detail;
  CompanyFinancials? _financials;
  List<DisclosureSectionInfo> _sections = const [];
  Object? _error;
  bool _loaded = false;

  /// 새 데이터를 불러올 때마다 올려 재무 탭을 새 값으로 다시 만든다.
  int _version = 0;

  /// 계산식을 펼친 지표. 머리의 지표를 누르면 재무 탭에서 그 계산식을 연다.
  String? _openMetric;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (detail, financials, sections) = await (
        client.company.detail(widget.corpCode),
        client.financial.summary(widget.corpCode),
        client.disclosure.sections(widget.corpCode),
      ).wait;
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _financials = financials;
        _sections = sections;
        _error = null;
        _loaded = true;
        _version++;
      });
    } catch (e) {
      final error = e is ParallelWaitError ? e.errors : e;
      if (mounted) setState(() => (_error = error, _loaded = true));
    }
  }

  void _openFinancials({String? metric}) => setState(() {
    _tab = CompanyTab.financials;
    // 같은 지표를 다시 누르면 닫는다.
    _openMetric = metric == _openMetric ? null : metric;
  });

  /// 원문 표로 보여 주는 항목 (사업의 내용은 글이라 따로 탭이 있다).
  List<DisclosureSectionInfo> get _tableSections => [
    for (final s in _sections)
      if (s.section != DartSection.businessContent) s,
  ];

  bool _has(Set<DartSection> wanted) =>
      _sections.any((s) => wanted.contains(s.section));

  /// 데이터가 있는 탭만.
  Map<CompanyTab, String> get _tabs => {
    CompanyTab.overview: '개요',
    CompanyTab.financials: '재무',
    if (_has({DartSection.businessContent})) CompanyTab.business: '사업의 내용',
    if (_has(_governanceSections)) CompanyTab.governance: '지배구조',
    if (_has(_returnSections)) CompanyTab.returns: '주주환원',
    if (_tableSections.isNotEmpty) CompanyTab.disclosures: '공시 항목',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final detail = _detail;
    final tabs = _tabs;
    final tab = tabs.containsKey(_tab) ? _tab : CompanyTab.overview;

    return PageFrame(
      children: [
        if (!_loaded)
          const LinearProgressIndicator(minHeight: 2)
        else if (detail == null)
          Text(
            _error != null ? '불러오지 못했습니다: $_error' : '기업을 찾을 수 없습니다.',
            style: t.body(14, color: c.textSecondary),
          )
        else ...[
          CompanyHeader(
            detail: detail,
            financials: _financials,
            openMetric: tab == CompanyTab.financials ? _openMetric : null,
            onOpenMetric: (key) => _openFinancials(metric: key),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ThemeChips(
                key: ValueKey('themes-$_version'),
                corpCode: widget.corpCode,
              ),
              AppButton(
                label: '다른 기업과 비교 →',
                variant: AppButtonVariant.link,
                onPressed: () =>
                    context.push(AppRoutes.compare([widget.corpCode])),
              ),
            ],
          ),
          _GroupLine(
            key: ValueKey('group-$_version'),
            corpCode: widget.corpCode,
            companyId: detail.company.id!,
          ),
          const SizedBox(height: AppSpace.lg),
          AppTabBar<CompanyTab>(
            tabs: tabs,
            value: tab,
            onChanged: (tab) => setState(() {
              _tab = tab;
              _openMetric = null;
            }),
          ),
          const SizedBox(height: AppSpace.xl),
          switch (tab) {
            CompanyTab.overview => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompanyOverviewTab(
                  detail: detail,
                  financials: _financials,
                  onOpenFinancials: () => _openFinancials(),
                  onOpenTab: (name) => setState(
                    () => _tab = CompanyTab.values.asNameMap()[name] ?? _tab,
                  ),
                ),
                if (_sections.isEmpty) ...[
                  const SizedBox(height: AppSpace.section),
                  _DisclosureFetchCard(
                    corpCode: widget.corpCode,
                    onDone: _load,
                  ),
                ],
              ],
            ),
            CompanyTab.governance => GovernanceTab(
              key: ValueKey('governance-$_version'),
              corpCode: widget.corpCode,
              companyName: detail.company.name,
            ),
            CompanyTab.returns => ShareholderReturnTab(
              key: ValueKey('returns-$_version'),
              corpCode: widget.corpCode,
            ),
            CompanyTab.disclosures => DisclosureTab(
              key: const ValueKey('disclosures'),
              dataVersion: _version,
              corpCode: widget.corpCode,
              sections: _tableSections,
            ),
            CompanyTab.business => BusinessTab(
              key: const ValueKey('business'),
              dataVersion: _version,
              corpCode: widget.corpCode,
            ),
            CompanyTab.financials => FinancialSection(
              key: const ValueKey('financials'),
              dataVersion: _version,
              corpCode: widget.corpCode,
              initialData: _financials,
              openMetric: _openMetric,
              onCloseMetric: () => setState(() => _openMetric = null),
            ),
          },
        ],
      ],
    );
  }
}

/// 주요정보를 아직 받지 않은 기업: 이 기업만 바로 받는다.
class _DisclosureFetchCard extends StatefulWidget {
  const _DisclosureFetchCard({required this.corpCode, required this.onDone});

  final String corpCode;
  final Future<void> Function() onDone;

  @override
  State<_DisclosureFetchCard> createState() => _DisclosureFetchCardState();
}

class _DisclosureFetchCardState extends State<_DisclosureFetchCard> {
  bool _fetching = false;
  String? _message;

  Future<void> _fetch() async {
    if (!context.ensureAdmin()) return;
    setState(() => (_fetching = true, _message = null));
    try {
      var job = await client.ingest.startDisclosures(corpCode: widget.corpCode);
      IngestMonitor.instance.poke();
      while (job.status == IngestStatus.running && mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await client.ingest.latestOf(job.kind) ?? job;
      }
      if (!mounted) return;
      setState(() => _message = job.message);
      await widget.onDone();
    } on IngestException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: context.shape.borderRadius,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('정기보고서 주요정보 · 지배구조 · 주주환원'),
          const SizedBox(height: AppSpace.sm),
          Text(
            '이 기업의 사업보고서 주요정보(최대주주·임원·출자·배당 등 28종)를 아직 받지 않았습니다. '
            '전체 수집은 매일 자동으로 이어지고, 이 기업만 먼저 받을 수도 있습니다 '
            '(사업보고서 5개년 × 28종, 최대 140회 호출).',
            style: t.body(13, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: _fetching ? '받는 중…' : '이 기업 주요정보 지금 받기',
            onPressed: _fetching ? null : _fetch,
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(_message!, style: t.body(12, color: c.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// 기업이 속한 테마와 "테마에 추가".
class _ThemeChips extends StatefulWidget {
  const _ThemeChips({super.key, required this.corpCode});

  final String corpCode;

  @override
  State<_ThemeChips> createState() => _ThemeChipsState();
}

class _ThemeChipsState extends State<_ThemeChips> {
  List<InvestmentTheme> _mine = const [];
  List<ThemeSummary> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (mine, all) = await (
        client.theme.themesOf(widget.corpCode),
        client.theme.list(),
      ).wait;
      if (mounted) setState(() => (_mine = mine, _all = all));
    } catch (_) {
      // 테마는 부가 정보라 실패해도 상세는 보여 준다.
    }
  }

  Future<void> _add(int themeId) async {
    if (!context.ensureAdmin()) return;
    await client.theme.addCompany(themeId, widget.corpCode);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final mineIds = {for (final m in _mine) m.id};
    final candidates = {
      for (final s in _all)
        if (!mineIds.contains(s.theme.id)) s.theme.id!: s.theme.name,
    };
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('테마', style: t.label(color: c.textSecondary)),
        for (final theme in _mine)
          HoverBuilder(
            onTap: () => context.push(AppRoutes.theme(theme.id!)),
            builder: (context, hovered) => AppTag(
              label: theme.name,
              color: hovered ? c.accent : null,
              size: AppTagSize.medium,
            ),
          ),
        if (candidates.isNotEmpty)
          AppSelect<int>(
            placeholder: '테마에 추가',
            allLabel: '—',
            value: null,
            options: candidates,
            onChanged: (id) {
              if (id != null) _add(id);
            },
          )
        else
          AppButton(
            label: _all.isEmpty ? '테마 만들기 →' : '새 테마 →',
            variant: AppButtonVariant.link,
            onPressed: () => context.go('/themes'),
          ),
      ],
    );
  }
}

/// 지분 묶음 한 줄: 이 기업이 묶음 안 상장사에 가진 지분의 시가 합(시총 대비)과, 묶음 안
/// 기업들이 이 기업에 가진 지분율. 계열사 사건이 이 주가로 얼마나 번질지 가늠하는 숫자.
class _GroupLine extends StatefulWidget {
  const _GroupLine({
    super.key,
    required this.corpCode,
    required this.companyId,
  });

  final String corpCode;
  final int companyId;

  @override
  State<_GroupLine> createState() => _GroupLineState();
}

class _GroupLineState extends State<_GroupLine> {
  CompanyGroup? _group;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await client.group.of(widget.corpCode);
      if (mounted) setState(() => (_group = g, _loaded = true));
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final g = _group;
    if (!_loaded || g == null) return const SizedBox.shrink();
    final math = GroupMath(g);
    final held = math.heldValueOf(widget.companyId);
    final own = math.capById[widget.companyId];
    final heldRatio = math.heldRatioOf(widget.companyId);
    final parts = <String>[
      '${g.anchor.name} 묶음 ${g.members.length}개사',
      if (held != null)
        '묶음 안 상장 지분 가치 ${formatKrwShort(held)}'
            '${own == null ? '' : ' (시총의 ${(held / own * 100).toStringAsFixed(0)}%)'}',
      if (heldRatio != null) '묶음 안 기업이 가진 지분 ${heldRatio.toStringAsFixed(1)}%',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('지분 묶음', style: t.label(color: c.textSecondary)),
          Text(parts.join(' · '), style: t.numeric(12.5, color: c.textPrimary)),
          AppButton(
            label: '묶음 보기 →',
            variant: AppButtonVariant.link,
            tone: c.accent,
            onPressed: () => context.push(AppRoutes.group(widget.corpCode)),
          ),
        ],
      ),
    );
  }
}
