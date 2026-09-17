import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hover_builder.dart';

/// 라벨: 값 한 줄. [onTap]이 있으면 값이 링크로 보인다.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.numeric = false,
    this.onTap,
    this.labelWidth = 108,
  });

  final String label;
  final String? value;
  final bool numeric;
  final VoidCallback? onTap;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    final v = value;
    final Widget valueWidget;
    if (v == null) {
      valueWidget = Text('—', style: t.body(13.5, color: c.textMuted));
    } else if (onTap != null) {
      valueWidget = HoverBuilder(
        onTap: onTap,
        builder: (context, _) => Text(
          v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t
              .body(13.5, color: c.accent)
              .copyWith(
                decoration: TextDecoration.underline,
                decorationColor: c.accent,
              ),
        ),
      );
    } else {
      valueWidget = SelectableText(
        v,
        style: numeric ? t.numeric(13) : t.body(13.5),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: t.body(13, color: c.textSecondary)),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}
