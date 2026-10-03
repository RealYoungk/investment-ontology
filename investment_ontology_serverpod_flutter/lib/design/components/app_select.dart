import 'package:flutter/material.dart';
import 'package:shad/shad.dart';

import '../tokens.dart';

/// Service filter: an explicit “all” option maps back to a nullable query value.
class AppSelect<T> extends StatefulWidget {
  const AppSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.label,
    this.allLabel = '전체',
    this.allowClear = true,
  });
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final String? label;
  final String allLabel;
  final bool allowClear;
  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  final popoverController = ShadPopoverController();
  late final controller = ShadSelectController<T>(
    initialValue: widget.value == null ? {} : {widget.value as T},
  );
  @override
  void didUpdateWidget(covariant AppSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.value = widget.value == null ? {} : {widget.value as T};
  }

  @override
  void dispose() {
    popoverController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.label != null) ...[
        Text(
          widget.label!,
          style: context.typo.label(color: context.colors.textSecondary),
        ),
        const SizedBox(width: AppSpace.md),
      ],
      ShadSelect<T>(
        controller: controller,
        popoverController: popoverController,
        enabled: widget.options.isNotEmpty,
        placeholder: Text(widget.placeholder),
        minWidth: 160,
        maxWidth: 260,
        maxHeight: 420,
        allowDeselection: widget.allowClear,
        selectedOptionBuilder: (_, value) => Text(
          widget.options[value] ?? widget.placeholder,
          overflow: TextOverflow.ellipsis,
        ),
        onChanged: widget.onChanged,
        header: widget.allowClear
            ? ShadButton.ghost(
                onPressed: () {
                  popoverController.hide();
                  controller.value = {};
                  widget.onChanged(null);
                },
                child: Flexible(child: Text(widget.allLabel)),
              )
            : null,
        options: [
          for (final entry in widget.options.entries)
            ShadOption<T>(value: entry.key, child: Text(entry.value)),
        ],
      ),
    ],
  );
}
