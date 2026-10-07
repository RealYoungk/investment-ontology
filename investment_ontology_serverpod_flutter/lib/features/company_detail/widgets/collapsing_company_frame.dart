import 'package:flutter/material.dart';

import '../../../design/components/components.dart';
import '../../../design/components/company_logo.dart';
import '../../../design/tokens.dart';

/// The expanded header owns its natural height. Only compact identity and tabs
/// are pinned. Anchored values have one moving paint layer; their source text
/// remains hidden in the header while retaining its layout.
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

class _Flight {
  const _Flight(this.offset, this.size, this.style);
  final Offset offset;
  final Size size;
  final TextStyle style;
}

class _CollapsingCompanyFrameState extends State<CollapsingCompanyFrame> {
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  double _height = 1;
  Offset? _actionsOffset;
  double _actionsWidth = 0;
  List<_Flight?> _sources = [];

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final header =
          _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (header == null || !header.hasSize) return;
      final actionBox =
          widget.actionsAnchor?.currentContext?.findRenderObject()
              as RenderBox?;
      final actionOffset = actionBox != null && actionBox.hasSize
          ? actionBox.localToGlobal(Offset.zero) -
                header.localToGlobal(Offset.zero)
          : null;
      final sources = [widget.titleAnchor, ...widget.sourceAnchors].map((key) {
        final box = key?.currentContext?.findRenderObject() as RenderBox?;
        final text = key?.currentWidget;
        if (box == null || !box.hasSize || text is! Text) {
          return null;
        }
        return _Flight(
          box.localToGlobal(Offset.zero) - header.localToGlobal(Offset.zero),
          box.size,
          DefaultTextStyle.of(key!.currentContext!).style.merge(text.style),
        );
      }).toList();
      final changed =
          _actionsOffset != actionOffset ||
          _height != header.size.height ||
          _sources.length != sources.length ||
          sources.indexed.any(
            (entry) =>
                _sources[entry.$1]?.offset != entry.$2?.offset ||
                _sources[entry.$1]?.size != entry.$2?.size,
          );
      if (changed) {
        setState(() {
          _height = header.size.height;
          _actionsOffset = actionOffset;
          _actionsWidth = actionBox?.size.width ?? 0;
          _sources = sources;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<Widget> _flights(BuildContext context, double width, double gutter) {
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final progress = (offset / _height.clamp(1, double.infinity)).clamp(
      0.0,
      1.0,
    );
    final inset =
        (width - 2 * gutter - AppLayout.contentWidth).clamp(
          0.0,
          double.infinity,
        ) /
        2;
    final left = gutter + inset;
    final available = width - left * 2;
    final values = [
      widget.name,
      widget.code,
      widget.price == null
          ? ''
          : '${widget.price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원',
      widget.marketCap,
    ];
    final titleLeft = left + 36 + AppSpace.md;
    double targetX = left;
    final result = <Widget>[];
    if (widget.corpCode != null &&
        _sources.isNotEmpty &&
        _sources.first != null) {
      final source = _sources.first!;
      final size = 48 * (1 - progress) + 36 * progress;
      result.add(
        Positioned(
          left:
              (left + source.offset.dx - 48 - AppSpace.md) * (1 - progress) +
              left * progress,
          top:
              (AppSpace.xxl + source.offset.dy) * (1 - progress) +
              AppSpace.xl * progress,
          child: IgnorePointer(
            child: CompanyLogo(
              key: const ValueKey('company-flight-logo'),
              name: widget.name,
              stockCode: widget.code,
              corpCode: widget.corpCode,
              size: size,
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < values.length && i < _sources.length; i++) {
      final source = _sources[i];
      if (source == null || values[i].isEmpty) continue;
      final targetStyle = source.style.copyWith(fontSize: i == 0 ? 16 : 12);
      final painter = TextPainter(
        text: TextSpan(text: values[i], style: targetStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final chip = i == 1 || i == 2;
      final targetWidth = i == 0
          ? available
          : painter.width + 2 + (chip ? 12 : 0);
      final targetTop = i == 0
          ? AppSpace.xl +
                (widget.corpCode != null ? (36 - painter.height) / 2 : 0)
          : 64.0;
      painter.dispose();
      final flightStyle = source.style.copyWith(
        fontSize:
            (source.style.fontSize ?? 16) * (1 - progress) +
            (i == 0 ? 16 : 12) * progress,
      );
      final flightPainter = TextPainter(
        text: TextSpan(text: values[i], style: flightStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final flightWidth = flightPainter.width + 2;
      flightPainter.dispose();
      final sourceWidth = i == 3 && width < 600
          ? source.size.width.clamp(
              1.0,
              available / 2 - AppSpace.xl * 2,
            )
          : source.size.width;
      result.add(
        Positioned(
          left:
              (left + source.offset.dx - (chip ? 6 : 0)) * (1 - progress) +
              (i == 0 && widget.corpCode != null
                      ? titleLeft
                      : i == 0
                      ? left
                      : targetX) *
                  progress,
          top:
              (AppSpace.xxl + source.offset.dy - (chip ? 2 : 0)) *
                  (1 - progress) +
              targetTop * progress,
          width: i == 0
              ? (available -
                        source.offset.dx * (1 - progress) -
                        (widget.corpCode != null ? 36 + AppSpace.md : 0) *
                            progress -
                        (widget.actionsBuilder != null ? 112 : 0) * progress)
                    .clamp(48.0, double.infinity)
              : sourceWidth * (1 - progress) +
                    flightWidth * progress +
                    (chip ? 12 : 0),
          child: IgnorePointer(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: chip
                  ? ShadBadge.secondary(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        values[i],
                        key: ValueKey('company-flight-$i'),
                        style: flightStyle,
                      ),
                    )
                  : Text(
                      values[i],
                      key: ValueKey('company-flight-$i'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: flightStyle,
                    ),
            ),
          ),
        ),
      );
      if (i > 0) targetX += targetWidth + AppSpace.md;
    }
    return result;
  }

  Widget _movingActions(BuildContext context, double width, double gutter) {
    final progress =
        ((_scroll.hasClients ? _scroll.offset : 0) /
                _height.clamp(1, double.infinity))
            .clamp(0.0, 1.0);
    final inset =
        (width - 2 * gutter - AppLayout.contentWidth).clamp(
          0.0,
          double.infinity,
        ) /
        2;
    final left = gutter + inset;
    return Positioned(
      top:
          (AppSpace.xxl + _actionsOffset!.dy) * (1 - progress) +
          AppSpace.xl * progress,
      left: (left + _actionsOffset!.dx) * (1 - progress),
      right:
          (width - left - _actionsOffset!.dx - _actionsWidth) * (1 - progress) +
          left * progress,
      child: Align(
        alignment: Alignment.centerRight,
        child: widget.actionsBuilder!(context, progress),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _measure();
    return LayoutBuilder(
      builder: (context, constraints) {
        _measure();
        final gutter = PageFrame.gutter(constraints.maxWidth);
        Widget bounded(Widget child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: child,
          ),
        );
        return AnimatedBuilder(
          animation: _scroll,
          builder: (context, _) => Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpace.xxl,
                      gutter,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: bounded(
                        KeyedSubtree(
                          key: _headerKey,
                          child: Opacity(
                            opacity:
                                (1 -
                                        ((_scroll.hasClients
                                                    ? _scroll.offset
                                                    : 0) /
                                                _height.clamp(
                                                  1,
                                                  double.infinity,
                                                )) *
                                            1.5)
                                    .clamp(0.0, 1.0),
                            child: widget.header,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.metrics != null)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      sliver: SliverToBoxAdapter(
                        child: bounded(widget.metrics!),
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CompanyNavigation(
                      background: context.colors.background,
                      identity: bounded(
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.typo.body(
                                  16,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (widget.code.isNotEmpty) ...[
                              const SizedBox(width: AppSpace.sm),
                              Text(
                                widget.code,
                                style: context.typo.numeric(
                                  12,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      navigation: bounded(widget.navigation),
                      gutter: gutter,
                      hasFlights: widget.titleAnchor != null,
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
              ),
              if (_scroll.hasClients && _scroll.offset > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 96,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity:
                          (_scroll.offset / _height.clamp(1, double.infinity))
                              .clamp(0.0, 1.0),
                      child: ColoredBox(color: context.colors.background),
                    ),
                  ),
                ),
              ..._flights(context, constraints.maxWidth, gutter),
              if (widget.actionsBuilder != null && _actionsOffset != null)
                _movingActions(context, constraints.maxWidth, gutter),
            ],
          ),
        );
      },
    );
  }
}

class _CompanyNavigation extends SliverPersistentHeaderDelegate {
  _CompanyNavigation({
    required this.background,
    required this.identity,
    required this.navigation,
    required this.gutter,
    this.hasFlights = false,
  });

  final Color background;
  final Widget identity, navigation;
  final double gutter;
  final bool hasFlights;

  // Explicit separate rows keep tabs below the identity at every scroll offset.
  @override
  double get minExtent => 160;
  @override
  double get maxExtent => 160;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: background,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: Offstage(
              offstage: hasFlights || shrinkOffset <= 0,
              child: identity,
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: navigation),
          ),
        ],
      ),
    ),
  );

  @override
  bool shouldRebuild(covariant _CompanyNavigation oldDelegate) => true;
}
