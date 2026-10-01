import 'package:flutter/widgets.dart';

import 'ad_config.dart';

class AdPlatform extends StatelessWidget {
  const AdPlatform({
    super.key,
    required this.config,
    required this.onUnavailable,
  });
  final AdConfig config;
  final VoidCallback onUnavailable;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
