import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/components/app_navigation_tile.dart';
import '../../design/tokens.dart';

/// Every entry opens the same business-discovery screen, not a company list.
class IndustryDirectory extends StatefulWidget {
  const IndustryDirectory({super.key, required this.data});
  final IndustryDiscovery data;
  @override
  State<IndustryDirectory> createState() => _IndustryDirectoryState();
}

class _IndustryDirectoryState extends State<IndustryDirectory> {
  static const familyIcons = {
    'IT·전자': Icons.memory_outlined,
    '건강·의료': Icons.health_and_safety_outlined,
    '자동차·산업재': Icons.precision_manufacturing_outlined,
    '에너지·소재': Icons.bolt_outlined,
    '먹거리·생활': Icons.eco_outlined,
    '소비·콘텐츠': Icons.play_circle_outline,
    '금융·서비스': Icons.account_balance_outlined,
    '미분류': Icons.category_outlined,
  };

  static const families = {
    'IT·전자': ['semiconductor', 'software', 'electronics', 'telecom'],
    '건강·의료': ['pharma', 'medical'],
    '자동차·산업재': [
      'auto',
      'shipbuilding',
      'aerospace',
      'rail',
      'machinery',
      'electrical',
      'instruments',
      'construction',
    ],
    '에너지·소재': [
      'battery',
      'chemicals',
      'metals',
      'building-materials',
      'energy',
      'utilities',
      'environment',
    ],
    '먹거리·생활': ['food', 'agriculture', 'fashion', 'cosmetics', 'household'],
    '소비·콘텐츠': [
      'retail',
      'transport',
      'travel',
      'content',
      'gaming',
      'leisure',
      'education',
    ],
    '금융·서비스': [
      'finance',
      'holdings',
      'real-estate',
      'research',
      'business-services',
      'other-services',
    ],
    '미분류': ['unclassified'],
  };
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<IndustryActivity>>{};
    for (final a in widget.data.activities) {
      (groups[a.industryKey ?? 'semiconductor'] ??= []).add(a);
    }
    final visible = groups.keys.toSet();
    final businessCounts = {
      for (final entry in groups.entries)
        entry.key: entry.value
            .where(
              (a) =>
                  a.classificationBasis != 'ksic' &&
                  a.classificationBasis != 'unclassified',
            )
            .map((a) => a.corpCode)
            .toSet()
            .length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final family in families.entries)
          if (family.value.any(visible.contains)) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    familyIcons[family.key],
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    family.key,
                    style: context.typo.body(
                      13,
                      color: context.colors.textSecondary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth < 600
                    ? 1
                    : box.maxWidth < 1000
                    ? 2
                    : 3;
                return Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final key in family.value.where(visible.contains))
                      SizedBox(
                        width:
                            (box.maxWidth - AppSpace.sm * (columns - 1)) /
                            columns,
                        child: AppNavigationTile(
                          title: groups[key]!.first.industryName ?? '반도체',
                          detail: businessCounts[key] == 0
                              ? '분류 준비 중'
                              : '${businessCounts[key]}곳',
                          onTap: () => context.go(
                            Uri(
                              path: '/industries',
                              queryParameters: {'industry': key},
                            ).toString(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        const SizedBox(height: AppSpace.lg),
        Text(
          '공시·공식 등록 정보로 분류한 기업 수예요. 여러 사업을 하는 기업은 둘 이상의 분야에 나올 수 있어요.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
      ],
    );
  }
}
