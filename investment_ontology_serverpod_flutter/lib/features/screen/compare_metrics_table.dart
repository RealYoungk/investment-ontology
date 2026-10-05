import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';

class CompareMetricRow {
  const CompareMetricRow({
    required this.label,
    required this.values,
    required this.notes,
  });
  final String label;
  final List<String?> values;
  final List<String?> notes;
}

/// One horizontal viewport keeps company headings and values together, while
/// metric labels stay outside it. The page owns all vertical scrolling.
class CompareMetricsTable extends StatefulWidget {
  const CompareMetricsTable({
    super.key,
    required this.companies,
    required this.metrics,
  });
  final List<String> companies;
  final List<CompareMetricRow> metrics;

  @override
  State<CompareMetricsTable> createState() => _CompareMetricsTableState();
}

class _CompareMetricsTableState extends State<CompareMetricsTable> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final labelStyle = t.body(13, color: c.textSecondary);
    final valueStyle = t.numeric(13, color: c.textPrimary);
    final headerStyle = t.body(13, weight: FontWeight.w600);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final labelWidth = box.maxWidth < 600 ? 104.0 : 156.0;
        final available = math.max(1.0, box.maxWidth - labelWidth);
        final columnWidth = math.max(
          156.0,
          available / widget.companies.length,
        );
        final overflow = columnWidth * widget.companies.length > available + 1;
        double textHeight(String text, TextStyle style, double width) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: width - 24);
          return painter.height + 24;
        }

        final headerHeight = widget.companies.fold<double>(
          48,
          (height, name) =>
              math.max(height, textHeight(name, headerStyle, columnWidth)),
        );
        final heights = [
          for (final metric in widget.metrics)
            metric.values.fold<double>(
              math.max(48, textHeight(metric.label, labelStyle, labelWidth)),
              (height, value) => math.max(
                height,
                textHeight(value ?? '—', valueStyle, columnWidth),
              ),
            ),
        ];
        Widget cell(
          String text,
          double width,
          double height,
          TextStyle style, {
          bool header = false,
          bool numeric = false,
          String? note,
          String? semanticLabel,
        }) {
          final content = Container(
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: header ? c.surfaceHover : null,
              border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
            ),
            child: Text(
              text,
              style: style,
              textAlign: numeric ? TextAlign.right : TextAlign.left,
            ),
          );
          return Semantics(
            label: semanticLabel,
            tooltip: note,
            child: note == null || note.isEmpty
                ? content
                : ShadTooltip(builder: (_) => Text(note), child: content),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (overflow) ...[
              Text(
                '지표는 왼쪽에 고정됩니다 · 기업 열을 좌우로 넘겨 보세요',
                style: t.body(12, color: c.textSecondary),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  foregroundDecoration: BoxDecoration(
                    border: Border(right: BorderSide(color: c.border)),
                  ),
                  child: Column(
                    children: [
                      cell(
                        '지표',
                        labelWidth,
                        headerHeight,
                        headerStyle,
                        header: true,
                      ),
                      for (final (i, metric) in widget.metrics.indexed)
                        cell(metric.label, labelWidth, heights[i], labelStyle),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: overflow,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      key: const ValueKey('compare-values-scroll'),
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(bottom: overflow ? 12 : 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              for (final name in widget.companies)
                                cell(
                                  name,
                                  columnWidth,
                                  headerHeight,
                                  headerStyle,
                                  header: true,
                                ),
                            ],
                          ),
                          for (final (i, metric) in widget.metrics.indexed)
                            Row(
                              children: [
                                for (
                                  var j = 0;
                                  j < widget.companies.length;
                                  j++
                                )
                                  cell(
                                    metric.values[j] ?? '—',
                                    columnWidth,
                                    heights[i],
                                    metric.values[j] == null
                                        ? valueStyle.copyWith(
                                            color: c.textMuted,
                                          )
                                        : valueStyle,
                                    numeric: true,
                                    note: metric.notes[j],
                                    semanticLabel:
                                        '${widget.companies[j]} · ${metric.label}',
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
