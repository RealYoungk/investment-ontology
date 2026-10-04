import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import '../companies/company_filter.dart';
import '../financials/financial_metrics.dart';
import 'market_cap_treemap_section.dart';
import 'market_load_notice.dart';
import 'widgets/index_trend.dart';
import '../macro/macro_snapshot.dart';
import 'widgets/industry_distribution.dart';
import 'widgets/market_cap_trend.dart';
import 'widgets/market_summary.dart';
import 'widgets/new_companies.dart';
import '../monetization/ad_content_state.dart';

/// 시장: 시장별 상장사 수 · 업종 분포 · 업종별 시가총액 트리맵. 탐색의 시작점.
///
/// 업종 분포에서 중분류를 누르면 그 업종의 기업 목록으로, 트리맵에서 기업을 누르면
/// 기업 상세로 간다.
class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  Overview? _overview;
  bool _failed = false;
  bool _loadingOverview = false;
  Market? _market;
  String? _section;
  List<FacetCount> _divisions = const [];

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_reload);
    _loadOverview();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    _loadOverview();
    _loadDivisions();
  }

  Future<void> _loadOverview() async {
    if (_loadingOverview) return;
    _loadingOverview = true;
    setState(() => _failed = false);
    try {
      final o = await client.company.overview();
      if (mounted) setState(() => (_overview = o, _failed = false));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loadingOverview = false);
    }
  }

  Future<void> _loadDivisions() async {
    final section = _section;
    final market = _market;
    if (section == null) {
      setState(() => _divisions = const []);
      return;
    }
    try {
      final d = await client.company.divisions(section, market: market);
      if (mounted && section == _section && market == _market) {
        setState(() => _divisions = d);
      }
    } catch (_) {
      // 대분류 분포는 그대로 보여준다.
    }
  }

  void _openCompanies({String? division}) => context.go(
    CompanyFilter(
      market: _market,
      section: _section,
      division: division,
    ).location,
  );

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final sectionName = overview?.bySection
        .where((s) => s.code == _section)
        .firstOrNull
        ?.name;
    return PageFrame(
      allowLeading: AdContentState(
        // Existing summary remains publisher content during background refresh.
        loading: _loadingOverview,
        contentRemainsVisible: overview != null,
        failed: _failed,
        itemCount: overview?.totalListed ?? 0,
      ).allowsAd,
      children: [
        const PageHeading(title: '시장'),
        const SizedBox(height: AppSpace.lg),
        ValueListenableBuilder<int>(
          valueListenable: IngestMonitor.instance.dataVersion,
          builder: (context, version, _) =>
              NewCompanies(key: ValueKey(version)),
        ),
        if (_failed) ...[
          const SizedBox(height: AppSpace.lg),
          MarketLoadNotice(subject: '시장 정보', retry: _loadOverview),
        ],
        const SizedBox(height: AppSpace.section),
        DataPanel(
          child: ValueListenableBuilder<int>(
            valueListenable: IngestMonitor.instance.dataVersion,
            builder: (context, version, _) =>
                IndexTrend(key: ValueKey('index-trend-$version')),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        const MacroSnapshot(),
        const SizedBox(height: AppSpace.section),
        ValueListenableBuilder<int>(
          valueListenable: IngestMonitor.instance.dataVersion,
          builder: (context, version, _) => DataPanel(
            child: MarketCapTrend(
              key: ValueKey('cap-trend-$version'),
              market: _market,
              controls: MarketSummary(
                showHeading: false,
                showScopeNote: false,
                alignment: WrapAlignment.end,
                overview: overview,
                failed: _failed,
                selected: _market,
                onSelect: (m) {
                  setState(() => _market = m);
                  _loadDivisions();
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        _RecentFilings(market: _market),
        const SizedBox(height: AppSpace.section),
        ValueListenableBuilder<int>(
          valueListenable: IngestMonitor.instance.dataVersion,
          builder: (context, version, _) => DataPanel(
            child: MarketCapTreemapSection(
              dataVersion: version,
              market: _market,
              onSelectCompany: (corpCode) =>
                  context.push(AppRoutes.company(corpCode)),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        if (overview != null && overview.bySection.isNotEmpty) ...[
          DataPanel(
            child: IndustryDistribution(
              revision: overview.industryRevision,
              sections: overview.bySection,
              divisions: _divisions,
              selectedSection: _section,
              selectedDivision: null,
              onSelectSection: (code) {
                setState(() {
                  _section = _section == code ? null : code;
                  _divisions = const [];
                });
                _loadDivisions();
              },
              onSelectDivision: (code) => _openCompanies(division: code),
            ),
          ),
          if (_section != null) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.raw(
                onPressed: _openCompanies,

                variant: ShadButtonVariant.link,
                foregroundColor: context.colors.accent,
                child: Flexible(
                  child: Text('$_section ${sectionName ?? ''} 기업 목록 →'),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// 최근 올라온 정기보고서. 새 공시부터 기업으로 들어가는 길.
class _RecentFilings extends StatefulWidget {
  const _RecentFilings({required this.market});

  final Market? market;

  @override
  State<_RecentFilings> createState() => _RecentFilingsState();
}

class _RecentFilingsState extends State<_RecentFilings> {
  List<FilingFeedItem>? _items;
  int _sequence = 0;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant _RecentFilings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.market != widget.market) _load();
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final sequence = ++_sequence;
    setState(() => _items = null);
    try {
      final items = await client.disclosure.recentFilings(
        market: widget.market,
        limit: 12,
      );
      if (mounted && sequence == _sequence) setState(() => _items = items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final items = _items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return DataPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            '최근 정기보고서',
            accent: true,
            trailing: Text(
              '사업·반기·분기보고서 · 접수일 순',
              style: t.body(12, color: c.textMuted),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              // 좁은 화면에서는 접수일·보고서를 기업 이름 아래로 접는다.
              final compact = constraints.maxWidth < 700;
              Widget name(FilingFeedItem f) => HoverBuilder(
                onTap: () =>
                    context.push(AppRoutes.company(f.company.corpCode)),
                builder: (context, hovered) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t
                          .body(13.5, color: c.accent, weight: FontWeight.w600)
                          .copyWith(
                            decoration: hovered
                                ? TextDecoration.underline
                                : null,
                            decorationColor: c.accent,
                          ),
                    ),
                    if (compact)
                      Text(
                        '${formatDate(f.receivedDate)} · ${f.reportName}'
                        '${f.marketCap == null ? '' : ' · ${formatKrw(f.marketCap)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.body(11.5, color: c.textSecondary),
                      ),
                  ],
                ),
              );
              // 열이 몇 개 없어 왼쪽에 몰려 보이지 않게 폭을 다 쓴다 (기업·보고서 열이 남는 폭을 가져간다).
              return AppDataTable(
                expand: true,
                columns: [
                  // 날짜는 고정 폭 — 내용 폭 재기가 몇 px 모자라 끝 글자가 잘린다.
                  if (!compact) const AppColumn('접수일', width: 100),
                  const AppColumn('기업', flex: true),
                  if (!compact)
                    const AppColumn('보고서', flex: true, nowrap: true),
                  if (!compact)
                    const AppColumn('시가총액', numeric: true, nowrap: true),
                  const AppColumn('재무'),
                ],
                rows: [
                  for (final f in items)
                    AppRow([
                      if (!compact)
                        AppDataTable.text(
                          context,
                          formatDate(f.receivedDate),
                          nowrap: true,
                        ),
                      name(f),
                      if (!compact) AppDataTable.text(context, f.reportName),
                      if (!compact)
                        AppDataTable.text(
                          context,
                          f.marketCap == null
                              ? null
                              : formatKrwShort(f.marketCap!.toDouble()),
                          numeric: true,
                        ),
                      ShadBadge.raw(
                        variant: ShadBadgeVariant.outline,
                        foregroundColor: f.financialStored
                            ? c.success
                            : c.textMuted,
                        child: Text(
                          f.financialStored ? '받음' : '대기',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
