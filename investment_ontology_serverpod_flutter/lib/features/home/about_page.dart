import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../../design/premium_style.dart';
import '../monetization/service_links.dart';
import 'journey_widgets.dart';
import 'intro_film.dart';
import 'company_preview.dart';

typedef IntroScopeLoad = Future<Overview> Function();

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.loadScope, this.previewLoad});
  final IntroScopeLoad? loadScope;
  final PreviewFactsLoad? previewLoad;
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Overview? _scope;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadScope();
  }

  Future<void> _loadScope() async {
    try {
      final result =
          await (widget.loadScope?.call() ?? client.company.overview());
      if (mounted) setState(() => _scope = result);
    } catch (_) {
      // The introduction remains usable without a data-coverage claim.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PageFrame.gutter(MediaQuery.sizeOf(context).width),
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Text('알파인더', style: t.body(18, weight: FontWeight.w700)),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width > 420)
                    ShadButton.ghost(
                      onPressed: () => context.go('/home'),
                      child: Flexible(child: const Text('홈')),
                    ),
                  const SizedBox(width: AppSpace.sm),
                  JourneyButton(
                    label: '시작하기',
                    primary: true,
                    onPressed: () => context.go('/companies'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageFrame(
                maxWidth: 1200,
                controller: _scroll,
                children: [
                  const SizedBox(height: 52),
                  Center(
                    child: Text(
                      '발견하고, 분석하고,\n변화를 놓치지 않도록.',
                      textAlign: TextAlign.center,
                      style: t
                          .display(
                            MediaQuery.sizeOf(context).width < 600 ? 36 : 60,
                          )
                          .copyWith(height: 1.25, letterSpacing: -2),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Center(
                    child: Text(
                      '어떤 기업을 볼지, 무엇을 확인할지, 무엇이 달라졌는지.\n기업의 사업과 숫자, 작성자의 투자 관점을 함께 살펴보세요.',
                      textAlign: TextAlign.center,
                      style: t
                          .body(17, color: c.textSecondary)
                          .copyWith(height: 1.7),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Center(
                    child: JourneyButton(
                      label: '기업 탐색 시작하기',
                      primary: true,
                      onPressed: () => context.go('/companies'),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Center(
                    child: Text(
                      '가입 없이 기업 탐색부터',
                      style: t.body(12, color: c.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  IntroFilm(controller: _scroll),
                  const SizedBox(height: 64),
                  Divider(color: c.border),
                  const SizedBox(height: AppSpace.xl),
                  LayoutBuilder(
                    builder: (context, box) {
                      final entries = [
                        (
                          number: _scope == null
                              ? '국내 상장사'
                              : _scope!.totalListed.toString().replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{3})+$)'),
                                  (m) => '${m[1]},',
                                ),
                          label: _scope == null
                              ? '공식 기업정보에서 출발'
                              : '현재 조회 가능한 상장사',
                          detail: '상장사 목록 기준 · 기업별 자료 범위는 다름',
                        ),
                        (
                          number: '5개 관점',
                          label: '한 기업을 여러 방향에서',
                          detail: '개요 · 재무 · 지배구조 · 주주환원 · 공시',
                        ),
                        (
                          number: '원문까지',
                          label: '숫자의 근거를 확인',
                          detail: '기준일 · 출처 · 계산식과 입력값',
                        ),
                      ];
                      return Wrap(
                        spacing: AppSpace.xl,
                        runSpacing: AppSpace.xl,
                        children: [
                          for (final e in entries)
                            SizedBox(
                              width: box.maxWidth < 700
                                  ? box.maxWidth
                                  : (box.maxWidth - AppSpace.xl * 2) / 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.number,
                                    style: t.display(30, color: c.accent),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    e.label,
                                    style: t.body(14, weight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    e.detail,
                                    style: t.body(11, color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                  Text(
                    '투자 탐구의 세 과정,\n한곳에서 이어가세요.',
                    style: t.display(34).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    '기업을 훑어보고, 관심이 생기면 더 깊이 분석하고, 이후의 변화를 지켜보세요.',
                    style: t.body(15, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  for (final entry in [
                    (
                      number: '01',
                      question: '종목발굴 · 어떤 기업을 살펴볼까?',
                      problem:
                          '어떤 기업을 봐야 할지 막막할 때, 먼저 살펴볼 후보와 관심을 가져야 할 이유가 필요합니다.',
                      outcome: '직접 기업을 찾거나 스크리너로 후보를 좁혀보세요. 작성자가 선별한 관심종목 소개와 탑픽에서는 주목하는 이유와 투자 관점을 읽을 수 있습니다.',
                      action: '기업 찾기에서 시작',
                      destination: '/screen',
                      icon: LucideIcons.store,
                    ),
                    (
                      number: '02',
                      question: '기업분석 · 투자할 근거가 있을까?',
                      problem: '좋은 이야기만으로 판단하기는 어렵습니다. 사업이 실제로 작동하는지, 숫자와 기술의 차별성을 뒷받침할 근거가 필요합니다.',
                      outcome: '사업·재무·기업 비교와 출처를 함께 확인하세요. 작성자 분석에서는 투자 논리와 근거, 아직 확인해야 할 쟁점을 정리합니다.',
                      action: '기업 분석 시작하기',
                      destination: '/companies',
                      icon: LucideIcons.chartLine,
                    ),
                    (
                      number: '03',
                      question: '모니터링 · 무엇이 달라졌을까?',
                      problem: '기업을 분석한 뒤에도 새로운 공시와 사업 변화를 계속 확인해야 합니다.',
                      outcome: '관심기업의 새 공시와 작성자의 후속 글을 알림함에서 확인하세요. 후속 글은 이전 관점과 연결되어 판단의 변화를 따라갈 수 있습니다.',
                      action: '관심기업 등록하기',
                      destination: '/watchlist',
                      icon: LucideIcons.bell,
                    ),
                  ]) ...[
                    Divider(color: c.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xl,
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final question = Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.number,
                                style: t.numeric(13, color: c.accent),
                              ),
                              const SizedBox(width: AppSpace.lg),
                              Expanded(
                                child: Text(
                                  entry.question,
                                  style: t.display(23).copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          );
                          final answer = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.problem,
                                style: t
                                    .body(13, color: c.textSecondary)
                                    .copyWith(height: 1.7),
                              ),
                              const SizedBox(height: AppSpace.md),
                              Text(
                                entry.outcome,
                                style: t.body(16).copyWith(height: 1.7),
                              ),
                              const SizedBox(height: AppSpace.lg),
                              JourneyButton(
                                label: entry.action,
                                icon: entry.icon,
                                onPressed: () => context.go(entry.destination),
                              ),
                            ],
                          );
                          return box.maxWidth >= 850
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: question),
                                    const SizedBox(width: AppSpace.xxl),
                                    Expanded(child: answer),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    question,
                                    const SizedBox(height: AppSpace.lg),
                                    answer,
                                  ],
                                );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xxl),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    decoration: BoxDecoration(
                      color: c.accentSubtle,
                      borderRadius: context.shape.borderRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('처음이라면, 한 기업부터.', style: t.display(28)),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          '궁금한 기업 하나를 골라, 이 순서로 살펴보세요.',
                          style: t
                              .body(15, color: c.textSecondary)
                              .copyWith(height: 1.8),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        _firstCompanyJourney(),
                        const SizedBox(height: AppSpace.xl),
                        Wrap(
                          spacing: AppSpace.md,
                          runSpacing: AppSpace.md,
                          children: [
                            JourneyButton(
                              label: '삼성전자부터 살펴보기',
                              primary: true,
                              onPressed: () => context.go('/company/00126380'),
                            ),
                            JourneyButton(
                              label: '직접 기업 찾기',
                              onPressed: () => context.go('/companies'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          '사용 흐름을 익히는 예시이며 투자 추천이 아닙니다.',
                          style: t.body(11, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  Text('충분히 경험한 뒤, 더 깊게 함께하세요.', style: t.display(25)),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    '분석 도구를 먼저 이용해보세요. 더 깊은 작성자 관점과 더 많은 관심기업을 하나의 멤버십으로 이어갑니다.',
                    style: t
                        .body(15, color: c.textSecondary)
                        .copyWith(height: 1.8),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  LayoutBuilder(
                    builder: (context, box) {
                      final offers = [
                        _offer(
                          title: '무료로 시작하기',
                          description: '궁금한 기업을 충분히 살펴보세요.',
                          benefits: const [
                            '기업 정보·사업·재무 분석',
                            '스크리너와 기업 비교',
                            '작성자가 선별한 관심종목 소개',
                            '관심기업 3개와 공시·후속 글 알림함',
                          ],
                          action: '무료 기업 분석 시작하기',
                          destination: '/companies',
                        ),
                        _offer(
                          premium: true,
                          title: '판단의 깊이가 달라지는 리서치',
                          description: '선별된 탑픽부터 투자 논리, 그 이후의 변화까지.',
                          benefits: const [
                            '무료 분석 기능 모두 포함',
                            '작성자가 선정한 탑픽',
                            '상세 투자 논리·근거와 날짜별 후속 기록',
                            '관심기업 20개와 광고 제거',
                          ],
                          action: '멤버십 혜택 확인하기',
                          destination: '/membership',
                        ),
                      ];
                      if (box.maxWidth < 720) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            offers.first,
                            const SizedBox(height: AppSpace.lg),
                            offers.last,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: offers.first),
                          const SizedBox(width: AppSpace.lg),
                          Expanded(child: offers.last),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: c.surfaceHover,
                      borderRadius: context.shape.borderRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('어떤 기업에, 왜 주목할까요?', style: t.display(21)),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '기업을 고른 이유와 투자 논리, 관점이 바뀌는 순간까지. 작성자의 리서치를 따라가세요.',
                          style: t
                              .body(14, color: c.textSecondary)
                              .copyWith(height: 1.7),
                        ),
                        const SizedBox(height: AppSpace.md),
                        Wrap(
                          spacing: AppSpace.md,
                          runSpacing: AppSpace.sm,
                          children: [
                            JourneyButton(
                              label: '투자 관점 둘러보기',
                              primary: true,
                              onPressed: () => context.go('/insights'),
                            ),
                            JourneyButton(
                              label: '내 관심기업의 변화 확인하기',
                              onPressed: () => context.go('/watchlist'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  Text('판단은 스스로. 근거는 분명하게.', style: t.display(25)),
                  const SizedBox(height: AppSpace.lg),
                  _faq(
                    '숫자는 어디에서 오나요?',
                    'DART 공시와 공식 시장 자료를 바탕으로 보여줍니다. 기업별 수집 범위가 다르며 자료 미확보·수집 대기 상태도 구분합니다. 시세는 실시간 가격이 아니므로 기준일을 확인하세요.',
                  ),
                  _faq(
                    '투자 성과나 시간 절약을 보장하나요?',
                    '투자 성과를 보장하지 않습니다. 작성자의 투자 관점과 그 근거를 제공하며 최종 판단은 독자가 합니다. 소개의 기업 수는 현재 조회한 상장사 목록 규모이며 모든 자료의 완전성을 뜻하지 않습니다.',
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  Divider(color: c.border),
                  const SizedBox(height: AppSpace.lg),
                  const ServiceLinks(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _firstCompanyJourney() => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 760;
      const steps = [
        (icon: LucideIcons.store, title: '기업 이해', detail: '무엇을 팔고\n어떻게 돈을 버는지'),
        (
          icon: LucideIcons.chartLine,
          title: '근거 확인',
          detail: '실적과 비교 지표\n숫자의 출처까지',
        ),
        (
          icon: LucideIcons.bell,
          title: '변화 추적',
          detail: '관심기업으로 등록\n공시와 후속 글 확인',
        ),
      ];
      Widget step(int i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: context.shape.borderRadius,
              ),
              child: Icon(
                steps[i].icon,
                color: context.colors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0${i + 1}  ${steps[i].title}',
                    style: context.typo.body(17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    steps[i].detail,
                    style: context.typo
                        .body(14, color: context.colors.textSecondary)
                        .copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 20,
                    color: context.colors.accent,
                  ),
                ),
              Expanded(child: step(i)),
            ],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: 18,
                    color: context.colors.borderStrong,
                  ),
                ),
              ),
            step(i),
          ],
        ],
      );
    },
  );

  Widget _offer({
    required String title,
    required String description,
    required List<String> benefits,
    required String action,
    required String destination,
    bool premium = false,
  }) {
    final c = context.colors;
    final t = context.typo;
    final foreground = premium ? PremiumStyle.light : c.textPrimary;
    final secondary = premium ? PremiumStyle.muted : c.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: premium
          ? PremiumStyle.decoration()
          : BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...[
            Row(
              children: [
                Icon(
                  premium ? LucideIcons.sparkles : LucideIcons.compass,
                  color: premium ? PremiumStyle.gold : c.accent,
                  size: 18,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    premium ? 'ALFINDER  /  MEMBERSHIP' : 'ALFINDER  /  FREE',
                    style: t
                        .body(
                          11,
                          color: premium ? PremiumStyle.gold : c.accent,
                          weight: FontWeight.w600,
                        )
                        .copyWith(letterSpacing: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          Text(title, style: t.display(premium ? 26 : 22, color: foreground)),
          const SizedBox(height: AppSpace.sm),
          Text(
            description,
            style: t.body(14, color: secondary).copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSpace.lg),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: premium ? PremiumStyle.gold : c.accent,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      benefit,
                      style: t
                          .body(14, color: foreground)
                          .copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.md),
          if (premium)
            ShadButton(
              backgroundColor: PremiumStyle.gold,
              hoverBackgroundColor: PremiumStyle.gold.withValues(alpha: .9),
              onPressed: () => context.go(destination),
              child: Flexible(
                child: Text(
                  action,
                  style: t.body(
                    14,
                    color: PremiumStyle.ink,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ShadButton.outline(
              onPressed: () => context.go(destination),
              child: Flexible(child: Text(action)),
            ),
        ],
      ),
    );
  }

  Widget _faq(String title, String answer) => ShadAccordion<int>(
    maintainState: false,
    children: [
      ShadAccordionItem<int>(
        value: 0,
        title: Text(
          title,
          style: context.typo.body(14, weight: FontWeight.w600),
        ),
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: context.typo
                      .body(14, color: context.colors.textSecondary)
                      .copyWith(height: 1.8),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
