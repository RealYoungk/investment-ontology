import 'package:flutter/material.dart';

import '../tokens.dart';

/// 기업 상세에서 보조 정보를 여는 카드. 접힌 상태에서도 내용을 예고한다.
class CompanyDetailDisclosure extends StatelessWidget {
  const CompanyDetailDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.children,
    this.collapsible = true,
  });
  final String title;
  final String summary;
  final List<Widget> children;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: context.shape.borderRadius,
      side: BorderSide(color: context.colors.border),
    );
    return Material(
      color: context.colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: !collapsible
          ? Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: context.typo.body(16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    summary,
                    style: context.typo.body(
                      12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ...children,
                ],
              ),
            )
          : ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                0,
                AppSpace.md,
                AppSpace.md,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: context.colors.textSecondary,
              collapsedIconColor: context.colors.textSecondary,
              title: Text(
                title,
                style: context.typo.body(16, weight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: Text(
                  summary,
                  style: context.typo.body(
                    12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              children: children,
            ),
    );
  }
}
