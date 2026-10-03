import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../tokens.dart';

/// Required service choice: toggling off the active value does not clear it.
class AppToggleGroup<T> extends StatelessWidget {
  const AppToggleGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = const {},
  });
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? label;
  final Set<T> disabled;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[Text(label!), const SizedBox(width: AppSpace.md)],
      Flexible(
        child: Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final entry in options.entries)
              IntrinsicWidth(
                child: ShadToggle(
                  value: entry.key == value,
                  enabled: !disabled.contains(entry.key),
                  onChanged: (_) => onChanged(entry.key),
                  child: Text(entry.value),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
