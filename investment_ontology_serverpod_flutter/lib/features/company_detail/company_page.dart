import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../disclosures/disclosure_tab.dart';
import '../financials/financial_section.dart';
import '../governance/governance_tab.dart';
import '../shareholder_return/shareholder_return_tab.dart';
import 'widgets/company_header.dart';
import 'widgets/company_overview_tab.dart';

enum CompanyTab { overview, financials, governance, returns, disclosures }

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

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/companies');
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
    if (_sections.isNotEmpty) CompanyTab.disclosures: '공시 항목',
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
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: '← 뒤로',
            variant: AppButtonVariant.link,
            onPressed: _back,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
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
          const SizedBox(height: AppSpace.xl),
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
              key: ValueKey('disclosures-$_version'),
              corpCode: widget.corpCode,
              sections: _sections,
            ),
            CompanyTab.financials => FinancialSection(
              key: ValueKey('financials-$_version'),
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
