import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../market_map/market_cap_treemap_section.dart';
import 'widgets/company_card.dart';
import 'widgets/company_table.dart';
import 'widgets/data_sync_panel.dart';
import 'widgets/industry_distribution.dart';
import 'widgets/ingest_status_bar.dart';
import 'widgets/market_summary.dart';

/// 상장사 원장: 시장·업종 분포 + 검색 가능한 전체 상장사 목록 + 기업 상세.
class CompanyLedgerPage extends StatefulWidget {
  const CompanyLedgerPage({super.key});

  @override
  State<CompanyLedgerPage> createState() => _CompanyLedgerPageState();
}

class _CompanyLedgerPageState extends State<CompanyLedgerPage> {
  static const _pageSize = 50;
  static const _wideBreakpoint = 1180.0;
  static const _detailWidth = 440.0;

  Overview? _overview;
  List<FacetCount> _divisions = const [];
  CompanyPage? _page;
  String? _error;
  bool _loadingPage = false;

  Market? _market;
  String? _section;
  String? _division;
  CompanySort _sort = CompanySort.name;
  String _query = '';
  int _offset = 0;
  String? _selected;

  /// 재무·시세 수집이 끝날 때마다 올려 트리맵·기업 카드를 다시 불러온다.
  int _dataVersion = 0;

  final _searchController = TextEditingController();
  Timer? _debounce;

  /// 늦게 도착한 이전 요청 결과를 버리기 위한 번호.
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadOverview(), _loadPage(), _loadDivisions()]);
  }

  Future<void> _loadOverview() async {
    try {
      final o = await client.company.overview();
      if (mounted) setState(() => _overview = o);
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
      // 목록 쪽 오류 표시로 충분하다.
    }
  }

  Future<void> _loadPage() async {
    final seq = ++_requestSeq;
    setState(() => _loadingPage = true);
    try {
      final page = await client.company.list(
        query: _query.isEmpty ? null : _query,
        market: _market,
        sectionCode: _section,
        divisionCode: _division,
        sort: _sort,
        offset: _offset,
        limit: _pageSize,
      );
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _page = page;
        _error = null;
      });
    } catch (e) {
      if (mounted && seq == _requestSeq) setState(() => _error = '$e');
    } finally {
      if (mounted && seq == _requestSeq) setState(() => _loadingPage = false);
    }
  }

  /// 필터를 바꾸고 첫 페이지부터 다시 불러온다.
  void _applyFilter(VoidCallback change, {bool reloadDivisions = false}) {
    setState(() {
      change();
      _offset = 0;
    });
    _loadPage();
    if (reloadDivisions) _loadDivisions();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (value.trim() == _query) return;
      _applyFilter(() => _query = value.trim());
    });
  }

  void _clearFilters() {
    _searchController.clear();
    _applyFilter(() {
      _market = null;
      _section = null;
      _division = null;
      _divisions = const [];
      _query = '';
    });
  }

  void _openCompany(String corpCode, {required bool wide}) {
    if (wide) {
      setState(() => _selected = corpCode);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          backgroundColor: routeContext.colors.surface,
          body: SafeArea(
            child: CompanyCard(
              corpCode: corpCode,
              onClose: () => Navigator.of(routeContext).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          final main = _buildMain(context, wide: wide);
          if (!wide) return main;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: main),
              _buildDetailPane(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final c = context.colors;
    final selected = _selected;
    return AnimatedContainer(
      duration: AppMotion.slow,
      curve: AppMotion.curve,
      width: selected == null ? 0 : _detailWidth,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(left: BorderSide(color: c.borderStrong, width: 1.5)),
      ),
      child: selected == null
          ? const SizedBox.shrink()
          : ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: _detailWidth,
                maxWidth: _detailWidth,
                child: CompanyCard(
                  key: ValueKey('$selected-$_dataVersion'),
                  corpCode: selected,
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            ),
    );
  }

  Widget _buildMain(BuildContext context, {required bool wide}) {
    final overview = _overview;
    final hPad = wide ? AppSpace.section : AppSpace.xl - 4;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 36, hPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IngestStatusBar(
                  lastJob: overview?.lastJob,
                  nextFullRefreshAt: overview?.nextFullRefreshAt,
                  onFinished: _refreshAll,
                ),
                DataSyncPanel(
                  onFinished: () async => setState(() => _dataVersion++),
                ),
                const SizedBox(height: 28),
                MarketSummary(
                  overview: overview,
                  selected: _market,
                  onSelect: (m) => _applyFilter(
                    () => _market = _market == m ? null : m,
                    reloadDivisions: true,
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                if (overview != null && overview.bySection.isNotEmpty)
                  IndustryDistribution(
                    revision: overview.industryRevision,
                    sections: overview.bySection,
                    divisions: _divisions,
                    selectedSection: _section,
                    selectedDivision: _division,
                    onSelectSection: (code) => _applyFilter(() {
                      _section = _section == code ? null : code;
                      _division = null;
                      _divisions = const [];
                    }, reloadDivisions: true),
                    onSelectDivision: (code) => _applyFilter(
                      () => _division = _division == code ? null : code,
                    ),
                  ),
                const SizedBox(height: AppSpace.xxl),
                MarketCapTreemapSection(
                  key: ValueKey('treemap-$_dataVersion'),
                  market: _market,
                  onSelectCompany: (corpCode) =>
                      _openCompany(corpCode, wide: wide),
                ),
                const SizedBox(height: 28),
                _buildToolbar(),
                const SizedBox(height: AppSpace.md),
                if (_error != null) ...[
                  AppNotice(message: '서버에 연결하지 못했습니다 — $_error'),
                  const SizedBox(height: AppSpace.md),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpace.section),
          sliver: SliverToBoxAdapter(
            child: CompanyTable(
              page: _page,
              loading: _loadingPage,
              compact: !wide,
              selected: _selected,
              offset: _offset,
              pageSize: _pageSize,
              onSelect: (corpCode) => _openCompany(corpCode, wide: wide),
              onPage: (offset) {
                setState(() => _offset = offset);
                _loadPage();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final hasFilter = _market != null || _section != null || _query.isNotEmpty;
    return Wrap(
      spacing: AppSpace.lg,
      runSpacing: AppSpace.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: context.typo.body(15),
            decoration: InputDecoration(
              hintText: '회사명 · 종목코드 · 대표자',
              prefixIcon: Icon(
                Icons.search,
                color: context.colors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        AppToggleGroup<CompanySort>(
          label: '정렬',
          value: _sort,
          options: const {
            CompanySort.name: '가나다',
            CompanySort.stockCode: '종목코드',
            CompanySort.establishedDate: '설립 오래된',
          },
          onChanged: (s) => _applyFilter(() => _sort = s),
        ),
        if (hasFilter)
          AppButton(
            label: '필터 초기화',
            icon: Icons.close,
            variant: AppButtonVariant.link,
            tone: context.colors.accent,
            onPressed: _clearFilters,
          ),
      ],
    );
  }
}
