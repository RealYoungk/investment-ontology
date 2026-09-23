import 'package:flutter/material.dart';

import 'components/components.dart';
import 'tokens.dart';

/// Debug-only, same components and tokens as production pages.
class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return PageFrame(
      children: [
        const PageHeading(
          title: 'Research Desk',
          subtitle: '공통 컴포넌트 · 표시 값은 예시입니다',
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final entry in [
              ('바탕', c.background),
              ('표면', c.surface),
              ('탐색', c.inverse),
              ('강조', c.accent),
              ('상승', c.marketUp),
              ('하락', c.marketDown),
            ])
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.$2,
                      border: Border.all(color: c.border),
                      borderRadius: context.shape.borderRadius,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(entry.$1),
                ],
              ),
          ],
        ),
        const SizedBox(height: 32),
        Text('기업을 이해하는 리서치', style: t.pageTitle),
        Text('섹션 제목', style: t.sectionTitle),
        Text('본문은 숫자의 의미와 다음 행동을 설명합니다.', style: t.bodyText),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButton(
              label: '기업 살펴보기',
              variant: AppButtonVariant.primary,
              onPressed: () {},
            ),
            AppButton(label: '비교에 담기', onPressed: () {}),
            const AppButton(label: '선택 필요', onPressed: null),
            AppButton(
              label: '근거 보기',
              variant: AppButtonVariant.link,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('계산 근거'),
                  content: const Text('실제 화면에서는 산식과 입력값, 공시 출처를 표시합니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const TextField(
          decoration: InputDecoration(
            labelText: '기업 검색',
            hintText: '기업 이름 또는 종목코드',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            Text('+1.65%', style: t.metricValue.copyWith(color: c.marketUp)),
            Text('−1.65%', style: t.metricValue.copyWith(color: c.marketDown)),
            Text('—', style: t.metricValue.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(height: 24),
        const AppNotice(message: '계산에 필요한 현금흐름 데이터가 아직 없습니다.'),
        const SizedBox(height: 24),
        const ExpansionTile(
          title: Text('기준·출처'),
          children: [ListTile(title: Text('공시 출처와 산식은 펼쳐서 확인합니다.'))],
        ),
      ],
    );
  }
}
