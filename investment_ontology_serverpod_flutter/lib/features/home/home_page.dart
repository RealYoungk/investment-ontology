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
        const JourneyHeading(
          eyebrow: '나의 기업 탐색',
          title: '궁금한 기업,\n어디부터 살펴볼까요?',
          description: '무엇으로 돈을 벌고, 어떻게 변하고 있는지.\n공시 데이터에서 판단의 근거를 찾아보세요.',
        ),
        const SizedBox(height: AppSpace.xxl),
        Text(
          '먼저 기업 하나를 골라보세요',
          key: _searchKey,
          style: t.body(14, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.md),
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.go('/about'),
            icon: const Icon(Icons.auto_stories_outlined, size: 16),
            label: const Text('처음이라면, 서비스 소개'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 920
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: search),
                    const SizedBox(width: 64),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpace.lg),
                        child: ResearchPath(
                          activeStep: _intent.index,
                          onStep: (i) => _selectIntent(ExploreIntent.values[i]),
                        ),
                      ),
                    ),
                  ],
                )
              : search,
        ),
        const SizedBox(height: 64),
        Divider(color: c.border),
        const SizedBox(height: AppSpace.xxl),
        Text('어떤 것이 궁금하세요?', style: t.display(26)),
        const SizedBox(height: AppSpace.sm),
        Text(
          '질문을 고르면 선택한 기업의 해당 화면으로 이어집니다.',
          style: t.body(14, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpace.xl),
        for (final intent in ExploreIntent.values) _intentRow(context, intent),
        const SizedBox(height: AppSpace.section),
        Wrap(
          spacing: AppSpace.xl,
          runSpacing: AppSpace.lg,
          children: [
            JourneyButton(
              label: '처음 오셨나요? 서비스 소개',
              icon: Icons.auto_stories_outlined,
              onPressed: () => context.go('/about'),
            ),
            JourneyButton(
              label: '전체 기업 둘러보기',
              onPressed: () => context.go('/companies'),
            ),
            JourneyButton(
              label: '조건으로 기업 찾기',
              onPressed: () => context.go('/screen'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          '기업별 자료의 기준일과 수집 범위는 다를 수 있어요. 상세 화면에서 출처와 기간을 함께 확인하세요.',
          style: t.body(12, color: c.textSecondary),
        ),
      ],
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

  Widget _intentRow(BuildContext context, ExploreIntent intent) {
    final c = context.colors;
    final t = context.typo;
    final selected = _intent == intent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? c.accentSubtle : c.surface,
          child: InkWell(
            onTap: () => _selectIntent(intent),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Row(
                children: [
                  Text(
                    '0${intent.index + 1}',
                    style: t.numeric(16, color: c.accent),
                  ),
                  const SizedBox(width: AppSpace.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          intent.question,
                          style: t.body(18, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          intent.description,
                          style: t.body(13, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Icon(
                    selected ? Icons.check_circle_outline : Icons.arrow_forward,
                    color: selected ? c.accent : c.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
