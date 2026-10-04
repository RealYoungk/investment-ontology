import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/ingest_monitor.dart';
import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../common/formatters.dart';
import 'company_filter.dart';
import 'widgets/company_table.dart';
import '../monetization/ad_content_state.dart';

/// 기업: 검색 · 시장 · 업종 필터 · 정렬 + 상장사 목록. 필터는 주소에 남는다.
class CompanyListPage extends StatefulWidget {
  const CompanyListPage({super.key, required this.filter});

  final CompanyFilter filter;

  @override
  State<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  static const _pageSize = 20;

  Overview? _overview;
  List<FacetCount> _divisions = const [];
  CompanyPage? _page;
  String? _error;
  bool _loading = false;

  late final _searchController = TextEditingController(
    text: widget.filter.query,
  );
  final _searchFocus = FocusNode();
  Timer? _debounce;

  /// 늦게 도착한 이전 요청 결과를 버리기 위한 번호.
  int _requestSeq = 0;

  CompanyFilter get _filter => widget.filter;
  int get _offset => (_filter.page - 1) * _pageSize;

  @override
  void initState() {
    super.initState();
    IngestMonitor.instance.dataVersion.addListener(_reloadAll);
    _reloadAll();
  }

  @override
  void didUpdateWidget(covariant CompanyListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.filter, now = widget.filter;
    if (before == now) return;
    // 뒤로가기 등으로 주소가 바뀌었을 때 검색창도 맞춘다 (입력 중이면 건드리지 않는다).
    if (!_searchFocus.hasFocus && _searchController.text != now.query) {
      _searchController.text = now.query;
    }
    _loadPage();
    if (before.section != now.section || before.market != now.market) {
      _loadDivisions();
    }
  }

  @override
  void dispose() {
    IngestMonitor.instance.dataVersion.removeListener(_reloadAll);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _reloadAll() {
    _loadOverview();
    _loadPage();
    _loadDivisions();
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
    final section = _filter.section;
    if (section == null) {
      setState(() => _divisions = const []);
      return;
    }
    try {
      final d = await client.company.divisions(section, market: _filter.market);
      if (mounted && section == _filter.section) {
        setState(() => _divisions = d);
      }
    } catch (_) {
      // 목록 쪽 오류 표시로 충분하다.
    }
  }

  Future<void> _loadPage() async {
    final seq = ++_requestSeq;
    final f = _filter;
    setState(() => _loading = true);
    try {
      final page = await client.company.list(
        query: f.query.isEmpty ? null : f.query,
        market: f.market,
        sectionCode: f.section,
        divisionCode: f.division,
        sort: f.sort,
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
      if (mounted && seq == _requestSeq) setState(() => _loading = false);
    }
  }

  /// 필터를 주소에 반영한다. 필터를 바꿀 때마다 방문 기록이 쌓이지 않게 한다.
  void _apply(CompanyFilter next) {
    if (next == _filter) return;
    Router.neglect(context, () => context.go(next.location));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || value.trim() == _filter.query) return;
      _apply(_filter.copyWith(query: value.trim()));
    });
  }

  void _clearFilters() {
    _searchController.clear();
    _apply(CompanyFilter(sort: _filter.sort));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        return PageFrame(
          allowLeading: AdContentState(
            // The table keeps actual rows visible during a background refresh.
            // Keep the existing slot; do not turn refresh into another ad request.
            loading: _loading,
            contentRemainsVisible: _page != null,
            failed: _error != null,
            itemCount: _page?.items.length ?? 0,
          ).allowsAd,
          children: [
            const PageHeading(title: '기업'),
            const SizedBox(height: AppSpace.xl),
            DataPanel(child: _buildToolbar(context)),
            const SizedBox(height: AppSpace.md),
            if (_error != null) ...[
              ReadFailureNotice(
                subject: '기업 목록',
                retry: () async {
                  await _loadOverview();
                  await _loadPage();
                },
              ),
              const SizedBox(height: AppSpace.md),
            ],
            CompanyTable(
              page: _page,
              loading: _loading,
              compact: compact,
              selected: null,
              sort: _filter.sort,
              onSort: (sort) => _apply(_filter.copyWith(sort: sort)),
              offset: _offset,
              pageSize: _pageSize,
              onSelect: (corpCode) => context.push(AppRoutes.company(corpCode)),
              onPage: (offset) =>
                  _apply(_filter.copyWith(page: offset ~/ _pageSize + 1)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final f = _filter;
    final sections = _overview?.bySection ?? const <FacetCount>[];
    Widget group(String label, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typo.label(color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.sm),
        child,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ShadInput(
                placeholder: const Text('회사명 · 종목코드 · 대표자'),
                leading: const Icon(LucideIcons.search, size: 20),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: context.typo.body(15),
              ),
            ),
            if (f.hasFilter)
              ShadButton.ghost(
                onPressed: _clearFilters,
                leading: const Icon(LucideIcons.x, size: 16),
                child: const Text('필터 초기화'),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.xl,
          runSpacing: AppSpace.lg,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            group(
              '시장',
              AppToggleGroup<Market?>(
                value: f.market,
                options: const {
                  null: '전체',
                  Market.kospi: 'KOSPI',
                  Market.kosdaq: 'KOSDAQ',
                  Market.konex: 'KONEX',
                },
                onChanged: (m) => _apply(f.copyWith(market: () => m)),
              ),
            ),
            group(
              '업종',
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  AppSelect<String>(
                    placeholder: '대분류 전체',
                    allLabel: '대분류 전체',
                    value: f.section,
                    options: {
                      for (final s in sections)
                        s.code: '${s.code} ${s.name} (${formatCount(s.count)})',
                    },
                    onChanged: (code) =>
                        _apply(f.copyWith(section: () => code)),
                  ),
                  if (f.section != null)
                    AppSelect<String>(
                      placeholder: '중분류 전체',
                      allLabel: '중분류 전체',
                      value: f.division,
                      options: {
                        for (final d in _divisions)
                          d.code:
                              '${d.code} ${d.name} (${formatCount(d.count)})',
                      },
                      onChanged: (code) =>
                          _apply(f.copyWith(division: () => code)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
