import 'package:flutter/material.dart';

import '../../design/components/components.dart';

/// A recoverable read failure; implementation errors never reach the page.
class MarketLoadNotice extends StatelessWidget {
  const MarketLoadNotice({
    super.key,
    required this.subject,
    required this.retry,
  });
  final String subject;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppNotice(message: '$subject 연결이 지연되고 있어요. 잠시 후 다시 불러와 주세요.'),
      TextButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('다시 불러오기'),
      ),
    ],
  );
}
