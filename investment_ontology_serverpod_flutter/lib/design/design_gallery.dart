import 'package:flutter/material.dart';

import 'components/components.dart';
import 'tokens.dart';

/// Debug-only, same components and tokens as production pages.
class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return PageFrame(
      children: [
        const PageHeading(
          title: '알파인더 디자인 시스템',
          subtitle: 'shad 0.99.4 · 서비스 차트와 재무표 · 모든 수치는 합성 예시입니다',
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final entry in [
              ('바탕', c.background),
              ('표면', c.surface),
              ('탐색', c.inverse),
              ('강조', c.accent),
              ('상승', c.marketUp),
              ('하락', c.marketDown),
            ])
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.$2,
                      border: Border.all(color: c.border),
                      borderRadius: context.shape.borderRadius,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(entry.$1),
                ],
              ),
          ],
        ),
        const SizedBox(height: 32),
        Text('기업을 이해하는 리서치', style: t.pageTitle),
        Text('섹션 제목', style: t.sectionTitle),
        Text('본문은 숫자의 의미와 다음 행동을 설명합니다.', style: t.bodyText),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ShadButton.raw(
              onPressed: () {},
              variant: ShadButtonVariant.primary,
              child: Flexible(child: Text('기업 살펴보기')),
            ),
            ShadButton.raw(
              onPressed: () {},
              variant: ShadButtonVariant.outline,
              child: Flexible(child: Text('비교에 담기')),
            ),
            const ShadButton.raw(
              onPressed: null,
              enabled: false,
              variant: ShadButtonVariant.outline,
              child: Flexible(child: Text('선택 필요')),
            ),
            ShadButton.raw(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (overlayContext) => InheritedTheme.captureAll(
                  context,
                  Builder(
                    builder: (ctx) => ShadDialog(
                      closeIcon: Builder(
                        builder: (context) => Semantics(
                          container: true,
                          label: '닫기',
                          button: true,
                          onTap: () => Navigator.of(context).pop(),
                          child: ExcludeSemantics(
                            child: ShadIconButton.ghost(
                              width: 20,
                              height: 20,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                      title: const Text('계산 근거'),
                      actions: [
                        ShadButton.ghost(
                          onPressed: () => Navigator.pop(ctx),
                          child: Flexible(child: const Text('닫기')),
                        ),
                      ],
                      child: Material(
                        type: MaterialType.transparency,
                        child: const Text('실제 화면에서는 산식과 입력값, 공시 출처를 표시합니다.'),
                      ),
                    ),
                  ),
                ),
                barrierLabel: '닫기',
              ),
              variant: ShadButtonVariant.link,
              child: Flexible(child: Text('근거 보기')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const ShadInput(
          placeholder: Text('기업 이름 또는 종목코드'),
          leading: Icon(Icons.search),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            Text('+1.65%', style: t.metricValue.copyWith(color: c.marketUp)),
            Text('−1.65%', style: t.metricValue.copyWith(color: c.marketDown)),
            Text('—', style: t.metricValue.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(height: 24),
        DataPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CompanySectionHeading(
                '실적의 흐름',
                description: '원 단위 합성 예시 · 연결 기준 · 결측 기간은 연결하지 않습니다',
              ),
              const SizedBox(height: AppSpace.lg),
              ChartLegend(
                series: [
                  ChartSeries(
                    label: '합성 매출',
                    color: c.chartSeries1,
                    values: const [100, null, -20, 140],
                  ),
                ],
              ),
              AppColumnChart(
                categories: const ['2023', '2024', '2025', '2026'],
                series: [
                  ChartSeries(
                    label: '합성 매출',
                    color: c.chartSeries1,
                    values: const [100, null, -20, 140],
                  ),
                ],
                categoryNotes: const [null, '2024년 예시 자료 미제공', null, null],
                showMissingMarkers: true,
                formatValue: (value) => '${value.toStringAsFixed(0)}원',
              ),
              Text(
                'Tab으로 차트를 선택하고 방향키·Home·End로 기간을 확인하세요.',
                style: t.supportingText,
              ),
              const SizedBox(height: AppSpace.lg),
              DataPanel(
                child: AppDataTable(
                  columns: const [
                    AppColumn('기간', flex: true),
                    AppColumn('합성 값', numeric: true),
                    AppColumn('기준·근거'),
                  ],
                  rows: [
                    AppRow([
                      Text('2024'),
                      AppDataTable.text(context, null, numeric: true),
                      Text('예시 자료 미제공. 없는 값은 0으로 처리하지 않습니다.'),
                    ]),
                    AppRow([
                      Text('2025'),
                      AppDataTable.text(context, '-20원', numeric: true),
                      Text('가변 행 높이로 긴 근거를 보존합니다.'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const ShadAlert(description: Text('계산에 필요한 현금흐름 데이터가 아직 없습니다.')),
        const SizedBox(height: 24),
        ShadAccordion<int>(
          maintainState: false,
          children: [
            ShadAccordionItem<int>(
              value: 0,
              title: Text('기준·출처'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('공시 출처와 산식은 펼쳐서 확인합니다.')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
