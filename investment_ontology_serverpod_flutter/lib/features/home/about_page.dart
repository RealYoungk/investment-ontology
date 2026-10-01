import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../monetization/service_links.dart';
import 'explore_intent.dart';
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
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('홈'),
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
                      '흩어진 정보에서, 연결된 이해로.',
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
                      '공시와 숫자를 기업으로 모으고,\n기업 사이의 관계를 따라 더 깊이 탐색하세요.',
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
                    '좋은 질문이,\n좋은 탐색의 시작이니까.',
                    style: t.display(34).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    '읽어야 할 자료는 많습니다. 지금 알고 싶은 것부터 연결해 보세요.',
                    style: t.body(15, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  for (final entry in [
                    (
                      number: '01',
                      question: '이 회사는 대체 무엇을 파는 걸까?',
                      problem: '종목 이름과 업종만으로는 실제 사업이 잘 보이지 않습니다.',
                      outcome: '제품과 쓰이는 공정, 매출 구성을 함께 읽으며 사업의 구조를 파악하세요.',
                      action: '기업 개요에서 시작',
                      intent: ExploreIntent.overview,
                      icon: Icons.storefront_outlined,
                    ),
                    (
                      number: '02',
                      question: '매출은 늘었는데, 왜 이익은 줄었을까?',
                      problem: '서로 다른 보고서와 기간을 오가면 변화의 맥락을 놓치기 쉽습니다.',
                      outcome: '매출·이익·현금흐름을 기간별로 살피고 지표의 계산식과 입력값까지 확인하세요.',
                      action: '재무 추이에서 시작',
                      intent: ExploreIntent.financials,
                      icon: Icons.stacked_line_chart,
                    ),
                    (
                      number: '03',
                      question: '비슷해 보이는 두 회사, 무엇이 다를까?',
                      problem: '가격이나 하나의 지표만으로 사업과 재무의 차이를 설명하기 어렵습니다.',
                      outcome:
                          '직접 고른 기업을 동일 기준의 지표로 비교하고, 차이가 나는 항목을 더 깊게 읽으세요.',
                      action: '기업 비교에서 시작',
                      intent: ExploreIntent.compare,
                      icon: Icons.compare_arrows,
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
                                onPressed: () => context.go(
                                  '/home?intent=${entry.intent.name}',
                                ),
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
                          '아는 기업의 개요를 읽고 → 재무에서 변화를 보고 → 다른 기업과 비교해 보세요.\n삼성전자 예시로 시작하거나, 궁금한 기업을 직접 찾아도 좋습니다.',
                          style: t
                              .body(15, color: c.textSecondary)
                              .copyWith(height: 1.8),
                        ),
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
                  Text('판단은 스스로. 근거는 분명하게.', style: t.display(25)),
                  const SizedBox(height: AppSpace.lg),
                  _faq(
                    '숫자는 어디에서 오나요?',
                    'DART 공시와 공식 시장 자료를 바탕으로 보여줍니다. 기업별 수집 범위가 다르며 자료 미확보·수집 대기 상태도 구분합니다. 시세는 실시간 가격이 아니므로 기준일을 확인하세요.',
                  ),
                  _faq(
                    '투자 성과나 시간 절약을 보장하나요?',
                    '아닙니다. 자료를 찾고 비교하는 흐름을 돕지만 수익을 보장하거나 매수·매도 종목을 추천하지 않습니다. 소개의 기업 수는 현재 조회한 상장사 목록 규모이며 모든 항목의 완전성을 뜻하지 않습니다.',
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

  Widget _faq(String title, String answer) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: AppSpace.lg),
    title: Text(title, style: context.typo.body(14, weight: FontWeight.w600)),
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
  );
}
