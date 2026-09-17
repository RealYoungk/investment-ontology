import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../theme/ledger_theme.dart';
import 'company_detail_panel.dart';
import 'company_table.dart';
import 'market_header.dart';
import 'section_strip.dart';
import 'sync_bar.dart';

/// 상장사 원장: 시장·업종 분포 + 검색 가능한 전체 상장사 목록 + 기업 상세.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  static const _pageSize = 50;

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

  final _searchController = TextEditingController();
  Timer? _debounce;
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

  void _update(VoidCallback change, {bool divisions = false}) {
    setState(() {
      change();
      _offset = 0;
    });
    _loadPage();
    if (divisions) _loadDivisions();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (value.trim() == _query) return;
      _update(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          final list = _buildMain(context, wide: wide);
          if (!wide) return list;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: list),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: _selected == null ? 0 : 440,
                decoration: const BoxDecoration(
                  color: Pal.card,
                  border: Border(left: BorderSide(color: Pal.ink, width: 1.5)),
                ),
                child: _selected == null
                    ? const SizedBox.shrink()
                    : ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: 440,
                          maxWidth: 440,
                          child: CompanyDetailPanel(
                            key: ValueKey(_selected),
                            corpCode: _selected!,
                            onClose: () => setState(() => _selected = null),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMain(BuildContext context, {required bool wide}) {
    final overview = _overview;
    final hPad = wide ? 48.0 : 20.0;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 36, hPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SyncBar(
                  lastJob: overview?.lastJob,
                  onFinished: _refreshAll,
                ),
                const SizedBox(height: 28),
                MarketHeader(
                  overview: overview,
                  selected: _market,
                  onSelect: (m) => _update(
                    () => _market = _market == m ? null : m,
                    divisions: true,
                  ),
                ),
                const SizedBox(height: 32),
                if (overview != null && overview.bySection.isNotEmpty)
                  SectionStrip(
                    sections: overview.bySection,
                    divisions: _divisions,
                    selectedSection: _section,
                    selectedDivision: _division,
                    onSelectSection: (code) => _update(() {
                      _section = _section == code ? null : code;
                      _division = null;
                      _divisions = const [];
                    }, divisions: true),
                    onSelectDivision: (code) => _update(
                      () => _division = _division == code ? null : code,
                    ),
                  ),
                const SizedBox(height: 28),
                _buildToolbar(),
                const SizedBox(height: 12),
                if (_error != null) _ErrorNote(message: _error!),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 48),
          sliver: SliverToBoxAdapter(
            child: CompanyTable(
              page: _page,
              loading: _loadingPage,
              compact: !wide,
              selected: _selected,
              offset: _offset,
              pageSize: _pageSize,
              onSelect: (corpCode) {
                if (wide) {
                  setState(() => _selected = corpCode);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        backgroundColor: Pal.card,
                        body: SafeArea(
                          child: CompanyDetailPanel(
                            corpCode: corpCode,
                            onClose: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
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
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: Typo.body(15),
            decoration: const InputDecoration(
              hintText: '회사명 · 종목코드 · 대표자',
              prefixIcon: Icon(Icons.search, color: Pal.ink, size: 20),
            ),
          ),
        ),
        _SortSwitch(
          value: _sort,
          onChanged: (s) => _update(() => _sort = s),
        ),
        if (_market != null || _section != null || _query.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              _update(() {
                _market = null;
                _section = null;
                _division = null;
                _divisions = const [];
                _query = '';
              });
            },
            icon: const Icon(Icons.close, size: 16, color: Pal.seal),
            label: Text('필터 초기화', style: Typo.body(13, color: Pal.seal)),
          ),
      ],
    );
  }
}

class _SortSwitch extends StatelessWidget {
  const _SortSwitch({required this.value, required this.onChanged});

  final CompanySort value;
  final ValueChanged<CompanySort> onChanged;

  static const _labels = {
    CompanySort.name: '가나다',
    CompanySort.stockCode: '종목코드',
    CompanySort.establishedDate: '설립 오래된',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('정렬', style: Typo.label()),
        const SizedBox(width: 10),
        for (final entry in _labels.entries)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _Toggle(
              label: entry.value,
              active: entry.key == value,
              onTap: () => onChanged(entry.key),
            ),
          ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? Pal.ink : Colors.transparent,
            border: Border.all(color: Pal.ink, width: 1.2),
          ),
          child: Text(
            label,
            style: Typo.body(
              13,
              color: active ? Pal.paper : Pal.ink,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Pal.sealSoft,
        border: Border(left: BorderSide(color: Pal.seal, width: 4)),
      ),
      child: Text(
        '서버에 연결하지 못했습니다 — $message',
        style: Typo.body(13, color: Pal.ink),
      ),
    );
  }
}
