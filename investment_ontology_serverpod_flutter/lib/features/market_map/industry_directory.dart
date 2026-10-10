import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';

/// Every entry opens the same business-discovery screen, not a company list.
class IndustryDirectory extends StatefulWidget {
  const IndustryDirectory({super.key, this.data});
  final IndustryDiscovery? data;
  @override
  State<IndustryDirectory> createState() => _IndustryDirectoryState();
}

class _IndustryDirectoryState extends State<IndustryDirectory> {
  static const familyIcons = {
    'IT·전자': LucideIcons.cpu,
    '건강·의료': LucideIcons.heartPulse,
    '자동차·산업재': LucideIcons.factory,
    '에너지·소재': LucideIcons.zap,
    '먹거리·생활': LucideIcons.leaf,
    '소비·콘텐츠': LucideIcons.play,
    '금융·서비스': LucideIcons.landmark,
    '미분류': LucideIcons.shapes,
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
  // Navigation labels are bundled; counts require classified data.
  static const labels = {
    'semiconductor': '반도체',
    'software': '소프트웨어·IT 서비스',
    'electronics': '전자부품·IT 기기',
    'gaming': '게임',
    'battery': '배터리',
    'cosmetics': '화장품',
    'instruments': '측정·광학 기기',
    'telecom': '통신',
    'pharma': '제약·바이오 의약품',
    'medical': '의료기기·의료 서비스',
    'auto': '자동차·부품',
    'shipbuilding': '조선',
    'aerospace': '항공·우주',
    'rail': '철도·기타 운송장비',
    'machinery': '기계·생산 장비',
    'electrical': '전기장비',
    'chemicals': '화학·소재',
    'metals': '철강·금속',
    'building-materials': '유리·시멘트·건축 소재',
    'energy': '에너지·자원',
    'utilities': '전기·가스·수도',
    'environment': '환경·재활용',
    'food': '식품·음료',
    'agriculture': '농림·수산',
    'fashion': '의류·섬유·신발',
    'household': '생활용품·가구',
    'retail': '유통·무역',
    'transport': '운송·물류',
    'travel': '여행·숙박·외식',
    'content': '미디어·콘텐츠',
    'leisure': '스포츠·여가',
    'finance': '금융·보험',
    'holdings': '지주회사',
    'real-estate': '부동산',
    'construction': '건설·인프라',
    'research': '연구·엔지니어링',
    'business-services': '기업 서비스',
    'education': '교육',
    'other-services': '공공·생활 서비스',
    'unclassified': '업종 확인이 필요한 기업',
  };
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<IndustryActivity>>{};
    for (final a in (widget.data?.activities ?? <IndustryActivity>[])) {
      (groups[a.industryKey ?? 'semiconductor'] ??= []).add(a);
    }
    final visible = widget.data == null
        ? labels.keys.toSet()
        : groups.keys.toSet();
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
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1000
            ? 3
            : box.maxWidth >= 650
            ? 2
            : 1;
        final width = (box.maxWidth - AppSpace.md * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final family in families.entries)
                  if (family.value.any(visible.contains))
                    SizedBox(
                      width: width,
                      child: DataPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    familyIcons[family.key],
                                    size: 18,
                                    color: context.colors.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: Text(
                                    family.key,
                                    style: context.typo.body(
                                      15,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.md),
                            for (final key in family.value.where(
                              visible.contains,
                            ))
                              ShadButton.raw(
                                variant: ShadButtonVariant.ghost,
                                height: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.sm,
                                ),
                                mainAxisAlignment: MainAxisAlignment.start,
                                foregroundColor: context.colors.textSecondary,
                                onPressed: () => context.go(
                                  Uri(
                                    path: '/industries',
                                    queryParameters: {'industry': key},
                                  ).toString(),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.data != null)
                                      Text(
                                        businessCounts[key] == 0
                                            ? '준비 중'
                                            : '${businessCounts[key]}곳',
                                        style: context.typo.body(
                                          12,
                                          color: context.colors.textMuted,
                                        ),
                                      ),
                                    const SizedBox(width: AppSpace.xs),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 14,
                                      color: context.colors.textMuted,
                                    ),
                                  ],
                                ),
                                child: Expanded(
                                  child: Text(
                                    groups[key]?.first.industryName ??
                                        labels[key]!,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              '여러 사업을 하는 기업은 둘 이상의 업종에서 찾을 수 있어요.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
          ],
        );
      },
    );
  }
}
