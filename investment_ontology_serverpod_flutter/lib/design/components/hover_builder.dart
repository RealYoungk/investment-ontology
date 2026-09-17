import 'package:flutter/material.dart';

/// 마우스 오버 상태와 클릭 커서를 제공하는 기본 상호작용 래퍼.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder, this.onTap});

  final Widget Function(BuildContext context, bool hovered) builder;

  /// null이면 비활성: 커서가 바뀌지 않고 오버 효과도 없다.
  final VoidCallback? onTap;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, enabled && _hovered),
      ),
    );
  }
}
