import 'package:flutter/material.dart';

import 'components/components.dart';
import 'components/adaptive_detail.dart';
import 'tokens.dart';
import 'components/charts/app_sparkline.dart';

/// Fixed information overview, using synthetic fixtures for user review.
class CompactHomeReview extends StatefulWidget {
  const CompactHomeReview({super.key});
  @override
  State<CompactHomeReview> createState() => _CompactHomeReviewState();
}

class _CompactHomeReviewState extends State<CompactHomeReview> {
  String query = '';
  bool corrections = false;
  bool personal = true;
  int period = 0;
  static const companies = [
    ('가상기업 한빛', '반도체', '72,400', '+1.40%', '새 공시'),
    ('가상기업 새봄', '자동차', '184,500', '−0.81%', '정정'),
    ('가상기업 온유', '식품', '28,100', '+0.36%', ''),
    ('가상기업 다온', '기계', '45,200', '−1.09%', ''),
    ('가상기업 이음', '소프트웨어', '—', '—', '자료 준비 중'),
  ];
  static const trends = <String, List<double?>>{
    '코스피': [2595, 2604, 2588, 2612, 2625, 2608, 2619.92, 2641.4],
    '코스닥': [858, 852, 856, 844, 839, 846, 845.47, 842.6],
    '원/달러': [1348, 1353, 1350, 1362, 1358, 1365, 1355.67, 1359.6],
    '미국 국채 2년': [4.32, 4.28, 4.30, 4.23, 4.19, 4.21, 4.15, 4.12],
    '미국 국채 10년': [4.18, 4.20, 4.16, 4.24, 4.22, 4.26, 4.26, 4.28],
    '브렌트 원유': [81.2, 80.4, 82.1, 79.8, 80.3, 79.1, 79.06, 78.42],
  };
  String unit(String label) => label.contains('국채')
      ? '%'
      : label == '브렌트 원유'
      ? '달러/배럴'
      : label == '원/달러'
      ? '원/달러'
      : '지수';
  Widget gap([double h = AppSpace.md]) => SizedBox(height: h);
  Widget muted(String s) =>
      Text(s, style: context.typo.body(12, color: context.colors.textMuted));
  Widget toggle(String s, bool on, VoidCallback f) => IntrinsicWidth(
    child: ShadToggle.outline(value: on, onChanged: (_) => f(), child: Text(s)),
  );
  Widget link(String s, VoidCallback f) => ShadButton.link(
    size: ShadButtonSize.sm,
    onPressed: f,
    child: Flexible(
      child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
  Widget header(String s, String action, VoidCallback f) => Row(
    children: [
      Expanded(child: Text(s, style: context.typo.display(19))),
      link(action, f),
    ],
  );
  Widget columns(Widget left, Widget right) => LayoutBuilder(
    builder: (_, b) => b.maxWidth < 950
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, gap(AppSpace.lg), right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpace.lg),
              Expanded(child: right),
            ],
          ),
  );
  void detail(String title, {String? note}) => showAdaptiveDetail(
    context: context,
    builder: (c) => SizedBox(
      width: 470,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('상세 · 합성 예시', style: c.typo.label())),
                ShadButton.ghost(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
            gap(),
            Text(title, style: c.typo.display(25)),
            gap(),
            Text(
              note ?? '요약을 훑은 뒤 자료의 기간·기준·출처를 확인하는 위치입니다.',
              style: c.typo.body(14),
            ),
            gap(AppSpace.xl),
            if (trends.containsKey(title)) ...[
              Text('최근 1개월 · 관측값 8개 · 합성', style: c.typo.label()),
              gap(),
              AppLineChart.many(
                height: 180,
                includeZeroBaseline: false,
                categories: const ['1', '2', '3', '4', '5', '6', '7', '8'],
                formatValue: (v) => '${v.toStringAsFixed(2)} ${unit(title)}',
                series: [
                  ChartSeries(
                    label: title,
                    color: trendColor(title),
                    values: trends[title]!,
                  ),
                ],
              ),
              gap(),
              Text(
                title.contains('국채')
                    ? '연 수익률의 변화입니다. 채권 가격이나 보유 수익률이 아닙니다.'
                    : '${unit(title)} 단위의 관측값입니다.',
                style: c.typo.body(13),
              ),
              gap(),
            ],
            AppDataTable(
              columns: const [
                AppColumn('확인 항목'),
                AppColumn('표시 내용', flex: true),
              ],
              rows: const [
                AppRow([Text('데이터'), Text('모든 값·기업·일정은 합성')]),
                AppRow([Text('시세 기준'), Text('전 거래일 종가 · 실시간 아님')]),
                AppRow([Text('자료 범위'), Text('수집된 자료만 표시')]),
                AppRow([Text('근거'), Text('실서비스에서 공식 원문 연결')]),
              ],
            ),
            gap(),
            muted('운영 계정·데이터를 변경하지 않는 리뷰 화면입니다.'),
          ],
        ),
      ),
    ),
  );
  Widget change(String s) => Text(
    s,
    style: context.typo.numeric(
      13,
      color: s.startsWith('+')
          ? context.colors.marketUp
          : s.startsWith('−')
          ? context.colors.marketDown
          : context.colors.textMuted,
    ),
  );
  Widget metric(
    String label,
    String value,
    String delta,
    String date,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: ShadButton.link(
          size: ShadButtonSize.sm,
          padding: EdgeInsets.zero,
          onPressed: () => detail(label),
          child: Text(
            label,
            style: context.typo.body(12, weight: FontWeight.w600),
          ),
        ),
      ),
      Text(value, style: context.typo.numeric(21)),
      gap(AppSpace.xs),
      change(delta),
      gap(AppSpace.sm),
      AppSparkline(
        values: trends[label]!,
        color: trendColor(label),
        description:
            '$label 최근 1개월 합성 추이. 시작 ${trends[label]!.first}, 최근 ${trends[label]!.last} ${unit(label)}. 항목별 독립 눈금.',
      ),
      gap(AppSpace.xs),
      muted(date),
    ],
  );
  Color trendColor(String label) {
    final samples = trends[label]!
        .whereType<double>()
        .where((v) => v.isFinite)
        .toList();
    if (samples.length < 2 || samples.last == samples.first) {
      return context.colors.textMuted;
    }
    return samples.last > samples.first
        ? context.colors.marketUp
        : context.colors.marketDown;
  }

  Widget marketStrip() => LayoutBuilder(
    builder: (_, b) {
      final n = b.maxWidth >= 1200
          ? 6
          : b.maxWidth >= 600
          ? 3
          : b.maxWidth >= 340
          ? 2
          : 1;
      final width = (b.maxWidth - AppSpace.lg * (n - 1)) / n;
      return Wrap(
        spacing: AppSpace.lg,
        runSpacing: AppSpace.lg,
        children: [
          for (final e in [
            ('코스피', '2,641.4', '+0.82%', '전일 종가 · 합성'),
            ('코스닥', '842.6', '−0.34%', '전일 종가 · 합성'),
            ('원/달러', '1,359.6', '+0.29%', '원/달러 · 전일 · 합성'),
            ('미국 국채 2년', '4.12%', '−0.03%p', '연 수익률 · 전일 · 합성'),
            ('미국 국채 10년', '4.28%', '+0.02%p', '연 수익률 · 전일 · 합성'),
            ('브렌트 원유', '78.42', '−0.81%', '달러/배럴 · 전일 · 합성'),
          ])
            SizedBox(width: width, child: metric(e.$1, e.$2, e.$3, e.$4)),
        ],
      );
    },
  );
  Widget markets() => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header('시장 흐름', '시장 상세', () => detail('시장 상세')),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            toggle('1개월', period == 0, () => setState(() => period = 0)),
            toggle('3개월', period == 1, () => setState(() => period = 1)),
            toggle('1년', period == 2, () => setState(() => period = 2)),
          ],
        ),
        gap(AppSpace.sm),
        ChartLegend(
          series: [
            ChartSeries(
              label: '코스피',
              color: context.colors.chartSeries1,
              values: const [],
            ),
            ChartSeries(
              label: '코스닥',
              color: context.colors.chartSeries2,
              values: const [],
            ),
          ],
        ),
        gap(AppSpace.sm),
        AppLineChart.many(
          height: 150,
          includeZeroBaseline: false,
          categories: period == 0
              ? const ['1주', '2주', '3주', '4주', '최근']
              : period == 1
              ? const ['1개월', '2개월', '3개월', '최근−1', '최근']
              : const ['1분기', '2분기', '3분기', '4분기', '최근'],
          formatValue: (v) => v.toStringAsFixed(1),
          series: [
            ChartSeries(
              label: '코스피',
              color: context.colors.chartSeries1,
              values: period == 0
                  ? const [100, 101.4, 100.8, 102.1, 102.9]
                  : period == 1
                  ? const [100, 99.1, 101.2, 102.8, 104.1]
                  : const [100, 104, 102, 108, 110],
            ),
            ChartSeries(
              label: '코스닥',
              color: context.colors.chartSeries2,
              values: period == 0
                  ? const [100, 99.4, 100.3, 99.1, 99.8]
                  : period == 1
                  ? const [100, 101, 99.2, 98.8, 101.1]
                  : const [100, 98, 102, 103, 105],
            ),
          ],
        ),
        muted('선택 기간 시작=100 · 같은 기간의 변화 비교 · 합성'),
        gap(),
        const Divider(),
        gap(AppSpace.sm),
        Row(
          children: [
            Expanded(child: Text('업종별 흐름', style: context.typo.label())),
            muted('전일 대비 · 합성'),
          ],
        ),
        gap(AppSpace.sm),
        for (final e in [
          ('반도체', '+1.24%'),
          ('자동차', '−0.62%'),
          ('기계', '+0.48%'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Row(
              children: [
                Expanded(child: Text(e.$1, style: context.typo.body(13))),
                change(e.$2),
              ],
            ),
          ),
        gap(AppSpace.sm),
        muted('업종 수익률은 신규 집계 필요 · 시안에서만 제공'),
      ],
    ),
  );
  Widget watchlist() => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header('내 관심기업', '관심 설정', () => settings()),
        if (!personal) ...[
          gap(AppSpace.xl),
          Text(
            '관심기업을 담으면 시세와 새 공시를 함께 볼 수 있습니다.',
            style: context.typo.body(14),
          ),
          gap(),
          Align(
            alignment: Alignment.centerLeft,
            child: ShadButton.outline(
              onPressed: () => setState(() => personal = true),
              child: const Text('예시 관심기업 보기'),
            ),
          ),
          gap(AppSpace.xxl),
        ] else ...[
          ShadInput(
            placeholder: const Text('관심기업 검색'),
            onChanged: (v) => setState(() => query = v),
          ),
          gap(AppSpace.sm),
          LayoutBuilder(
            builder: (_, b) {
              final compact = b.maxWidth < 500;
              final filtered = companies
                  .where((e) => e.$1.contains(query) || e.$2.contains(query))
                  .toList();
              return filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xxl,
                      ),
                      child: Text(
                        '일치하는 관심기업이 없습니다.',
                        style: context.typo.body(14),
                      ),
                    )
                  : AppDataTable(
                      columns: [
                        const AppColumn('기업', flex: true),
                        const AppColumn('종가 · 원', numeric: true),
                        const AppColumn('등락', numeric: true),
                        if (!compact) const AppColumn('새 소식'),
                      ],
                      rows: [
                        for (final e in filtered)
                          AppRow([
                            compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: link(e.$1, () => detail(e.$1)),
                                      ),
                                      muted(
                                        e.$5.isNotEmpty
                                            ? '${e.$2} · ${e.$5}'
                                            : e.$2,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: link(e.$1, () => detail(e.$1)),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.sm),
                                      muted(e.$2),
                                    ],
                                  ),
                            Text(e.$3, style: context.typo.numeric(13)),
                            change(e.$4),
                            if (!compact)
                              Text(
                                e.$5.isEmpty ? '—' : e.$5,
                                style: context.typo.body(12),
                              ),
                          ]),
                      ],
                    );
            },
          ),
          gap(AppSpace.sm),
          muted('전 거래일 종가 · 실시간 아님 · 기업·가격은 합성'),
          gap(AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              ShadBadge.outline(child: const Text('반도체')),
              ShadBadge.outline(child: const Text('자동차')),
              ShadBadge.outline(child: const Text('환율')),
            ],
          ),
          gap(AppSpace.sm),
          muted('관심 주제 · 직접 선택한 예시'),
        ],
      ],
    ),
  );
  void settings() => showAdaptiveDetail(
    context: context,
    builder: (c) => SizedBox(
      width: 440,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('관심 영역 리뷰', style: c.typo.display(24)),
            gap(),
            const Text(
              '관심기업이 있는 상태와 아직 없는 상태를 비교할 수 있습니다. 계정 저장 기능은 연결하지 않았습니다.',
            ),
            gap(),
            ShadButton.outline(
              onPressed: () {
                setState(() => personal = !personal);
                Navigator.of(c).pop();
              },
              child: Text(personal ? '관심기업 없는 상태 보기' : '예시 관심기업 보기'),
            ),
            gap(),
            ShadButton.ghost(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget item(String left, String title, String sub, {String? badge}) =>
      LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 520;
          final date = Text(
            left,
            maxLines: 1,
            softWrap: false,
            style: context.typo.body(12, color: context.colors.textMuted),
          );
          final status = SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.centerRight,
              child: badge == null
                  ? const SizedBox.shrink()
                  : ShadBadge.outline(child: Text(badge)),
            ),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ShadButton.link(
                  size: ShadButtonSize.sm,
                  padding: EdgeInsets.zero,
                  onPressed: () => detail(title, note: sub),
                  child: Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.body(12, color: context.colors.textMuted),
                ),
              ),
            ],
          );
          return Padding(
            key: ValueKey('overview-row-$title'),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 28,
                        child: Row(
                          children: [
                            Expanded(child: date),
                            status,
                          ],
                        ),
                      ),
                      content,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 32,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: date,
                        ),
                      ),
                      Expanded(child: content),
                      const SizedBox(width: AppSpace.sm),
                      SizedBox(height: 32, child: status),
                    ],
                  ),
          );
        },
      );
  Widget filings() => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header(
          '최근 공시',
          '수집 범위',
          () => detail(
            '최근 공시 범위',
            note: '현재 서비스의 recentFilings는 수집된 정기보고서입니다. 실시간 전체 DART 피드나 뉴스 피드로 표현하지 않습니다.',
          ),
        ),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            toggle(
              '전체',
              !corrections,
              () => setState(() => corrections = false),
            ),
            toggle('정정', corrections, () => setState(() => corrections = true)),
          ],
        ),
        gap(AppSpace.sm),
        if (!corrections)
          item(
            '예시 10/03',
            '가상기업 한빛 · 반기보고서',
            '2026 상반기 · 연결 · 원문 수집',
            badge: personal ? '관심' : null,
          ),
        item(
          '예시 10/03',
          '가상기업 새봄 · 정정 반기보고서',
          '2026 상반기 · 정정 내용 확인 필요',
          badge: '정정',
        ),
        if (!corrections) ...[
          item('예시 10/02', '가상기업 온유 · 사업보고서', '2025 연간 · 재무 수집 대기'),
          item('예시 10/02', '가상기업 다온 · 반기보고서', '2026 상반기 · 원문 수집'),
        ],
        gap(AppSpace.sm),
        muted('최근 수집 정기보고서 · 접수순 · 실시간 전체 공시 아님'),
      ],
    ),
  );
  Widget calendar() => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header(
          '주요 일정',
          '일정 기준',
          () => detail(
            '주요 일정 기준',
            note: '경제 일정 API는 아직 서비스에 없습니다. 공식 기관 일정 수집을 별도로 구현해야 합니다. 시각은 한국 시각으로 표시하고, 시각 경과만으로 발표 완료 처리하지 않습니다.',
          ),
        ),
        muted('한국 시각 · 공식 발표 일정 연결 예정'),
        gap(),
        item(
          '예시 내일',
          '미국 정책금리 결정',
          '03:00 · 정책 결정 / 03:30 · 기자회견',
          badge: '예정',
        ),
        const Divider(),
        item('예시 이번 주', '미국 소비자물가', '21:30 · 지난달 자료 · 예상치 제공 안 함', badge: '예정'),
        const Divider(),
        item('예시 이번 주', '국내 수출 통계', '시각 미정 · 공식 일정 확인 필요', badge: '미확인'),
        gap(),
        muted('합성 일정 · 미래 일정은 변경될 수 있습니다.'),
      ],
    ),
  );
  Future<void> openNavigation() => showShadSheet<void>(
    context: context,
    useRootNavigator: true,
    side: ShadSheetSide.left,
    barrierLabel: '메뉴 닫기',
    builder: (_) => InheritedTheme.captureAll(
      context,
      Builder(
        builder: (sheetContext) => ShadSheet(
          closeIcon: const SizedBox.shrink(),
          scrollable: true,
          child: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('알파인더', style: context.typo.display(21)),
                    ),
                    ShadButton.ghost(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('메뉴 닫기'),
                    ),
                  ],
                ),
                gap(AppSpace.lg),
                for (final label in ['홈', '시장', '기업', '기업 찾기', '비교', '관계망'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: ShadButton.ghost(
                      leading: Icon(destinationIcon(label), size: 20),
                      backgroundColor: label == '홈'
                          ? context.colors.accentSubtle
                          : null,
                      foregroundColor: label == '홈'
                          ? context.colors.accent
                          : null,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        if (label != '홈') {
                          detail(
                            '$label 진입',
                            note: '실서비스에서는 기존 URL로 이동합니다. 독립 시안에서는 데이터와 계정을 변경하지 않습니다.',
                          );
                        }
                      },
                      child: Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(label == '홈' ? '홈 · 현재' : label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  IconData destinationIcon(String label) => switch (label) {
    '홈' => Icons.home_outlined,
    '시장' => Icons.bar_chart_outlined,
    '기업' => Icons.business_outlined,
    '기업 찾기' => Icons.filter_alt_outlined,
    '비교' => Icons.compare_arrows_outlined,
    _ => Icons.hub_outlined,
  };

  Widget navigationHeader() => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 1100;
      return Container(
        key: const ValueKey('fixed-navigation-header'),
        height: 64,
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(bottom: BorderSide(color: context.colors.border)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: PageFrame.gutter(box.maxWidth),
        ),
        child: Row(
          children: [
            if (!wide) ...[
              ShadButton.ghost(
                leading: const Icon(Icons.menu, size: 20),
                onPressed: openNavigation,
                child: const Text('메뉴'),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Text('알파인더', style: context.typo.display(21)),
            if (wide) ...[
              const SizedBox(width: AppSpace.xl),
              for (final label in ['홈', '시장', '기업', '기업 찾기', '비교', '관계망'])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: ShadButton.ghost(
                    backgroundColor: label == '홈'
                        ? context.colors.accentSubtle
                        : null,
                    foregroundColor: label == '홈'
                        ? context.colors.accent
                        : null,
                    onPressed: () {
                      if (label != '홈') {
                        detail(
                          '$label 진입',
                          note: '실서비스에서는 기존 URL로 이동합니다. 독립 시안입니다.',
                        );
                      }
                    },
                    child: Text(label),
                  ),
                ),
            ] else ...[
              const Spacer(),
              ShadBadge.outline(child: const Text('홈')),
            ],
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: SafeArea(bottom: false, child: navigationHeader()),
    ),
    body: PageFrame(
      children: [
        Text('한눈에 보기', style: context.typo.display(27)),
        gap(AppSpace.xs),
        muted('시장 전체와 내 관심기업을 함께 확인합니다. · 모든 데이터는 합성 예시'),
        gap(AppSpace.lg),
        marketStrip(),
        gap(AppSpace.sm),
        muted(
          '작은 선: 1개월 시작 대비 상승 빨강·하락 파랑 · 항목별 독립 눈금 · 전일 등락과 기준 다름 · 이름을 누르면 상세',
        ),
        gap(AppSpace.lg),
        const Divider(),
        gap(AppSpace.lg),
        columns(markets(), watchlist()),
        gap(AppSpace.lg),
        columns(filings(), calendar()),
        gap(AppSpace.lg),
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.sm,
          children: [
            muted('원천·기준일은 항목별 확인'),
            link(
              '데이터 안내',
              () => detail(
                '데이터 안내',
                note: '자료의 수집·대기·실패와 최신 관측일을 따로 확인합니다. 이번 시안은 운영 수집 상태를 조회하지 않았습니다.',
              ),
            ),
            muted('리뷰 시안 · 운영 배포 전 · 로그인/알림/저장 미연결'),
          ],
        ),
        gap(AppSpace.lg),
      ],
    ),
  );
}
