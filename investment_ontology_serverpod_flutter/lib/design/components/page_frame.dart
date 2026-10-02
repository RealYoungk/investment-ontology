import 'package:flutter/material.dart';

import '../tokens.dart';

/// 화면 본문 틀: 세로 스크롤, 가운데 정렬된 최대 폭, 화면 폭에 맞춘 좌우 여백.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.children,
    this.maxWidth = 1280,
    this.controller,
    this.allowLeading = true,
  });

  /// 이보다 좁으면 좌우 여백을 줄인다.
  static const compactBreakpoint = 720.0;

  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;

  /// Do not mount a supplied lead while publisher content is unavailable.
  final bool allowLeading;

  static double gutter(double width) =>
      width < compactBreakpoint ? AppSpace.lg : AppSpace.xxl;

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
                children: [
                  if (allowLeading) ?PageFrameLeadScope.of(context),
                  ...children,
                ],
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
        Text(title, style: t.display(30, color: c.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(subtitle!, style: t.body(14, color: c.textSecondary)),
        ],
      ],
    );
  }
}

/// Optional page header inside the page's own scroll view.
/// The shell supplies content without coupling design components to features.
class PageFrameLeadScope extends InheritedWidget {
  const PageFrameLeadScope({
    super.key,
    required this.leading,
    required super.child,
  });
  final Widget? leading;
  static Widget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageFrameLeadScope>()?.leading;
  @override
  bool updateShouldNotify(PageFrameLeadScope oldWidget) =>
      leading != oldWidget.leading;
}
