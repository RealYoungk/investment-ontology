import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// URL-driven service tabs: selection remains owned by the screen/router.
class AppTabBar<T> extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.fitContent = false,
  });
  final Map<T, String> tabs;
  final T value;
  final bool fitContent;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabsBar = ShadTabs<T>(
      value: value,
      onChanged: onChanged,
      scrollable: !fitContent,
      expandTabs: fitContent ? false : null,
      gap: fitContent ? 0 : null,
      tabs: [
        for (final entry in tabs.entries)
          ShadTab<T>(
            value: entry.key,
            height: fitContent ? 48 : null,
            textStyle: fitContent
                ? ShadTheme.of(context).textTheme.small.copyWith(fontSize: 16)
                : null,
            child: Text(entry.value),
          ),
      ],
    );
    return fitContent
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tabsBar,
          )
        : tabsBar;
  }
}
