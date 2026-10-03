// Adapted from shadcn/ui Navigation Menu (MIT); provenance and differences:
// docs/design-system/navigation-menu/README.md. Uses Flutter shad primitives.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shad/shad.dart';

class NavigationEntry {
  const NavigationEntry({
    required this.label,
    this.onPressed,
    this.selected = false,
    this.content,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final WidgetBuilder? content;
}

/// Site navigation: direct links and optional disclosure panels, not page tabs.
class AppNavigationMenu extends StatefulWidget {
  const AppNavigationMenu({super.key, required this.entries});
  final List<NavigationEntry> entries;
  @override
  State<AppNavigationMenu> createState() => _AppNavigationMenuState();
}

class _AppNavigationMenuState extends State<AppNavigationMenu> {
  final nodes = <FocusNode>[];
  final panels = <ShadPopoverController>[];
  Timer? timer;
  @override
  void initState() {
    super.initState();
    sync();
  }

  void sync() {
    while (nodes.length < widget.entries.length) {
      nodes.add(FocusNode());
      panels.add(ShadPopoverController());
    }
  }

  @override
  void didUpdateWidget(covariant AppNavigationMenu old) {
    super.didUpdateWidget(old);
    sync();
  }

  void close() {
    for (final panel in panels) {
      panel.hide();
    }
  }

  void open(int index) {
    timer?.cancel();
    close();
    panels[index].show();
  }

  KeyEventResult key(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.escape) {
      close();
      nodes[index].requestFocus();
      return KeyEventResult.handled;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.home ||
        k == LogicalKeyboardKey.end) {
      final next = k == LogicalKeyboardKey.home
          ? 0
          : k == LogicalKeyboardKey.end
          ? widget.entries.length - 1
          : (index + ((k == LogicalKeyboardKey.arrowRight) != rtl ? 1 : -1)) %
                widget.entries.length;
      close();
      nodes[next].requestFocus();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown &&
        widget.entries[index].content != null) {
      open(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final n in nodes) {
      n.dispose();
    }
    for (final p in panels) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.entries.length; i++) item(i),
      ],
    ),
  );
  Widget item(int i) {
    final entry = widget.entries[i];
    final theme = ShadTheme.of(context);
    Widget button = Focus(
      onKeyEvent: (_, event) => key(i, event),
      child: Semantics(
        selected: entry.selected,
        child: ShadButton.ghost(
          focusNode: nodes[i],
          height: 36,
          hoverBackgroundColor: theme.colorScheme.accent,
          hoverForegroundColor: theme.colorScheme.accentForeground,
          backgroundColor: entry.selected ? theme.colorScheme.accent : null,
          onPressed: entry.content != null
              ? () {
                  panels[i].isOpen ? panels[i].hide() : open(i);
                }
              : entry.onPressed,
          enabled: entry.content != null || entry.onPressed != null,
          trailing: entry.content != null
              ? const Icon(LucideIcons.chevronDown, size: 16)
              : null,
          child: Text(entry.label),
        ),
      ),
    );
    if (entry.content == null) return button;
    button = ShadPopover(
      controller: panels[i],
      popover: entry.content!,
      child: button,
    );
    return MouseRegion(
      onEnter: (_) {
        timer?.cancel();
        timer = Timer(const Duration(milliseconds: 200), () {
          if (mounted) open(i);
        });
      },
      child: button,
    );
  }
}
