import 'package:shad/shad.dart';
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
        (label: '리서치 안내', path: '/start'),
        (label: '문의', path: '/support.html'),
        (label: '개인정보처리방침', path: '/data-notice.html'),
        (label: '이용권 약관', path: '/membership.html'),
        (label: '광고·쿠키 설정', path: '/cookies.html'),
      ])
        Link(
          uri: Uri.https('alfinder.kr', item.path),
          target: LinkTarget.blank,
          builder: (context, followLink) => ShadButton.ghost(
            onPressed: followLink,
            child: Flexible(child: Text(item.label)),
          ),
        ),
    ],
  );
}
