import 'package:flutter/material.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../business/overview_catalog.dart';

/// One layout for a service, pipeline, asset portfolio or physical product.
/// The flow describes a business model, not a forecast or a production schedule.
class BusinessModelGuide extends StatefulWidget {
  const BusinessModelGuide({
    super.key,
    required this.lesson,
    this.showGrowth = true,
    this.compact = false,
    this.summary,
    this.framed = true,
  });
  final CompanyOverviewLesson lesson;
  final bool showGrowth;
  final bool compact;
  final String? summary;
  final bool framed;
  @override
  State<BusinessModelGuide> createState() => _BusinessModelGuideState();
}

class _BusinessModelGuideState extends State<BusinessModelGuide> {
  int _selected = 0;
  @override
  void didUpdateWidget(covariant BusinessModelGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson != widget.lesson) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final lesson = widget.lesson;
    final model = lesson.models[_selected];
    Widget card(Widget child) => !widget.framed
        ? child
        : Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: c.border),
              borderRadius: context.shape.borderRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: child,
            ),
          );
    if (widget.compact) {
      final summary = widget.summary ?? lesson.summary;
      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (summary.isNotEmpty) ...[
              Text(
                summary,
                style: t
                    .body(16, weight: FontWeight.w600)
                    .copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            if (lesson.products.isNotEmpty) ...[
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  for (final product in lesson.products)
                    ShadBadge.outline(
                      child: Text(
                        product,
                        style: t.body(12, color: c.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            ShadAccordion<int>(
              maintainState: false,
              children: [
                ShadAccordionItem<int>(
                  value: 0,
                  title: Text(
                    '사업모델 이해하기',
                    style: t.body(13, color: c.textSecondary),
                  ),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BusinessModelGuide(
                        lesson: CompanyOverviewLesson(
                          summary: '',
                          products: const [],
                          models: lesson.models,
                          hasDocument: lesson.hasDocument,
                          year: lesson.year,
                        ),
                        showGrowth: false,
                        framed: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lesson.summary.isNotEmpty) ...[
                Text(
                  lesson.summary,
                  style: t
                      .body(16, weight: FontWeight.w600)
                      .copyWith(height: 1.55),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (lesson.products.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final product in lesson.products)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceHover,
                          borderRadius: context.shape.borderRadius,
                        ),
                        child: Text(
                          product,
                          style: t.body(12, color: c.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              if (lesson.models.length > 1) ...[
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final (index, item) in lesson.models.indexed)
                      IntrinsicWidth(
                        child: ShadToggle.outline(
                          value: index == _selected,
                          onChanged: (_) => setState(() => _selected = index),
                          child: Text(item.label),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Text(
                '${lesson.summary.isEmpty && lesson.products.isEmpty ? '업종 이해' : '사업 구조'} · ${model.label}',
                style: t.body(
                  12,
                  color: c.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                model.title,
                style: t
                    .body(18, weight: FontWeight.w700)
                    .copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpace.md),
              _BusinessFlow(model: model),
              const SizedBox(height: AppSpace.md),
              Text(
                model.description,
                style: t.body(14, color: c.textSecondary).copyWith(height: 1.6),
              ),
              if (model.terms.isNotEmpty)
                ShadAccordion<int>(
                  maintainState: false,
                  children: [
                    ShadAccordionItem<int>(
                      value: 0,
                      title: Text(
                        '용어 이해하기',
                        style: t.body(13, color: c.textSecondary),
                      ),
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              model.terms,
                              style: t.body(13).copyWith(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (widget.showGrowth) ...[
          const SizedBox(height: AppSpace.xl),
          const SectionLabel('무엇이 성장을 이끄나요?', accent: true),
          const SizedBox(height: AppSpace.md),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${model.label}의 성장 동력',
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  model.driver,
                  style: t
                      .body(18, weight: FontWeight.w700)
                      .copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(model.thesis, style: t.body(14).copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BusinessFlow extends StatelessWidget {
  const _BusinessFlow({required this.model});
  final OverviewModel model;
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    Widget stage(int index) {
      final step = model.flow[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  switch (index) {
                    0 => Icons.input_rounded,
                    1 => Icons.hub_outlined,
                    _ => Icons.payments_outlined,
                  },
                  size: 20,
                  color: c.accent,
                ),
                const SizedBox(width: AppSpace.sm),
                Text('0${index + 1}', style: t.body(11, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              step.title,
              style: t.body(14, weight: FontWeight.w700).copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              step.body,
              style: t.body(12, color: c.textSecondary).copyWith(height: 1.5),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final vertical = box.maxWidth < 500;
        final children = <Widget>[];
        for (var i = 0; i < model.flow.length; i++) {
          if (i > 0) {
            children.add(
              Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Icon(
                  vertical
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
                  color: c.textMuted,
                ),
              ),
            );
          }
          children.add(vertical ? stage(i) : Expanded(child: stage(i)));
        }
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );
      },
    );
  }
}
