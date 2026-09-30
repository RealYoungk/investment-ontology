import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/tokens.dart';
import 'business_guide_navigation.dart';
import 'package_structure_diagram.dart';

/// A product-family lesson: issuer attribution comes from the stored profile.
/// The shared technical explanation is not a claim about sales or customers.
class SubstrateGuide extends StatefulWidget {
  const SubstrateGuide({super.key});
  @override
  State<SubstrateGuide> createState() => _SubstrateGuideState();
}

class _SubstrateGuideState extends State<SubstrateGuide> {
  int _step = 0;
  static const titles = ['어떤 부품인가요?', '언제 장비를 쓰나요?', '무엇을 해결하나요?'];
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '칩을 받치는 기판,\n그 안의 회로를 검사하는 장비',
            style: t.body(24, weight: FontWeight.w700).copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '이 회사가 파는 제품을 이해하려면, 먼저 장비 안에 들어가는 기판부터 보면 됩니다.',
            style: t.body(14, color: c.textSecondary).copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (var i = 0; i < titles.length; i++)
                ChoiceChip(
                  label: Text('${i + 1}. ${titles[i]}'),
                  selected: _step == i,
                  onSelected: (_) => setState(() => _step = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          if (_step == 0) ...[
            _heading('칩과 메인보드 사이에는 작은 회로판이 있습니다.'),
            _body(
              'CPU 같은 반도체 칩은 아래의 패키지 기판을 거쳐 메인보드와 전기 신호를 주고받습니다. 기판 안의 선이 신호가 지나가는 구리 배선입니다.',
            ),
            const PackageStructureDiagram(),
            _note('알파인더 자체 제작 · 연결 관계를 설명하는 개념도이며 실제 크기·층수·배선과 다릅니다.'),
          ],
          if (_step == 1) ...[
            _heading('칩을 올리기 전, 기판의 회로를 만드는 동안 씁니다.'),
            _body('기판 한 장이 공장을 지나가는 순서로 보면 쉽습니다.'),
            _flowStep('1', '회로를 만듭니다', '기판 위에 전기가 흐를 구리 배선을 형성합니다.'),
            _flowArrow('회로가 만들어지면'),
            _flowStep(
              '2',
              '잘못된 부분을 찾습니다',
              '배선의 모양을 광학 영상으로 검사합니다.',
              equipment: 'AOI · 검사',
            ),
            _flowArrow('검사에서 표시한 부분을'),
            _flowStep(
              '3',
              '확대해서 확인합니다',
              '작업자가 결함 영상을 보고 상태를 확인합니다.',
              equipment: 'VRS · 확인',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                '문제가 없는 기판 → 다음 제조 공정',
                style: t.body(13, color: c.accent, weight: FontWeight.w600),
              ),
            ),
            _flowArrow('결함이 있고, 수리할 수 있다면'),
            _flowStep(
              '4',
              '불필요한 구리를 제거합니다',
              '쇼트·돌기 등 수리 가능한 결함을 처리합니다.',
              equipment: 'AOR · 수리',
            ),
            const SizedBox(height: AppSpace.md),
            _note(
              '이 검사·수리는 기판을 만드는 중에 일어납니다. 완성된 기판에 칩을 올리는 조립은 그 이후입니다. 실제 검사 위치와 반복 횟수는 제조 공정에 따라 다릅니다.',
            ),
          ],
          if (_step == 2) ...[
            _heading('회로 옆으로 튀어나온 구리를 보세요.'),
            _body(
              '구리 배선 옆에 불필요한 부분이 튀어나온 상황을 그렸습니다. 빨간 원 안을 비교하면, 수리 후에는 돌출 부분이 제거되어 있습니다.',
            ),
            const RepairPrincipleDiagram(),
            _source(
              '실제 수리 사진 보기 · 기가비스 원문',
              'https://www.gigavis.com/kr/product/aor/contents',
            ),
            _body(
              'AOI는 이런 결함을 찾고, VRS는 표시된 부분을 확대해 확인하도록 돕습니다. AOR는 수리할 수 있는 불필요한 구리를 제거합니다.',
            ),
            _heading('고객은 버릴 기판을 줄이기 위해 장비를 삽니다.'),
            _body(
              '불량을 일찍 찾으면 다음 공정에 불량품이 넘어가는 것을 줄일 수 있습니다. 수리가 가능한 기판을 살리면 이미 투입한 재료와 가공 비용의 손실도 줄일 수 있습니다.',
            ),
            _note(
              '알파인더 자체 제작 원리도입니다. 실제 검사 영상이나 성능 측정값이 아니며, 모든 불량을 수리할 수 있다는 뜻은 아닙니다.',
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          BusinessGuideNavigation(
            step: _step,
            onChanged: (value) => setState(() => _step = value),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Text(
      text,
      style: context.typo
          .body(18, weight: FontWeight.w700)
          .copyWith(height: 1.5),
    ),
  );
  Widget _body(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Text(text, style: context.typo.body(14).copyWith(height: 1.8)),
  );
  Widget _note(String text) => Text(
    text,
    style: context.typo
        .body(12, color: context.colors.textSecondary)
        .copyWith(height: 1.7),
  );
  Widget _flowArrow(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Icon(
            Icons.arrow_downward,
            size: 18,
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            label,
            style: context.typo.body(12, color: context.colors.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _flowStep(
    String number,
    String title,
    String body, {
    String? equipment,
  }) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: equipment == null
          ? context.colors.background
          : context.colors.accentSubtle,
      borderRadius: context.shape.borderRadius,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            number,
            style: context.typo.body(
              20,
              color: context.colors.accent,
              weight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (equipment != null) ...[
                Text(
                  equipment,
                  style: context.typo.body(
                    12,
                    color: context.colors.accent,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: context.typo.body(16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: context.typo
                    .body(13, color: context.colors.textSecondary)
                    .copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _source(String label, String url) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: () => launchUrl(Uri.parse(url)),
      child: Text(
        '$label ↗',
        style: context.typo.body(11, color: context.colors.textSecondary),
      ),
    ),
  );
}
