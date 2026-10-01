import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../auth/app_viewer.dart';
import 'ad_config.dart';
import 'ad_platform.dart';

/// One in-flow banner. The page owns scrolling; no sticky or timer refresh.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, this.config = const AdConfig.environment()});
  final AdConfig config;
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _unavailable = false;
  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final viewer = context.viewer;
    if (_unavailable ||
        (viewer != null && !viewer.membershipResolved) ||
        !config.show(adFree: viewer?.isAdFree ?? false, web: kIsWeb)) {
      return const SizedBox.shrink();
    }
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 250) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    config.preview ? '광고 · 미리보기' : '광고',
                    style: context.typo.body(11, color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  SizedBox(
                    height: 100,
                    key: const ValueKey('ad-placement-slot'),
                    child: config.preview
                        ? Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.border),
                            ),
                            child: Text(
                              '광고 영역',
                              style: context.typo.body(
                                13,
                                color: c.textSecondary,
                              ),
                            ),
                          )
                        : AdPlatform(
                            // Account switches dispose the old DOM before another request.
                            key: ValueKey(viewer?.userId ?? 'anonymous'),
                            config: config,
                            onUnavailable: () {
                              if (mounted) setState(() => _unavailable = true);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
