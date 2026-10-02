import 'package:flutter/material.dart';

import '../tokens.dart';
import 'adaptive_detail.dart';

/// 기업 상세 탭의 공통 정보 계층: 항목명 다음에 짧은 읽기 안내.
class CompanySectionHeading extends StatelessWidget {
  const CompanySectionHeading(
    this.title, {
    super.key,
    this.description,
    this.help,
  });
  final String title;
  final String? description;
  final String? help;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.typo.body(13, weight: FontWeight.w600),
            ),
          ),
          if (help != null)
            IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 18,
                color: context.colors.textMuted,
              ),
              tooltip: '$title 읽는 법',
              onPressed: () => showAdaptiveDetail(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$title 읽는 법',
                              style: context.typo.body(
                                16,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: '닫기',
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        help!,
                        style: context.typo.body(13).copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      if (description != null) ...[
        const SizedBox(height: AppSpace.xs),
        Text(
          description!,
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
      ],
    ],
  );
}

/// 탭의 목적은 한 번만 안내하고, 아래의 섹션 제목보다 한 단계 높게 표시한다.
class CompanyTabIntro extends StatelessWidget {
  const CompanyTabIntro(this.title, this.description, {super.key});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.typo.body(22, weight: FontWeight.w700)),
        const SizedBox(height: AppSpace.xs),
        Text(
          description,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
      ],
    ),
  );
}

class CompanyDataCard extends StatelessWidget {
  const CompanyDataCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border.all(color: context.colors.border),
      borderRadius: context.shape.borderRadius,
    ),
    child: child,
  );
}
