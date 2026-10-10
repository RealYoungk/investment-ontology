import 'package:flutter/material.dart';

import '../../../design/components/components.dart';
import '../../../design/tokens.dart';

/// A natural header followed by a compact reading bar. On mobile the bar
/// hides on downward scrolling and returns on upward scrolling.
class CollapsingCompanyFrame extends StatefulWidget {
  const CollapsingCompanyFrame({
    super.key,
    this.titleAnchor,
    this.metrics,
    this.actionsBuilder,
    this.actionsAnchor,
    this.sourceAnchors = const [],
    this.marketLabel = '',
    this.marketCap = '',
    this.price,
    this.corpCode,
    required this.name,
    required this.code,
    required this.navigation,
    required this.header,
    required this.children,
  });

  final List<GlobalKey> sourceAnchors;
  final String marketLabel, marketCap;
  final int? price;
  final String? corpCode;
  final GlobalKey? titleAnchor;
  final String name, code;
  final Widget navigation, header;
  final List<Widget> children;
  final Widget? metrics;
  final GlobalKey? actionsAnchor;
  final Widget Function(BuildContext, double)? actionsBuilder;

  @override
  State<CollapsingCompanyFrame> createState() => _CollapsingCompanyFrameState();
}

class _CollapsingCompanyFrameState extends State<CollapsingCompanyFrame> {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gutter = PageFrame.gutter(constraints.maxWidth);
      Widget bounded(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
          child: child,
        ),
      );
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpace.xl, gutter, 0),
            sliver: SliverToBoxAdapter(child: bounded(widget.header)),
          ),
          if (widget.metrics != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: SliverToBoxAdapter(child: bounded(widget.metrics!)),
            ),
          SliverPersistentHeader(
            floating: true,
            delegate: _CompanyNavigationDelegate(
              child: Container(
                color: context.colors.background,
                padding: EdgeInsets.symmetric(
                  horizontal: gutter,
                  vertical: AppSpace.md,
                ),
                child: bounded(widget.navigation),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpace.md,
              gutter,
              AppSpace.section,
            ),
            sliver: SliverToBoxAdapter(
              child: bounded(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in widget.children)
                      RepaintBoundary(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _CompanyNavigationDelegate extends SliverPersistentHeaderDelegate {
  _CompanyNavigationDelegate({required this.child});
  final Widget child;
  @override
  double get minExtent => 88;
  @override
  double get maxExtent => 88;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _CompanyNavigationDelegate oldDelegate) =>
      oldDelegate.child != child;
}
