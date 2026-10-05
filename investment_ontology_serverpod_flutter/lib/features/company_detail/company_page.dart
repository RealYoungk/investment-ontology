import '../shareholder_rights/shareholder_rights_card.dart';
import '../research/research_section.dart';

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
import '../financials/financial_section.dart';
import '../governance/governance_tab.dart';
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
/// 개요는 사업 이해와 사업 지표를 담당한다. 탭은 데이터가 생기는 단계마다 늘린다
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
  CompanyDetail? _detail;
  CompanyFinancials? _financials;
  List<DisclosureSectionInfo> _sections = const [];
  Object? _error;
  bool _loaded = false;

  /// 새 데이터를 불러올 때마다 올려 재무 탭을 새 값으로 다시 만든다.
  int _version = 0;
  int _loadSequence = 0;
  FsDiv? _fsDiv;
  bool _changingBasis = false;
  String? _basisError;

  Future<void> _changeBasis(FsDiv? div) async {
    final sequence = ++_loadSequence;
    final previousBasis = _financials?.basisReason == 'manual'
        ? _financials?.fsDiv
        : null;
    setState(() {
      _fsDiv = div;
      _changingBasis = true;
      _basisError = null;
    });
    try {
      final financials = await client.financial.summary(
        widget.corpCode,
        fsDiv: div,
      );
      if (!mounted || sequence != _loadSequence) return;
      if (financials == null ||
          (div != null &&
              (financials.fsDiv != div ||
                  !financials.availableFsDivs.contains(div)))) {
        throw StateError('Requested financial basis unavailable');
      }
      setState(() {
        _financials = financials;
        _fsDiv = div;
        _changingBasis = false;
        _version++;
      });
    } catch (_) {
      if (!mounted || sequence != _loadSequence) return;
      setState(() {
        _changingBasis = false;
        _fsDiv = previousBasis;
        _basisError = '재무 기준을 바꾸지 못했습니다. 다시 선택해 주세요.';
      });
    }
  }

  @override
  void didUpdateWidget(covariant CompanyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) {
      _detail = null;
      _financials = null;
      _sections = const [];
      _error = null;
      _loaded = false;
      _fsDiv = null;
      _changingBasis = false;
      _basisError = null;
      _load();
    }
  }

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
    final sequence = ++_loadSequence;
    try {
      final (detail, financials, sections) = await (
        client.company.detail(widget.corpCode),
        client.financial.summary(widget.corpCode, fsDiv: _fsDiv),
        client.disclosure.sections(widget.corpCode),
      ).wait;
      if (!mounted || sequence != _loadSequence) return;
      setState(() {
        _changingBasis = false;
        _basisError = null;
        _detail = detail;
        _financials = financials;
        _sections = sections;
        _error = null;
        _loaded = true;
        _version++;
      });
    } catch (e) {
      final error = e is ParallelWaitError ? e.errors : e;
      if (mounted && sequence == _loadSequence) {
        setState(() {
          _error = error;
          _loaded = true;
          _changingBasis = false;
          _fsDiv = _financials?.basisReason == 'manual'
              ? _financials?.fsDiv
              : null;
        });
      }
    }
  }

  bool _has(Set<DartSection> wanted) =>
      _sections.any((s) => wanted.contains(s.section));

  /// 데이터가 있는 탭만.
  Map<CompanyTab, String> get _tabs => {
    CompanyTab.overview: '개요',
    CompanyTab.financials: '재무',
    if (_has(_governanceSections)) CompanyTab.governance: '지배구조',
    if (_has(_returnSections)) CompanyTab.returns: '주주환원',
    CompanyTab.disclosures: '공시',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final detail = _detail;
    final tabs = _tabs;
    final tab = tabs.containsKey(widget.initialTab)
        ? widget.initialTab
        : CompanyTab.overview;

    return ExpansionTileTheme(
      data: ExpansionTileThemeData(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        childrenPadding: const EdgeInsets.all(AppSpace.md),
        textColor: c.textSecondary,
        collapsedTextColor: c.textSecondary,
        iconColor: c.textSecondary,
        collapsedIconColor: c.textSecondary,
        shape: Border(bottom: BorderSide(color: c.border)),
        collapsedShape: Border(bottom: BorderSide(color: c.border)),
      ),
      child: PageFrame(
        children: [
          if (!_loaded)
            const ShadProgress(minHeight: 2)
          else if (detail == null)
            (_error != null
                ? ReadFailureNotice(subject: '상세 정보', retry: _load)
                : Text(
                    '기업을 찾을 수 없습니다.',
                    style: t.body(14, color: c.textSecondary),
                  ))
          else ...[
            CompanyHeader(
              detail: detail,
              onCompare: () =>
                  context.push(AppRoutes.compare([widget.corpCode])),
              financials: _financials,
              onBasisChanged: _changeBasis,
              changingBasis: _changingBasis,
              selectedBasis: _fsDiv,
              basisError: _basisError,
            ),
            const SizedBox(height: AppSpace.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTabBar<CompanyTab>(
                tabs: tabs,
                value: tab,
                onChanged: (tab) => Router.neglect(
                  context,
                  () => context.replace(
                    AppRoutes.company(
                      widget.corpCode,
                      tab: tab == CompanyTab.overview ? null : tab.name,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            switch (tab) {
              CompanyTab.overview => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CompanyOverviewTab(
                    key: ValueKey(_version),
                    detail: detail,
                    latestReport: _financials?.periods.lastOrNull,
                    dataVersion: _version,
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
              CompanyTab.governance => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShareholderRightsCard(
                    key: ValueKey('rights-governance-$_version'),
                    corpCode: widget.corpCode,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  GovernanceTab(
                    key: ValueKey('governance-$_version'),
                    corpCode: widget.corpCode,
                    companyName: detail.company.name,
                  ),
                ],
              ),
              CompanyTab.returns => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShareholderReturnTab(
                    key: ValueKey('returns-$_version'),
                    corpCode: widget.corpCode,
                  ),
                ],
              ),
              CompanyTab.disclosures => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResearchSection(
                    corpCode: widget.corpCode,
                    kinds: const [
                      'capital',
                      'treasury',
                      'insiders',
                      'majorHoldings',
                    ],
                  ),
                ],
              ),
              CompanyTab.business => BusinessTab(
                key: const ValueKey('business'),
                dataVersion: _version,
                corpCode: widget.corpCode,
              ),
              CompanyTab.financials => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FinancialSection(
                    industryCode: detail.company.industryCode,
                    companyName: detail.company.name,
                    key: const ValueKey('financials'),
                    dataVersion: _version,
                    corpCode: widget.corpCode,
                    initialData: _financials,
                    showBasisSelector: false,
                  ),
                ],
              ),
            },
          ],
        ],
      ),
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
    return DataPanel(
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
          ShadButton.raw(
            onPressed: _fetching ? null : _fetch,
            enabled: (_fetching ? null : _fetch) != null,
            variant: ShadButtonVariant.outline,
            child: Flexible(
              child: Text(_fetching ? '받는 중…' : '이 기업 주요정보 지금 받기'),
            ),
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
