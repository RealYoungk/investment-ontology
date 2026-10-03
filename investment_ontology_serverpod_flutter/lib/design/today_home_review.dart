import 'package:flutter/material.dart';

import 'components/components.dart';
import 'components/adaptive_detail.dart';
import 'tokens.dart';

/// Synthetic, independent home review. No production data or account access.
class TodayHomeReview extends StatefulWidget {
  const TodayHomeReview({super.key});
  @override
  State<TodayHomeReview> createState() => _TodayHomeReviewState();
}

class _TodayHomeReviewState extends State<TodayHomeReview> {
  int scenario = 0;
  bool delayed = false;
  Set<String> interests = {'반도체', '환율', '가상기업 한빛'};
  Widget gap([double h = AppSpace.lg]) => SizedBox(height: h);
  Widget muted(String text) =>
      Text(text, style: context.typo.body(13, color: context.colors.textMuted));
  Widget heading(String text) => Text(text, style: context.typo.display(22));
  Widget toggle(String label, bool selected, VoidCallback action) =>
      IntrinsicWidth(
        child: ShadToggle.outline(
          value: selected,
          onChanged: (_) => action(),
          child: Text(label),
        ),
      );
  Widget split(Widget a, Widget b) => LayoutBuilder(
    builder: (_, box) => box.maxWidth < 850
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [a, gap(AppSpace.xxl), b],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: a),
              const SizedBox(width: AppSpace.xxl),
              Expanded(flex: 4, child: b),
            ],
          ),
  );
  void detail(String title) => showAdaptiveDetail(
    context: context,
    builder: (c) => SizedBox(
      width: 440,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('근거와 확인 상태', style: c.typo.label())),
                ShadButton.ghost(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
            gap(),
            Text(title, style: c.typo.display(26)),
            gap(),
            const Text('일정·수치·기업은 모두 합성 예시입니다.'),
            gap(),
            const Text(
              '실서비스 연결 시 제공할 항목\n\n• 공식 발표 원문과 자료 대상 기간\n• 원 발표 시각과 한국 시각\n• 원문 확인 시각과 수집 상태\n• 이전 값·정정 이력·단위\n• 홈에 표시한 이유',
            ),
            gap(),
            muted('선정 이유: 공통 주요 일정 또는 직접 선택한 관심사. 시장 움직임의 원인으로 단정하지 않습니다.'),
          ],
        ),
      ),
    ),
  );
  void settings() {
    final draft = Set<String>.of(interests);
    showAdaptiveDetail(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => SizedBox(
          width: 440,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('내 관심사', style: c.typo.display(26)),
                gap(),
                const Text('주제·지표·기업을 직접 선택하세요.'),
                gap(),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final label in [
                      '반도체',
                      '자동차',
                      '환율',
                      '금리',
                      '가상기업 한빛',
                      '가상기업 새봄',
                    ])
                      toggle(
                        label,
                        draft.contains(label),
                        () => update(() {
                          draft.contains(label)
                              ? draft.remove(label)
                              : draft.add(label);
                        }),
                      ),
                  ],
                ),
                gap(),
                muted('리뷰 시안에서만 유지됩니다. 계정 저장은 아직 연결하지 않았습니다.'),
                gap(),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    ShadButton.ghost(
                      onPressed: () => update(draft.clear),
                      child: const Text('모두 해제'),
                    ),
                    ShadButton.outline(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('취소'),
                    ),
                    ShadButton(
                      onPressed: () {
                        setState(() => interests = Set.of(draft));
                        Navigator.of(c).pop();
                      },
                      child: const Text('적용'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget event(String time, String title, String note) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 66, child: Text(time, style: context.typo.numeric(14))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.typo.body(15, weight: FontWeight.w600),
              ),
              gap(AppSpace.xs),
              muted(note),
            ],
          ),
        ),
        Semantics(
          container: true,
          label: '$title 상세 열기',
          button: true,
          onTap: () => detail(title),
          child: ExcludeSemantics(
            child: ShadIconButton.ghost(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => detail(title),
            ),
          ),
        ),
      ],
    ),
  );
  Widget metric(String title, String value, String unit, List<double> values) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.typo.label())),
              ShadButton.link(
                onPressed: () => detail(title),
                child: const Text('근거'),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(value, style: context.typo.numeric(28)),
              muted(unit),
            ],
          ),
          gap(AppSpace.sm),
          AppLineChart.many(
            height: 130,
            includeZeroBaseline: false,
            categories: const ['월', '화', '수', '목', '금'],
            formatValue: (v) => '${v.toStringAsFixed(2)} $unit · 합성',
            series: [
              ChartSeries(
                label: title,
                color: context.colors.chartSeries1,
                values: values,
              ),
            ],
          ),
          muted(delayed ? '최근 수집 실패 · 이전 관측값 유지' : '전일 관측 · 일별 자료 · 합성'),
        ],
      );
  @override
  Widget build(BuildContext context) {
    final quiet = scenario == 2;
    final hasCompany = interests.contains('가상기업 한빛');
    final released = scenario == 1 && !delayed;
    final title = quiet
        ? (hasCompany ? '오늘은 관심기업의 변화를 확인하세요' : '다음 주요 일정을 미리 확인하세요')
        : released
        ? '금리 결정이 발표됐습니다'
        : delayed
        ? '발표 예정 시각이 지났습니다'
        : '오늘 밤, 금리 결정이 예정되어 있습니다';
    return Scaffold(
      body: PageFrame(
        children: [
          Wrap(
            spacing: AppSpace.xxl,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('알파인더', style: context.typo.display(22)),
              muted('홈 리뷰 시안 · 모든 일정과 수치는 합성'),
            ],
          ),
          gap(),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final e in [(0, '발표 전'), (1, '발표 후'), (2, '큰 발표 없는 날')])
                toggle(
                  e.$2,
                  scenario == e.$1,
                  () => setState(() {
                    scenario = e.$1;
                    delayed = false;
                  }),
                ),
              toggle(
                '자료 확인 지연',
                delayed,
                () => setState(() => delayed = !delayed),
              ),
            ],
          ),
          gap(AppSpace.xxl),
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('오늘 챙길 것', style: context.typo.display(32)),
              muted('예시 날짜 · 한국 시각 기준'),
            ],
          ),
          gap(AppSpace.sm),
          muted('주요 발표 일정과 확인된 자료, 내 관심사의 새 소식을 한곳에서.'),
          gap(AppSpace.xxl),
          split(
            DataPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShadBadge.outline(
                      child: Text(
                        quiet
                            ? (hasCompany ? '관심기업 업데이트' : '다음 주요 일정')
                            : released
                            ? '원문 확인 · 합성'
                            : delayed
                            ? '원문 확인 대기'
                            : '공통 주요 일정',
                      ),
                    ),
                  ),
                  gap(),
                  Text(title, style: context.typo.display(28)),
                  gap(),
                  Text(
                    quiet
                        ? (hasCompany
                              ? '가상기업 한빛 · 새 반기보고서\n내가 선택한 기업에 새 공시가 들어왔습니다.'
                              : '오늘 확인한 일정 범위에는 큰 발표가 없습니다.\n다음 소비자물가 발표와 수출 통계를 확인하세요.')
                        : released
                        ? '정책금리 4.00–4.25%\n이전 4.25–4.50% → 이번 4.00–4.25%'
                        : delayed
                        ? '예정 03:00 · 실제 발표 여부 미확인\n공식 원문이 확인되면 결과를 표시합니다.'
                        : '03:00 · 정책 결정 / 03:30 · 기자회견\n발표 전에는 이전 확인값만 제공합니다.',
                    style: context.typo.body(16),
                  ),
                  gap(),
                  muted(
                    quiet
                        ? (hasCompany
                              ? '선정 이유 · 내 관심기업의 새 공시'
                              : '선정 이유 · 다음 공통 주요 일정')
                        : '선정 이유 · 오늘 확인할 공통 주요 정책 일정',
                  ),
                  gap(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShadButton(
                      onPressed: () => detail(title),
                      child: Text(
                        quiet
                            ? (hasCompany ? '보고서 확인' : '다음 일정 확인')
                            : released
                            ? '발표 내용과 근거'
                            : '일정과 이전 값',
                      ),
                    ),
                  ),
                  gap(AppSpace.sm),
                  muted('공식 원문 연결 예정 · 합성 시나리오'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading('이어서 챙길 일정'),
                gap(),
                event(
                  quiet ? '내일' : '03:30',
                  '정책 결정 기자회견',
                  '정책 결정과 별개 일정 · 합성',
                ),
                const Divider(),
                event('내일', '소비자물가 발표', '자료 대상 기간: 지난달 · 합성'),
                const Divider(),
                event('이번 주', '국내 수출 통계', '예정일 변경 가능 · 합성'),
                gap(),
                muted(
                  quiet
                      ? '오늘 확인한 일정 범위에는 큰 발표가 없습니다.'
                      : '시간 경과만으로 발표 완료 처리하지 않습니다.',
                ),
              ],
            ),
          ),
          gap(AppSpace.section),
          heading(quiet ? '꾸준히 보는 시장 흐름' : '함께 확인할 지표'),
          gap(AppSpace.sm),
          muted(
            quiet
                ? '일별 관측값으로 시장 맥락을 짧게 확인합니다.'
                : '금리 일정과 함께 볼 지표입니다. 가격 변화의 원인으로 단정하지 않습니다.',
          ),
          gap(),
          split(
            metric('미국 국채 2년', '4.12', '%', [4.23, 4.21, 4.19, 4.15, 4.12]),
            metric('원/달러 환율', '1,359.60', '원/달러', [
              1348,
              1353,
              1350,
              1362,
              1359.6,
            ]),
          ),
          gap(AppSpace.section),
          Row(
            children: [
              Expanded(child: heading('내 관심사에서')),
              ShadButton.outline(
                onPressed: settings,
                child: const Text('관심사 편집'),
              ),
            ],
          ),
          gap(),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final label in interests)
                ShadBadge.outline(child: Text(label)),
            ],
          ),
          gap(),
          if (interests.isEmpty)
            const Text('관심사를 고르면 관련 업데이트를 모아드립니다.')
          else ...[
            if (interests.contains('가상기업 한빛'))
              event('새 공시', '가상기업 한빛 · 반기보고서', '관심기업에 새 공시가 도착함 · 합성'),
            if (interests.contains('반도체'))
              event('자료', '반도체 · 월별 수출 자료', '직접 선택한 주제와 연결 · 합성'),
            if (interests.contains('환율'))
              event('지표', '원/달러 · 새 관측값', '직접 선택한 지표 · 관측일과 수집일 구분 · 합성'),
            if (!interests.any({'가상기업 한빛', '반도체', '환율'}.contains))
              const Text('선택한 관심사에 새로 확인된 자료가 없습니다.'),
          ],
          gap(AppSpace.xxl),
          const Divider(),
          gap(),
          muted('독립 리뷰 화면입니다. 경제 일정 수집과 관심 주제 저장은 아직 서비스에 연결되지 않았습니다.'),
          gap(AppSpace.xxl),
        ],
      ),
    );
  }
}
