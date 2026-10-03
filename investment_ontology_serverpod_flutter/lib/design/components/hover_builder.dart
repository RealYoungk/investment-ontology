import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

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
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: enabled,
        enabled: enabled,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: context.shape.borderRadius,
            border: _focused
                ? Border.all(color: context.colors.accent, width: 2)
                : null,
          ),
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
            onExit: enabled ? (_) => setState(() => _hovered = false) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: widget.builder(context, enabled && (_hovered || _focused)),
            ),
          ),
        ),
      ),
    );
  }
}
