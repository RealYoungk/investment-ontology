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
  });
  final ExploreIntent intent;
  final CompanySearch? search;
  final FilingFeedLoad? filings;
  final MarketPulseLoad? market;
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
          '기업 바로 찾기',
          key: _searchKey,
          style: t.body(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          key: const ValueKey('home-company-search'),
          controller: _query,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          style: t.body(16),
          onChanged: _search,
          onSubmitted: (value) => _search(value, immediate: true),
          decoration: InputDecoration(
            labelText: '기업 이름 또는 종목코드',
            hintText: '예: 삼성전자, 005930',
            prefixIcon: Icon(Icons.search, color: c.textSecondary),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '검색어 지우기',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _query.clear();
                      _search('');
                      _focus.requestFocus();
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 22,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          '${_intent.label} · ${_intent.description}',
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
                TextButton(
                  onPressed: () => _example(name),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  child: Text(name),
                ),
            ],
          ),
          Text(
            '사용법을 살펴볼 수 있는 예시예요. 투자 추천은 아니에요.',
            style: t.body(12, color: c.textSecondary),
          ),
        ],
      ],
    );
    return PageFrame(
      maxWidth: 1160,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESEARCH DESK', style: t.label(color: c.accent)),
                const SizedBox(height: AppSpace.sm),
                Text('오늘의 리서치', style: t.display(28)),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/about'),
              child: const Text('처음 오셨나요? 서비스 소개 →'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        MarketPulse(load: widget.market),
        const SizedBox(height: AppSpace.xxl),
        DailyBrief(load: widget.filings),
        const SizedBox(height: AppSpace.xxl),
        LayoutBuilder(
          builder: (context, box) {
            final discovery = Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: c.accentSubtle,
                borderRadius: context.shape.borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '다음 탐색의 출발점',
                    style: t.body(16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '궁금한 산업에서 후보를 넓혀보세요.',
                    style: t.body(12, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.md),
                  for (final item in const [
                    (
                      title: '전자·반도체',
                      detail: '부품부터 장비까지',
                      code: '26',
                      icon: Icons.memory_outlined,
                    ),
                    (
                      title: '자동차',
                      detail: '완성차와 부품',
                      code: '30',
                      icon: Icons.directions_car_outlined,
                    ),
                    (
                      title: '식품',
                      detail: '식품 제조 기업',
                      code: '10',
                      icon: Icons.restaurant_outlined,
                    ),
                  ])
                    _entry(
                      context,
                      title: item.title,
                      detail: item.detail,
                      icon: item.icon,
                      onTap: () => context.push(
                        CompanyFilter(
                          section: 'C',
                          division: item.code,
                        ).location,
                      ),
                    ),
                ],
              ),
            );
            return box.maxWidth >= 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: search),
                      const SizedBox(width: AppSpace.xxl),
                      Expanded(flex: 4, child: discovery),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: AppSpace.xl),
                      discovery,
                    ],
                  );
          },
        ),
        const SizedBox(height: AppSpace.xxl),
        Text('숫자로 좁히는 후보', style: t.body(17, weight: FontWeight.w600)),
        const SizedBox(height: AppSpace.sm),
        Text(
          '수집된 지표의 조건별 탐색 · 추천이나 순위가 아닙니다.',
          style: t.body(12, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              for (final item in const [
                (
                  title: '매출이 늘어난 기업',
                  detail: '최근 12개월 매출 성장률',
                  value: '10% 이상',
                  path: '/screen?rgrow=10',
                ),
                (
                  title: '이익을 남기는 기업',
                  detail: '최근 12개월 영업이익률',
                  value: '10% 이상',
                  path: '/screen?margin=10',
                ),
                (
                  title: '배당을 주는 기업',
                  detail: '연간 배당금 ÷ 최근 주가',
                  value: '3% 이상',
                  path: '/screen?div=3',
                ),
              ])
                SizedBox(
                  width: box.maxWidth < 700
                      ? box.maxWidth
                      : (box.maxWidth - AppSpace.md * 2) / 3,
                  child: Material(
                    color: c.surface,
                    borderRadius: context.shape.borderRadius,
                    child: InkWell(
                      borderRadius: context.shape.borderRadius,
                      onTap: () => context.push(item.path),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: t.body(15, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.value,
                                    style: t.numeric(24, color: c.accent),
                                  ),
                                ),
                                Icon(
                                  Icons.north_east,
                                  size: 18,
                                  color: c.accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              item.detail,
                              style: t.body(12, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        Align(
          alignment: Alignment.centerLeft,
          child: JourneyButton(
            label: '기업 비교로 이어가기',
            onPressed: () => context.go('/compare'),
          ),
        ),
      ],
    );
  }

  Widget _entry(
    BuildContext context, {
    required String title,
    required String detail,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    final t = context.typo;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpace.md,
            horizontal: AppSpace.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: c.accent),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.body(15, weight: FontWeight.w600)),
                    const SizedBox(height: AppSpace.xs),
                    Text(detail, style: t.body(12, color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Icon(Icons.arrow_forward, size: 18, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    if (_loading) {
      return Semantics(
        liveRegion: true,
        label: '기업 검색 중',
        child: const LinearProgressIndicator(minHeight: 2),
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
            icon: Icons.refresh,
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
            child: ListTile(
              key: ValueKey('home-result-${item.corpCode}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
              ),
              title: Text(
                item.name,
                style: t.body(16, weight: FontWeight.w600),
              ),
              subtitle: Text(
                [?item.stockCode, ?item.industryName].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.body(12, color: c.textSecondary),
              ),
              trailing: Icon(Icons.arrow_forward, size: 20, color: c.accent),
              onTap: () {
                _focus.unfocus();
                context.push(_intent.destination(item.corpCode));
              },
            ),
          ),
        TextButton(
          onPressed: () =>
              context.go(CompanyFilter(query: _query.text.trim()).location),
          child: const Text('검색 결과 전체 보기'),
        ),
      ],
    );
  }
}
