import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../layout.dart';

/// A bounded research block, not a wrapper API for a basic widget.
/// Nested blocks become plain content so charts/tables never acquire
/// another white box inside the same research section.
class DataPanel extends StatelessWidget {
  const DataPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_PanelScope>() != null) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, box) => ShadCard(
        width: box.maxWidth.isFinite ? double.infinity : null,
        padding: EdgeInsets.all(AppLayout.panelPadding(box.maxWidth)),
        child: _PanelScope(child: child),
      ),
    );
  }
}

class _PanelScope extends InheritedWidget {
  const _PanelScope({required super.child});
  @override
  bool updateShouldNotify(_PanelScope oldWidget) => false;
}
