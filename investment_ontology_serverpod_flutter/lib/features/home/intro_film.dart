import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import 'intro_motion_surface.dart';

/// A single scroll owner; the film pins inside a long section without trapping input.
class IntroFilm extends StatefulWidget {
  const IntroFilm({super.key, required this.controller});
  final ScrollController controller;
  @override
  State<IntroFilm> createState() => _IntroFilmState();
}

class _IntroFilmState extends State<IntroFilm> {
  final _anchor = GlobalKey();
  double? _start;
  double _offset = 0;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  void _scroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _start ??= box.localToGlobal(Offset.zero).dy + widget.controller.offset;
    setState(() => _offset = widget.controller.offset - _start! + 80);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final height = (MediaQuery.sizeOf(context).height - 110).clamp(
      480.0,
      760.0,
    );
    final travel = reduced ? 0.0 : height * 1.8;
    final pinned = _offset.clamp(0.0, travel);
    final progress = travel == 0
        ? 1.0
        : introMotionProgress((pinned / travel).clamp(0.0, 1.0));
    final chapter = progress < .3
        ? 0
        : progress < .65
        ? 1
        : 2;
    final titles = ['흩어진 정보.', '하나의 기업.', '연결된 이해.'];
    final subtitles = [
      '보고서 속 숫자와 사업의 단서들',
      '숫자를 모으고, 사업의 구조를 읽습니다',
      '관계를 따라, 조사할 기업을 넓혀갑니다',
    ];
    final c = context.colors;
    return SizedBox(
      key: _anchor,
      height: height + travel,
      child: Stack(
        children: [
          Positioned(
            top: pinned,
            left: 0,
            right: 0,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: c.accentSubtle),
                  Positioned(
                    top: height * .30,
                    bottom: 106,
                    left: compact ? 12 : 48,
                    right: compact ? 12 : 48,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: progress, end: progress),
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => IntroMotionSurface(
                        progress: value,
                        reduced: reduced,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.surface.withValues(alpha: .8),
                            c.surface.withValues(alpha: 0),
                            c.surface.withValues(alpha: .3),
                          ],
                          stops: const [0, .48, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 30 : 44,
                    left: compact ? 24 : 48,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALFINDER / ${chapter + 1} OF 3',
                          style: context.typo.numeric(
                            11,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 450),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, .15),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            titles[chapter],
                            key: ValueKey(chapter),
                            style: context.typo
                                .display(compact ? 34 : 54)
                                .copyWith(letterSpacing: -1.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitles[chapter],
                          style: context.typo.body(
                            compact ? 13 : 16,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: compact ? 24 : 48,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              Container(
                                width: i == chapter ? 40 : 12,
                                height: 3,
                                color: i == chapter ? c.accent : c.borderStrong,
                              ),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reduced ? '정보의 연결 구조' : '스크롤하며 연결을 따라가세요 ↓',
                          style: context.typo.body(11, color: c.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '연결 구조를 표현한 연출 · 실제 기업 관계가 아닙니다',
                          style: context.typo.body(10, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hold each completed composition before the next transition. The page keeps
/// its original scroll length; no wheel/touch interception or snapping.
double introMotionProgress(double scrollProgress) {
  final p = scrollProgress.clamp(0.0, 1.0);
  if (p <= .14) return 0;
  if (p < .40) return .62 * Curves.easeInOutCubic.transform((p - .14) / .26);
  if (p <= .60) return .62;
  if (p < .84) {
    return .62 + .38 * Curves.easeInOutCubic.transform((p - .60) / .24);
  }
  return 1;
}
