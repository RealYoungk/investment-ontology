import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// Keep the list mounted; delegate overlay, focus and motion to shad.
Future<void> showAdaptiveDetail({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  await showShadSheet<void>(
    useRootNavigator: true,
    context: context,
    barrierLabel: '상세 닫기',
    side: MediaQuery.sizeOf(context).width >= 600
        ? ShadSheetSide.right
        : ShadSheetSide.bottom,
    builder: (overlayContext) => InheritedTheme.captureAll(
      context,
      Builder(
        builder: (context) => ShadSheet(
          // Service detail headers already own an accessible close action.
          closeIcon: const SizedBox.shrink(),
          scrollable: true,
          child: Material(
            type: MaterialType.transparency,
            child: builder(context),
          ),
        ),
      ),
    ),
  );
}
