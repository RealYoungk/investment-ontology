import 'package:flutter/material.dart';

import 'components/components.dart';
import 'components/adaptive_detail.dart';
import 'tokens.dart';

/// Synthetic home compositions using production widgets. No client/auth imports.
class HomeConceptGallery extends StatefulWidget {
  const HomeConceptGallery({super.key});
  @override
  State<HomeConceptGallery> createState() => _HomeConceptGalleryState();
}

class _HomeConceptGalleryState extends State<HomeConceptGallery> {
  int _concept = 2;
  bool _corrected = false;
  String _query = '';
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _detail(String title) => showAdaptiveDetail(
    context: context,
    builder: (context) => SizedBox(
      width: 430,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('합성 큐레이션 상세', style: context.typo.label()),
                ),
                Semantics(
                  container: true,
                  label: '상세 닫기',
                  button: true,
                  onTap: () => Navigator.of(context).pop(),
                  child: ExcludeSemantics(
                    child: ShadIconButton.ghost(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Text(title, style: context.typo.display(26)),
            const SizedBox(height: AppSpace.lg),
            Text(
              '가상기업 한빛 · 연결 · 2026 상반기\n모든 값과 보고서는 합성 예시입니다.',
              style: context.typo.body(14),
            ),
            const SizedBox(height: AppSpace.xl),
            _chart(context, 180),
            const SizedBox(height: AppSpace.xl),
            AppDataTable(
              columns: const [
                AppColumn('지표'),
                AppColumn('2025 상반기', numeric: true),
                AppColumn('2026 상반기', numeric: true),
              ],
              rows: const [
                AppRow([Text('매출 · 억원 예시'), Text('100'), Text('118')]),
                AppRow([Text('영업현금흐름 · 억원 예시'), Text('30'), Text('27.3')]),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              '실제 구현 시 원문 출처·계산 입력·수집 상태를 제공할 위치입니다. 서비스의 계정·데이터를 변경하지 않습니다.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _link(String label, String detail) => ShadButton.link(
    onPressed: () => _detail(detail),
    child: Flexible(child: Text(label)),
  );

  Widget _label(BuildContext context, String text) =>
      Text(text, style: context.typo.label(color: context.colors.accent));
  Widget _gap([double size = AppSpace.lg]) => SizedBox(height: size);

  Widget _section(BuildContext context, String title, {Widget? trailing}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.lg),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.typo.display(21))),
            ?trailing,
          ],
        ),
      );

  Widget _split(
    Widget left,
    Widget right, {
    int leftFlex = 6,
    double breakpoint = 850,
  }) => LayoutBuilder(
    builder: (context, box) => box.maxWidth < breakpoint
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, _gap(AppSpace.xl), right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: AppSpace.xxl),
              Expanded(flex: 10 - leftFlex, child: right),
            ],
          ),
  );

  Widget _chart(BuildContext context, double height) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ChartLegend(
        series: [
          ChartSeries(
            label: '매출 · 억원 예시',
            color: context.colors.chartSeries1,
            values: const [],
          ),
          ChartSeries(
            label: '영업현금흐름 · 억원 예시',
            color: context.colors.chartSeries2,
            values: const [],
          ),
        ],
      ),
      _gap(AppSpace.sm),
      AppLineChart.many(
        height: height,
        categories: const ['2024 상', '2024 하', '2025 상', '2025 하', '2026 상'],
        formatValue: (v) => '${v.toStringAsFixed(1)}억원 · 합성',
        series: [
          ChartSeries(
            label: '매출',
            color: context.colors.chartSeries1,
            values: const [81, 93, 100, 108, 118],
          ),
          ChartSeries(
            label: '영업현금흐름',
            color: context.colors.chartSeries2,
            values: const [24, 31, 30, 28, 27.3],
          ),
        ],
      ),
    ],
  );

  Widget _lead(BuildContext context, {bool panel = false, bool chart = true}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ShadBadge.outline(child: const Text('재무 변화 · 합성 예시')),
        ),
        _gap(),
        Text(
          panel ? '매출은 늘었는데,\n현금흐름은 달랐어요.' : '매출은 늘었는데,\n현금은 어디로 갔을까?',
          style: context.typo.display(panel ? 30 : 34),
        ),
        _gap(),
        Text(
          '가상기업 한빛의 같은 기간 매출과 영업현금흐름을\n비교하고, 숫자의 근거를 함께 확인하세요.',
          style: context.typo.body(14, color: context.colors.textSecondary),
        ),
        _gap(AppSpace.xl),
        if (chart)
          _chart(context, 155)
        else
          Text('매출 +18%   /   영업현금흐름 −9%', style: context.typo.numeric(19)),
        _gap(),
        Text(
          '2026 상반기 · 연결 · 전년 동기 대비 · 합성 보고서',
          style: context.typo.body(11, color: context.colors.textMuted),
        ),
        _gap(AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: _link('변화와 근거 살펴보기 →', '매출과 현금흐름의 변화'),
        ),
      ],
    );
    return panel ? DataPanel(child: content) : content;
  }

  Widget _row(
    BuildContext context,
    String title,
    String subtitle, {
    String? stamp,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.border)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadButton.link(
                onPressed: () => _detail(title),
                padding: EdgeInsets.zero,
                child: Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: context.typo.body(16, weight: FontWeight.w600),
                  ),
                ),
              ),
              Text(
                subtitle,
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (stamp != null)
          Text(
            stamp,
            style: context.typo.body(11, color: context.colors.textMuted),
          ),
      ],
    ),
  );

  Widget _watch(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(context, '내 기업의 소식'),
      Text(
        '관심기업 3개 · 개인화 합성 예시',
        style: context.typo.body(12, color: context.colors.textMuted),
      ),
      _row(context, '가상기업 한빛', '반기 재무 데이터 수집 완료', stamp: '2시간 전'),
      _row(context, '가상기업 새봄', '정정 보고서 · 이전 보고서 보존', stamp: '어제'),
      _row(context, '가상기업 온유', '새로 수집된 보고서가 없어요.', stamp: '변화 없음'),
      _gap(),
      Align(
        alignment: Alignment.centerLeft,
        child: _link('관심기업 전체 보기 →', '내 기업의 소식'),
      ),
    ],
  );

  Widget _market(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth < 600
          ? (box.maxWidth - AppSpace.lg) / 2
          : (box.maxWidth - AppSpace.lg * 3) / 4;
      return Wrap(
        spacing: AppSpace.lg,
        runSpacing: AppSpace.lg,
        children: [
          for (final item in const [
            ('코스피', '2,840.21', '+0.64%', true),
            ('코스닥', '812.35', '−0.28%', false),
            ('원/달러', '1,320.50', '−0.12%', false),
            ('국채 3년', '2.81%', '+0.02%p', true),
          ])
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.$1} · 예시',
                    style: context.typo.body(
                      11,
                      color: context.colors.textMuted,
                    ),
                  ),
                  _gap(AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.$2, style: context.typo.numeric(20)),
                      Text(
                        item.$3,
                        style: context.typo.numeric(
                          12,
                          color: item.$4
                              ? context.colors.marketUp
                              : context.colors.marketDown,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  static const _collections = [
    (
      '01',
      '매출과 현금이\n함께 늘어난 기업',
      '같은 기간 · 같은 재무 기준으로 비교',
      '24개사 · 합성',
      Icons.trending_up,
    ),
    ('02', '배당을\n이어온 기업', '최근 3개년 배당과 이익을 함께 확인', '36개사 · 합성', Icons.bar_chart),
    (
      '03',
      '새 보고서로\n다시 볼 기업',
      '새로 수집된 보고서부터 탐색',
      '12개사 · 합성',
      Icons.description_outlined,
    ),
  ];

  Widget _collectionsView(BuildContext context, {bool large = false}) =>
      LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth < 700
              ? box.maxWidth
              : (box.maxWidth - AppSpace.lg * 2) / 3;
          return Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.lg,
            children: [
              for (final item in _collections)
                SizedBox(
                  width: width,
                  child: DataPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (large) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.$1,
                                style: context.typo.numeric(
                                  32,
                                  color: context.colors.textMuted,
                                ),
                              ),
                              Icon(
                                item.$5,
                                size: 45,
                                color: context.colors.accent,
                              ),
                            ],
                          ),
                          _gap(AppSpace.xl),
                        ],
                        Text(
                          large ? item.$2 : item.$2.replaceAll('\n', ' '),
                          style: context.typo.display(large ? 22 : 18),
                        ),
                        _gap(AppSpace.sm),
                        Text(
                          item.$3,
                          style: context.typo.body(
                            12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        _gap(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$4,
                                style: context.typo.body(
                                  11,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ),
                            ShadButton.ghost(
                              onPressed: () =>
                                  _detail(item.$2.replaceAll('\n', ' ')),
                              child: const Text('살펴보기 ↗'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget _reports(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        context,
        '새로 들어온 보고서',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicWidth(
              child: ShadToggle.outline(
                value: !_corrected,
                onChanged: (_) => setState(() => _corrected = false),
                child: const Text('전체'),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            IntrinsicWidth(
              child: ShadToggle.outline(
                value: _corrected,
                onChanged: (_) => setState(() => _corrected = true),
                child: const Text('정정'),
              ),
            ),
          ],
        ),
      ),
      Text(
        '접수 시각과 수집 완료는 다릅니다. 아래는 합성 상태입니다.',
        style: context.typo.body(12, color: context.colors.textMuted),
      ),
      if (!_corrected)
        _row(context, '가상기업 한빛', '반기보고서 · 2026.06 · 합성', stamp: '수집 완료'),
      _row(context, '가상기업 새봄', '[기재정정] 반기보고서 · 합성', stamp: '수집 대기'),
    ],
  );

  List<Widget> _body(BuildContext context) {
    final a = _concept == 0, b = _concept == 1;
    return [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpace.lg,
        runSpacing: AppSpace.sm,
        children: [
          _label(
            context,
            a
                ? 'THE DAILY RESEARCH'
                : b
                ? 'DISCOVER COMPANIES'
                : 'YOUR RESEARCH, CURATED',
          ),
          Text(
            '2026.10.03 · 예시',
            style: context.typo.body(11, color: context.colors.textMuted),
          ),
        ],
      ),
      _gap(),
      PageHeading(
        title: a
            ? '오늘의 변화를 읽다.'
            : b
            ? '숫자 뒤의 기업을 발견하세요.'
            : '오늘, 다시 볼 기업들.',
        subtitle: '내 기업의 소식부터 새로운 발견까지. 중요한 변화와 그 근거를 모았어요.',
      ),
      _gap(AppSpace.xxl),
      if (a) ...[
        _split(
          _lead(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, '보고서 갱신'),
              _row(context, '정정 보고서, 무엇이 달라졌을까요?', '가상기업 새봄 · 합성 보고서'),
              _gap(AppSpace.xl),
              _label(context, '주주환원'),
              _row(context, '배당을 이익과 함께 읽어보세요.', '가상기업 온유 · 최근 3개년 예시'),
            ],
          ),
        ),
        _gap(AppSpace.section),
        _split(
          _watch(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, '기업을 발견하는 다른 방법'),
              _row(context, '매출과 현금이 함께 늘어난 기업', '같은 기간 · 같은 재무 기준'),
              _row(context, '배당을 이어온 기업', '최근 3개년 배당 내역'),
            ],
          ),
        ),
        _gap(AppSpace.section),
        _section(context, '시장의 짧은 맥락'),
        _market(context),
      ] else if (b) ...[
        _collectionsView(context, large: true),
        _gap(AppSpace.section),
        _section(context, '오늘 발견한 변화'),
        _lead(context, panel: true),
        _gap(AppSpace.section),
        _split(
          _watch(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_section(context, '시장의 맥락'), _market(context)],
          ),
        ),
      ] else ...[
        _market(context),
        _gap(AppSpace.xxl),
        _split(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, '오늘 살펴볼 변화'),
              _lead(context, panel: true, chart: false),
              _row(context, '정정 보고서, 이전 숫자와 비교해보세요.', '가상기업 새봄 · 접수 예시 10.02'),
            ],
          ),
          _watch(context),
        ),
        _gap(AppSpace.section),
        _section(context, '다음에 살펴볼 기업'),
        _collectionsView(context),
      ],
      _gap(AppSpace.section),
      _reports(context),
      _gap(AppSpace.xxl),
      Text(
        '실제 shad 0.99.4 / 서비스 테마 / PageFrame / DataPanel / AppLineChart / AppDataTable / showAdaptiveDetail 사용. 서비스에는 미적용이며 모든 데이터는 합성입니다.',
        style: context.typo.body(11, color: context.colors.textMuted),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(color: context.colors.surfaceHover),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            children: [
              Text(
                '실제 Flutter 컴포넌트로 보는 홈 시안',
                style: context.typo.body(
                  13,
                  color: context.colors.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: AppSpace.xs,
                children: [
                  for (final (index, label) in [
                    'A · 읽는 홈',
                    'B · 발견하는 홈',
                    'C · 함께 보는 홈',
                  ].indexed)
                    IntrinsicWidth(
                      child: ShadToggle.outline(
                        value: _concept == index,
                        onChanged: (_) {
                          setState(() => _concept = index);
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        },
                        child: Text(label),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          child: Text(
            '모든 기업·수치·선정 이유는 합성 예시입니다. 금융 데이터나 실제 분석 결과가 아닙니다.',
            style: context.typo.body(11, color: context.colors.textMuted),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(bottom: BorderSide(color: context.colors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                Text('알파인더', style: context.typo.display(20)),
                if (box.maxWidth > 700) ...[
                  const SizedBox(width: AppSpace.xxl),
                  for (final label in ['홈', '시장', '기업', '기업 찾기'])
                    ShadButton.ghost(
                      onPressed: () => _detail('$label 탐색 위치'),
                      child: Text(label),
                    ),
                ],
                const Spacer(),
                SizedBox(
                  width: box.maxWidth < 600 ? 155 : 245,
                  child: ShadInput(
                    placeholder: const Text('기업 이름 검색'),
                    onChanged: (v) => setState(() => _query = v),
                    leading: const Icon(Icons.search, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: PageFrame(
            controller: _scroll,
            maxWidth: 1160,
            children: [
              if (_query.isNotEmpty) ...[
                _row(context, '가상기업 한빛 · 검색 예시', '입력: $_query · 실제 서버 조회 없음'),
                _gap(),
              ],
              ..._body(context),
            ],
          ),
        ),
      ],
    ),
  );
}
