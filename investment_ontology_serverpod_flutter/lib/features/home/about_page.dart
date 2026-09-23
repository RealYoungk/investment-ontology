import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'explore_intent.dart';
import 'journey_widgets.dart';

/// Public-facing introduction. It needs no backend data to explain the service.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _step = 0;
  static const _details = [
    (
      '이름을 아는 기업에서,\n사업을 아는 기업으로.',
      '주요 사업과 매출 구성을 살펴보고, 더 궁금한 내용은 사업보고서 근거까지 확인하세요.',
      '기업 개요에서 시작',
    ),
    (
      '숫자 하나보다,\n변화의 흐름을 보세요.',
      '매출·이익·현금흐름을 기간별로 살펴보세요. 지표의 계산식과 입력값도 확인할 수 있어요.',
      '재무 추이에서 시작',
    ),
    (
      '기업을 나란히 놓으면,\n다른 질문이 생깁니다.',
      '비교할 기업을 직접 고르고 같은 기준의 지표를 살펴보세요. 사업이 다른 기업은 수치의 의미도 다를 수 있어요.',
      '기업 비교에서 시작',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: PageFrame.gutter(MediaQuery.sizeOf(context).width),
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '알파인더',
                      style: t.body(17, weight: FontWeight.w700),
                    ),
                  ),
                  JourneyButton(
                    label: '시작하기',
                    primary: true,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageFrame(
                maxWidth: 1160,
                children: [
                  const SizedBox(height: AppSpace.section),
                  const JourneyHeading(
                    eyebrow: '국내 상장기업을 이해하는 공간',
                    title: '기업을 이해하는 일,\n하나의 질문에서 시작하세요.',
                    large: true,
                    description:
                        '아는 이름에서 투자 판단의 근거까지.\n흩어진 사업·재무·기업 관계를 이어서 살펴보세요.',
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: JourneyButton(
                      label: '궁금한 기업 찾아보기',
                      primary: true,
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                  const SizedBox(height: 64),
                  Divider(color: c.borderStrong),
                  const SizedBox(height: AppSpace.section),
                  Text('무엇을 봐야 할지 막막할 때', style: t.label(color: c.accent)),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    '세 가지 질문을 따라가 보세요.',
                    style: t.display(28).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  LayoutBuilder(
                    builder: (context, box) {
                      final path = ResearchPath(
                        activeStep: _step,
                        onStep: (step) => setState(() => _step = step),
                      );
                      final detail = Padding(
                        padding: const EdgeInsets.all(AppSpace.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0${_step + 1} / ${ExploreIntent.values[_step].label}',
                              style: t.label(color: c.accent),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            Text(
                              _details[_step].$1,
                              style: t.display(28).copyWith(height: 1.4),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            Text(
                              _details[_step].$2,
                              style: t
                                  .body(16, color: c.textSecondary)
                                  .copyWith(height: 1.7),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            JourneyButton(
                              label: _details[_step].$3,
                              onPressed: () => context.go(
                                '/home?intent=${ExploreIntent.values[_step].name}',
                              ),
                            ),
                          ],
                        ),
                      );
                      return box.maxWidth >= 800
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: path),
                                const SizedBox(width: AppSpace.xxl),
                                Expanded(child: detail),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [path, detail],
                            );
                    },
                  ),
                  const SizedBox(height: 64),
                  Container(
                    color: c.inverse,
                    padding: const EdgeInsets.all(AppSpace.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '판단의 근거가 보이도록',
                          style: t
                              .display(28, color: c.onInverse)
                              .copyWith(height: 1.4),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        _principle(
                          '출처와 함께',
                          '공시와 공식 시세 자료에서 출발해, 원문과 기준일을 확인할 수 있게 합니다.',
                        ),
                        _principle(
                          '계산 과정까지',
                          'PER·수익성 같은 지표는 계산식과 입력값을 함께 살펴볼 수 있습니다.',
                        ),
                        _principle(
                          '모르는 것은 분명하게',
                          '자료가 없거나 수집 중인 상태를 구분합니다. 데이터가 없다는 것이 위험이 없다는 뜻은 아닙니다.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.section),
                  Text('궁금한 점이 남았다면', style: t.display(26)),
                  const SizedBox(height: AppSpace.lg),
                  _faq(
                    '투자 경험이 적어도 쓸 수 있나요?',
                    '홈에서 아는 기업을 검색하고 개요부터 살펴보세요. 처음부터 모든 지표를 이해할 필요는 없습니다. 무엇을 하는 회사인지 알아본 뒤 재무와 비교로 넓혀갈 수 있어요.',
                  ),
                  _faq(
                    '매수할 종목을 추천해 주나요?',
                    '기업을 이해하고 비교할 근거를 제공하는 서비스입니다. 매수·매도 추천이나 수익 보장을 제공하지 않으며, 최종 판단은 사용자가 합니다.',
                  ),
                  _faq(
                    '모든 기업의 정보가 같은 시점인가요?',
                    '아닙니다. 공시 시점과 수집 상태에 따라 기업별 자료 범위가 다르고, 시세도 실시간 가격이 아닙니다. 각 화면의 기준일과 출처를 확인하세요.',
                  ),
                  const SizedBox(height: AppSpace.section),
                  Wrap(
                    spacing: AppSpace.xl,
                    runSpacing: AppSpace.lg,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '첫 기업을 살펴볼 준비가 됐나요?',
                        style: t.body(20, weight: FontWeight.w600),
                      ),
                      JourneyButton(
                        label: '기업 탐색 시작하기',
                        primary: true,
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.section),
                  Divider(color: c.border),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    '알파인더 · 기업을 이해하고, 근거를 확인하고, 스스로 판단하기',
                    style: t.body(12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _principle(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.typo.body(
            16,
            color: context.colors.onInverse,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          description,
          style: context.typo
              .body(14, color: context.colors.onInverse)
              .copyWith(height: 1.6),
        ),
      ],
    ),
  );

  Widget _faq(String title, String answer) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: AppSpace.xl),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    title: Text(title, style: context.typo.body(16, weight: FontWeight.w600)),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          answer,
          style: context.typo
              .body(14, color: context.colors.textSecondary)
              .copyWith(height: 1.7),
        ),
      ),
    ],
  );
}
