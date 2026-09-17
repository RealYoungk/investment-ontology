import 'package:flutter/material.dart';

import '../tokens.dart';

/// 상태 점 + 라벨. [pulsing]이면 진행 중을 나타내며 깜빡인다.
class StatusDot extends StatefulWidget {
  const StatusDot({
    super.key,
    required this.color,
    required this.label,
    this.pulsing = false,
  });

  final Color color;
  final String label;
  final bool pulsing;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) _sync();
  }

  void _sync() {
    if (widget.pulsing) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.25, end: 1.0).animate(_pulse),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Text(
          widget.label,
          style: context.typo.label(color: context.colors.textPrimary),
        ),
      ],
    );
  }
}
