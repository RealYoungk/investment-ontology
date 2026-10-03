import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../companies/company_filter.dart';
import 'explore_intent.dart';
import 'journey_widgets.dart';
import 'daily_brief.dart';
import 'market_pulse.dart';
import 'home_dashboard.dart';

typedef CompanySearch = Future<List<CompanyListItem>> Function(String query);

Future<List<CompanyListItem>> _findCompanies(String query) async =>
    (await client.company.list(
      query: query,
      sort: CompanySort.marketCap,
      limit: 6,
    )).items;

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.intent = ExploreIntent.overview,
    this.search,
    this.filings,
    this.market,
    this.macro,
  });
  final ExploreIntent intent;
  final CompanySearch? search;
  final FilingFeedLoad? filings;
  final MarketPulseLoad? market;
  final Future<List<MacroSeriesView>> Function()? macro;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _searchKey = GlobalKey();
  Timer? _debounce;
  int _request = 0;
  List<CompanyListItem> _items = [];
  bool _loading = false;
  bool _failed = false;
  bool _searched = false;
  late ExploreIntent _intent = widget.intent;

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent) _intent = widget.intent;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String value, {bool immediate = false}) {
    _debounce?.cancel();
    final request = ++_request;
    final query = value.trim();
    setState(() {
      _items = [];
      _failed = false;
      _searched = query.isNotEmpty;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    Future<void> run() async {
      try {
        final items = await (widget.search ?? _findCompanies)(query);
        if (!mounted || request != _request) return;
        setState(() {
          _items = items;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }

    if (immediate) {
      unawaited(run());
    } else {
      _debounce = Timer(const Duration(milliseconds: 250), run);
    }
  }

  void _example(String name) {
    _query.text = name;
    _search(name, immediate: true);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final search = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '종목 발굴',
          key: _searchKey,
          style: t.display(20),
        ),
        const SizedBox(height: AppSpace.lg),
        ShadInput(
          placeholder: Text('예: 삼성전자, 005930'),
          leading: Icon(LucideIcons.search, size: 20, color: c.textSecondary),
          trailing: _query.text.isEmpty
              ? const SizedBox(width: 24, height: 24)
              : Semantics(
                  container: true,
                  label: '검색어 지우기',
                  button: true,
                  enabled: true,
                  onTap: () {
                    _query.clear();
                    _search('');
                    _focus.requestFocus();
                  },
                  child: ExcludeSemantics(
                    child: ShadIconButton.ghost(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _query.clear();
                        _search('');
                        _focus.requestFocus();
                      },
                      semanticLabel: '검색어 지우기',
                    ),
                  ),
                ),
          key: const ValueKey('home-company-search'),
          controller: _query,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          style: t.body(16),
          onChanged: _search,
          onSubmitted: (value) => _search(value, immediate: true),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          _intent == ExploreIntent.overview
              ? '성장·수익성·배당 조건으로 투자 후보를 살펴보세요.'
              : '${_intent.label} · ${_intent.description}',
          style: t.body(13, color: c.textSecondary),
        ),
        if (_searched) ...[
          const SizedBox(height: AppSpace.lg),
          _results(context),
        ] else ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('검색 예시', style: t.body(12, color: c.textSecondary)),
              for (final name in ['삼성전자', '현대자동차', 'NAVER'])
                ShadButton.ghost(
                  onPressed: () => _example(name),
                  child: Flexible(child: Text(name)),
                ),
            ],
          ),
        ],
      ],
    );
    return HomeDashboard(
      search: search,
      market: widget.market,
      filings: widget.filings,
      macro: widget.macro,
    );
  }

  Widget _results(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (_loading) {
      return Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const ExcludeSemantics(child: ShadSpinner(size: 16)),
            const SizedBox(width: AppSpace.sm),
            Text('검색 중…', style: t.body(14, color: c.textSecondary)),
          ],
        ),
      );
    }
    if (_failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              '기업을 불러오지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
              style: t.body(14),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          JourneyButton(
            label: '다시 시도',
            icon: LucideIcons.refreshCw,
            onPressed: () => _search(_query.text, immediate: true),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return Semantics(
        liveRegion: true,
        child: Text(
          '일치하는 기업이 없어요. 이름의 일부나 6자리 종목코드로 검색해 보세요.',
          style: t.body(14),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            '기업을 선택하면 ${_intent.action}',
            style: t.body(12, color: c.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final item in _items)
          Material(
            color: c.surface,
            child: ShadButton.ghost(
              key: ValueKey('home-result-${item.corpCode}'),
              width: double.infinity,
              height: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
              ),
              onPressed: () {
                _focus.unfocus();
                context.push(_intent.destination(item.corpCode));
              },
              child: Flexible(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: t.body(16, weight: FontWeight.w600),
                          ),
                          Text(
                            [?item.stockCode, ?item.industryName].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.body(12, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Icon(LucideIcons.arrowRight, size: 20, color: c.accent),
                  ],
                ),
              ),
            ),
          ),
        ShadButton.ghost(
          onPressed: () =>
              context.go(CompanyFilter(query: _query.text.trim()).location),
          child: Flexible(child: const Text('검색 결과 전체 보기')),
        ),
      ],
    );
  }
}
