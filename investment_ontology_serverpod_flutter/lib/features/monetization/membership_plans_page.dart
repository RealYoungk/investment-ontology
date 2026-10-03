import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_auth.dart';
import 'membership_availability.dart';
import '../../client.dart';

import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

class MembershipPlansPage extends StatefulWidget {
  const MembershipPlansPage({
    super.key,
    this.checkoutEnabled = membershipCheckoutEnabled,
    this.loadOffer,
  });
  final bool checkoutEnabled;
  final Future<MembershipView> Function()? loadOffer;
  @override
  State<MembershipPlansPage> createState() => _MembershipPlansPageState();
}

class _MembershipPlansPageState extends State<MembershipPlansPage> {
  MembershipView? _offer;
  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  Future<void> _loadOffer() async {
    try {
      final value = await (widget.loadOffer ?? client.membershipOffer.offer)();
      if (mounted) setState(() => _offer = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppAuth.viewer,
    builder: (context, _) => _buildPlans(context),
  );

  Widget _buildPlans(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final paid = AppAuth.viewer.value?.isAdFree ?? false;
    return PageFrame(
      maxWidth: 960,
      children: [
        const SizedBox(height: AppSpace.md),
        Text(
          '알파인더 멤버십',
          textAlign: TextAlign.center,
          style: t.body(13, color: c.accent, weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpace.md),
        LayoutBuilder(
          builder: (context, box) => Text(
            '먼저 가입할수록,\n더 좋은 가격으로.',
            textAlign: TextAlign.center,
            style: t
                .display(box.maxWidth < 600 ? 32 : 44, color: c.textPrimary)
                .copyWith(height: 1.25),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          '새로운 기능이 더해질수록 신규 가입 요금도 올라갑니다.\n지금 가입한 요금으로, 앞으로 추가되는 기능까지 이용하세요.',
          textAlign: TextAlign.center,
          style: t.body(15, color: c.textSecondary).copyWith(height: 1.6),
        ),
        const SizedBox(height: AppSpace.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '얼리버드 혜택 · 구독을 유지하면 가입 가격 그대로',
              style: t.body(12, color: c.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        LayoutBuilder(
          builder: (context, box) {
            final free = MembershipPlanCard(
              premium: false,
              current: !paid,
              onSelect: () => context.go('/watchlist'),
            );
            final member = MembershipPlanCard(
              premium: true,
              amountKrw: _offer?.currentPriceKrw ?? 4900,
              current: paid,
              onSelect:
                  paid ||
                      (widget.checkoutEnabled &&
                          _offer?.paymentAvailable == true)
                  ? () =>
                        context.push(paid ? '/account' : '/membership/checkout')
                  : null,
            );
            if (box.maxWidth < 640) {
              return Column(
                children: [
                  member,
                  const SizedBox(height: AppSpace.md),
                  free,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: free),
                const SizedBox(width: AppSpace.lg),
                Expanded(child: member),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.section),
        Text(
          '무엇이 달라지나요?',
          textAlign: TextAlign.center,
          style: t.body(24, weight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpace.lg),
        const _PlanComparison(),
        const SizedBox(height: AppSpace.section),
        Text('궁금한 점을 확인하세요', style: t.body(22, weight: FontWeight.w700)),
        const SizedBox(height: AppSpace.md),
        const _PlanQuestion(
          question: '무료로도 기업 정보를 볼 수 있나요?',
          answer: '네. 기업 정보, 재무, 스크리너와 관계망은 무료로 탐색할 수 있습니다. 멤버십에서는 관심기업 등록 한도가 3개에서 20개로 늘어나고 광고가 제거됩니다.',
        ),
        const _PlanQuestion(
          question: '공시와 뉴스 알림은 어떻게 제공되나요?',
          answer: '관심기업의 새 공시를 모아 보는 기능은 두 플랜 모두 제공합니다. 기기 알림은 브라우저의 지원과 알림 권한에 따라 달라집니다. 뉴스 알림은 준비 중이며 현재 유료 혜택에 포함되지 않습니다.',
        ),
        const _PlanQuestion(
          question: '구독을 해지하면 언제까지 이용할 수 있나요?',
          answer: '계정에서 언제든 다음 갱신을 해지할 수 있습니다. 이미 결제한 기간까지 멤버십이 유지되며, 이용 기간이 끝나면 무료 플랜으로 전환됩니다.',
        ),
        const _PlanQuestion(
          question: '얼리버드 요금은 계속 유지되나요?',
          answer: '네. 새로운 기능이 더해지면 신규 가입 요금은 단계적으로 올라갑니다. 기존 구독자는 구독을 유지하는 동안 가입 당시 월 요금으로 앞으로 추가되는 기능도 함께 이용할 수 있습니다. 해지 후 이용 기간이 끝나 재가입하면 재가입 시 표시된 요금이 적용됩니다.',
        ),
        const _PlanQuestion(
          question: '환불은 어떻게 요청하나요?',
          answer: '현재 이용 기간 안에 문의 이메일로 요청하면 해당 회차 전액을 환불합니다. 환불이 완료되면 멤버십과 다음 갱신이 종료됩니다. 상세 조건은 결제 전 이용권 약관에서 확인할 수 있습니다.',
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          _offer?.paymentAvailable == true
              ? '결제 전 가입 가격과 자동 갱신 조건을 확인하세요.'
              : '멤버십은 출시 준비 중입니다. 지금은 무료 플랜으로 이용할 수 있습니다.',
          textAlign: TextAlign.center,
          style: t.body(12, color: c.textMuted),
        ),
      ],
    );
  }
}

class MembershipPlanCard extends StatelessWidget {
  const MembershipPlanCard({
    super.key,
    required this.premium,
    required this.current,
    required this.onSelect,
    this.amountKrw = 4900,
  });
  final int amountKrw;
  final bool premium;
  final bool current;
  final VoidCallback? onSelect;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: premium ? c.accentSubtle : c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: premium ? c.accent : c.border,
          width: premium ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  premium ? '멤버십' : '무료',
                  style: t.body(24, weight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: premium ? c.accent : c.surfaceHover,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  current
                      ? '이용 중'
                      : premium
                      ? '더 넓은 관심 목록'
                      : '기본 플랜',
                  style: t.body(
                    11,
                    color: premium ? c.onAccent : c.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            premium ? '여러 기업을 꾸준히 살펴보는 분께' : '핵심 기업부터 가볍게 시작하는 분께',
            style: t.body(13, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.xl),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: premium
                      ? amountKrw.toString().replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+$)'),
                          (m) => '${m[1]},',
                        )
                      : '0',
                  style: t.numeric(40, weight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' 원 / 월',
                  style: t.body(14, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            premium ? '얼리버드 · 부가세 포함 · 매월 자동 갱신' : '기간 제한 없이 무료',
            style: t.body(12, color: c.textMuted),
          ),
          if (premium) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              '구독을 유지하면 가입 가격 그대로',
              style: t.body(13, color: c.accent, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '앞으로 추가되는 기능도 가입한 요금으로 이용',
              style: t.body(12, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            height: 48,
            child: premium
                ? ShadButton(
                    onPressed: onSelect,
                    child: Flexible(
                      child: Text(
                        current
                            ? '멤버십 관리'
                            : onSelect == null
                            ? '멤버십 출시 준비 중'
                            : '얼리버드 가격으로 시작하기',
                      ),
                    ),
                  )
                : ShadButton.outline(
                    onPressed: onSelect,
                    child: Flexible(
                      child: Text(current ? '무료로 계속 이용하기' : '관심종목으로 돌아가기'),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.xl),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bookmarks_outlined,
                  size: 24,
                  color: premium ? c.accent : c.textSecondary,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '나의 관심기업',
                        style: t.body(12, color: c.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        premium ? '최대 20개' : '최대 3개',
                        style: t.body(22, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            premium ? '무료 플랜의 모든 기능에 더해' : '투자 리서치의 기본을 함께',
            style: t.body(12, weight: FontWeight.w600, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final item
              in premium
                  ? [
                      '관심기업 17개 추가 등록',
                      '광고 없이 기업 정보에 집중',
                      '등록한 20개 기업의 새 공시 모아보기',
                    ]
                  : ['기업 정보 · 재무 · 스크리너 탐색', '관심기업 3개 저장', '관심기업의 새 공시 모아보기'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: premium ? c.accent : c.textSecondary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(item, style: t.body(13).copyWith(height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanComparison extends StatelessWidget {
  const _PlanComparison();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      child: Column(
        children: [
          for (final row in const [
            ['기능', '무료', '멤버십'],
            ['관심기업 등록', '3개', '20개'],
            ['광고', '표시', '제거'],
            ['기업 · 재무 탐색', '제공', '제공'],
            ['새 공시 모아보기', '제공', '제공'],
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              decoration: BoxDecoration(
                border: row[0] == '새 공시 모아보기'
                    ? null
                    : Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row[0],
                      style: t.body(12, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row[1],
                      textAlign: TextAlign.center,
                      style: t.body(13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row[2],
                      textAlign: TextAlign.center,
                      style: t.body(
                        13,
                        color: c.accent,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanQuestion extends StatelessWidget {
  const _PlanQuestion({required this.question, required this.answer});
  final String question;
  final String answer;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.background,
    child: ShadAccordion<int>(
      maintainState: true,
      children: [
        ShadAccordionItem<int>(
          value: 0,
          title: Text(
            question,
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
                        .body(13, color: context.colors.textSecondary)
                        .copyWith(height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
