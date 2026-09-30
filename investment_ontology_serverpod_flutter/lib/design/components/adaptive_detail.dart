import 'package:flutter/material.dart';

import '../tokens.dart';

/// Short detail on desktop; draggable, independently scrolling detail on phones.
Future<void> showAdaptiveDetail({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(child: builder(context)),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.background,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .35,
      maxChildSize: .92,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        child: SafeArea(top: false, child: builder(context)),
      ),
    ),
  );
}
