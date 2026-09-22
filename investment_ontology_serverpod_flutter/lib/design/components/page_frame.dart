import 'package:flutter/material.dart';

import '../tokens.dart';

/// 화면 본문 틀: 세로 스크롤, 가운데 정렬된 최대 폭, 화면 폭에 맞춘 좌우 여백.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.children,
    this.maxWidth = 1280,
    this.controller,
  });

  /// 이보다 좁으면 좌우 여백을 줄인다.
  static const compactBreakpoint = 720.0;

  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;

  static double gutter(double width) =>
      width < compactBreakpoint ? AppSpace.lg : AppSpace.section;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = gutter(constraints.maxWidth);
        return SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            pad,
            AppSpace.xxl,
            pad,
            AppSpace.section,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 화면 제목과 한 줄 설명.
class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: t.label(color: c.accent)),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(title, style: t.display(40, color: c.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(subtitle!, style: t.body(14, color: c.textSecondary)),
        ],
      ],
    );
  }
}
