import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// Public HTML pages remain accessible without loading Flutter or signing in.
class ServiceLinks extends StatelessWidget {
  const ServiceLinks({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final item in const [
        (label: '문의', path: '/support.html'),
        (label: '개인정보 처리 안내', path: '/data-notice.html'),
        (label: '광고 제거 안내', path: '/membership.html'),
      ])
        Link(
          uri: Uri.https('alfinder.kr', item.path),
          target: LinkTarget.blank,
          builder: (context, followLink) => TextButton(
            onPressed: followLink,
            child: Text(item.label),
          ),
        ),
    ],
  );
}
