import 'package:flutter/material.dart';
import 'package:shad/shad.dart';
import 'package:url_launcher/link.dart';

import '../../design/tokens.dart';

/// 공개 정책·문의 링크를 관리하는 공용 푸터.
/// 인증 화면은 compact로 필수 링크만 보여준다.
class ServiceFooter extends StatelessWidget {
  const ServiceFooter({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '서비스 안내',
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      children: [
        for (final item in [
          if (!compact) (label: '리서치 안내', path: '/start'),
          (label: '개인정보처리방침', path: '/data-notice.html'),
          (label: '이용권 약관', path: '/membership.html'),
          (label: '문의', path: '/support.html'),
          if (!compact) (label: '광고·쿠키 설정', path: '/cookies.html'),
        ])
          Link(
            uri: Uri.https('alfinder.kr', item.path),
            target: LinkTarget.blank,
            builder: (context, followLink) => ShadButton.ghost(
              onPressed: followLink,
              child: Text(
                item.label,
                style: context.typo.body(
                  12,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
