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
import 'widgets/industry_distribution.dart';
import 'widgets/market_summary.dart';

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
  String? _error;
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
    try {
      final o = await client.company.overview();
      if (mounted) setState(() => (_overview = o, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _loadDivisions() async {
    final section = _section;
    if (section == null) {
      setState(() => _divisions = const []);
      return;
    }
    try {
      final d = await client.company.divisions(section, market: _market);
      if (mounted && section == _section) setState(() => _divisions = d);
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
      children: [
        MarketSummary(
          overview: overview,
          selected: _market,
          onSelect: (m) {
            setState(() => _market = _market == m ? null : m);
            _loadDivisions();
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.lg),
          AppNotice(message: '서버에 연결하지 못했습니다 — $_error'),
        ],
        const SizedBox(height: AppSpace.section),
        _RecentFilings(market: _market),
        const SizedBox(height: AppSpace.section),
        ValueListenableBuilder<int>(
          valueListenable: IngestMonitor.instance.dataVersion,
          builder: (context, version, _) => MarketCapTreemapSection(
            key: ValueKey('treemap-$version'),
            market: _market,
            onSelectCompany: (corpCode) =>
                context.push(AppRoutes.company(corpCode)),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        if (overview != null && overview.bySection.isNotEmpty) ...[
          IndustryDistribution(
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
          if (_section != null) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: '$_section ${sectionName ?? ''} 기업 목록 →',
                variant: AppButtonVariant.link,
                tone: context.colors.accent,
                onPressed: _openCompanies,
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
    try {
      final items = await client.disclosure.recentFilings(
        market: widget.market,
        limit: 12,
      );
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final items = _items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
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
              onTap: () => context.push(AppRoutes.company(f.company.corpCode)),
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
                          decoration: hovered ? TextDecoration.underline : null,
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
            return AppDataTable(
              columns: [
                if (!compact) const AppColumn('접수일'),
                const AppColumn('기업'),
                if (!compact) const AppColumn('보고서'),
                if (!compact) const AppColumn('시가총액', numeric: true),
                const AppColumn('재무'),
              ],
              rows: [
                for (final f in items)
                  AppRow([
                    if (!compact)
                      AppDataTable.text(context, formatDate(f.receivedDate)),
                    name(f),
                    if (!compact) AppDataTable.text(context, f.reportName),
                    if (!compact)
                      AppDataTable.text(
                        context,
                        f.marketCap == null ? null : formatKrw(f.marketCap),
                        numeric: true,
                      ),
                    AppTag(
                      label: f.financialStored ? '받음' : '대기',
                      color: f.financialStored ? c.success : c.textMuted,
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
