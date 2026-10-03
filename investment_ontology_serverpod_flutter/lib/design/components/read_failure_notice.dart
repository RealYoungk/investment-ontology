import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';

/// Shared read failure with a guarded, visible manual retry.
class ReadFailureNotice extends StatefulWidget {
  const ReadFailureNotice({
    super.key,
    required this.subject,
    required this.retry,
  });
  final String subject;
  final Future<void> Function() retry;
  @override
  State<ReadFailureNotice> createState() => _ReadFailureNoticeState();
}

class _ReadFailureNoticeState extends State<ReadFailureNotice> {
  bool _busy = false;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.retry();
    } catch (_) {
      // The parent owns its failure state; keep this recovery action available.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShadAlert(
        description: Text(
          '${widget.subject}를 불러오지 못했어요. 연결 상태를 확인한 뒤 다시 시도해 주세요.',
        ),
      ),
      const SizedBox(height: AppSpace.sm),
      ShadButton.ghost(
        enabled: !(_busy),
        onPressed: _busy ? null : _retry,
        leading: const Icon(LucideIcons.refreshCw),
        child: Flexible(child: Text(_busy ? '다시 불러오는 중…' : '다시 불러오기')),
      ),
    ],
  );
}
