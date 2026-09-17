import 'package:flutter/material.dart';

import '../tokens.dart';

/// 페이지 안에 표시하는 알림 (오류 등).
class AppNotice extends StatelessWidget {
  const AppNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        border: Border(left: BorderSide(color: c.accent, width: 4)),
      ),
      child: Text(message, style: context.typo.body(13, color: c.textPrimary)),
    );
  }
}
