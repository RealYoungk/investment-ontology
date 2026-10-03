import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// URL-driven service tabs: selection remains owned by the screen/router.
class AppTabBar<T> extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });
  final Map<T, String> tabs;
  final T value;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => ShadTabs<T>(
    value: value,
    onChanged: onChanged,
    scrollable: true,
    tabs: [
      for (final entry in tabs.entries)
        ShadTab<T>(value: entry.key, child: Text(entry.value)),
    ],
  );
}
