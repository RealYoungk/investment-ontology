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
  });
  final ExploreIntent intent;
  final CompanySearch? search;
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

  void _selectIntent(ExploreIntent intent) {
    setState(() => _intent = intent);
    _focus.requestFocus();
    final target = _searchKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.normal,
        alignment: 0.15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final search = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('찾고 있는 기업이 있나요?', key: _searchKey, style: t.display(24)),
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
            '예시 기업은 사용법을 살펴보기 위한 것으로, 투자 추천이 아닙니다.',
            style: t.body(12, color: c.textSecondary),
          ),
        ],
      ],
    );
    return PageFrame(
      maxWidth: 1160,
      children: [
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(
          builder: (context, box) {
            final introduction = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const JourneyHeading(
                  eyebrow: '기업을 알아가는 첫걸음',
                  title: '아는 산업에서,\n새로운 기업으로.',
                  description:
                      '무엇을 팔고, 얼마나 벌고, 어떻게 달라지는지.\n국내 상장기업을 공시와 숫자로 알아보세요.',
                  large: true,
                ),
                const SizedBox(height: AppSpace.xl),
                Text(
                  '기업 이름을 몰라도 괜찮습니다.',
                  style: t.body(14, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.md),
                JourneyButton(
                  label: '전체 기업 둘러보기',
                  primary: true,
                  onPressed: () => context.push('/companies'),
                ),
              ],
            );
            final entry = Container(
              padding: const EdgeInsets.all(AppSpace.xl),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: context.shape.borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '익숙한 산업부터 골라보세요',
                    style: t.body(18, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '산업 안의 기업을 규모순으로 살펴봅니다.',
                    style: t.body(12, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  for (final item in const [
                    (
                      name: '전자·반도체',
                      detail: '전자부품 · 컴퓨터 · 통신장비',
                      code: '26',
                      icon: Icons.memory_outlined,
                    ),
                    (
                      name: '자동차',
                      detail: '완성차 · 차체 · 부품',
                      code: '30',
                      icon: Icons.directions_car_outlined,
                    ),
                    (
                      name: '식품',
                      detail: '우리가 매일 먹는 것들',
                      code: '10',
                      icon: Icons.restaurant_outlined,
                    ),
                    (
                      name: '의약품',
                      detail: '의약품 · 원료 · 관련 제품',
                      code: '21',
                      icon: Icons.medication_outlined,
                    ),
                  ])
                    _entry(
                      context,
                      title: item.name,
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
            if (box.maxWidth < 850) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  introduction,
                  const SizedBox(height: AppSpace.xxl),
                  entry,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: introduction),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: entry),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text('어떤 변화가 궁금한가요?', style: t.display(26)),
        const SizedBox(height: AppSpace.sm),
        Text(
          '간단한 조건으로 시작하고, 결과에서 내 기준으로 조정하세요.',
          style: t.body(14, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth < 700
                ? box.maxWidth
                : (box.maxWidth - AppSpace.md * 2) / 3;
            return Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final item in const [
                  (
                    title: '매출이 늘어난 기업',
                    detail: '최근 12개월 매출이 이전 12개월보다 10% 이상 증가',
                    path: '/screen?rgrow=10',
                    number: '01',
                  ),
                  (
                    title: '이익을 남기는 기업',
                    detail: '매출 100원당 영업이익 10원 이상 · 최근 12개월',
                    path: '/screen?margin=10',
                    number: '02',
                  ),
                  (
                    title: '배당을 주는 기업',
                    detail: '최근 연간 배당금 ÷ 최근 주가가 3% 이상',
                    path: '/screen?div=3',
                    number: '03',
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: Material(
                      color: c.surface,
                      child: InkWell(
                        onTap: () => context.push(item.path),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.number,
                                style: t.numeric(12, color: c.accent),
                              ),
                              const SizedBox(height: AppSpace.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: t.body(
                                        17,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: c.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                item.detail,
                                style: t.body(13, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '탐색을 위한 예시 조건입니다. 기업의 우열이나 투자 추천을 뜻하지 않습니다.',
          style: t.body(12, color: c.textSecondary),
        ),
        const SizedBox(height: 32),
        Divider(color: c.border),
        const SizedBox(height: AppSpace.xxl),
        LayoutBuilder(
          builder: (context, box) {
            final guide = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기업 하나, 이렇게 읽어보세요', style: t.display(24)),
                const SizedBox(height: AppSpace.lg),
                for (final intent in ExploreIntent.values)
                  _entry(
                    context,
                    title: intent.question,
                    detail: intent.description,
                    icon: switch (intent.index) {
                      0 => Icons.storefront_outlined,
                      1 => Icons.trending_up,
                      _ => Icons.compare_arrows,
                    },
                    onTap: () => _selectIntent(intent),
                  ),
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: () => context.push('/about'),
                  child: const Text('서비스 사용법 →'),
                ),
              ],
            );
            if (box.maxWidth < 850) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [search, const SizedBox(height: 48), guide],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: search),
                const SizedBox(width: 32),
                Expanded(child: guide),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.xxl),
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
