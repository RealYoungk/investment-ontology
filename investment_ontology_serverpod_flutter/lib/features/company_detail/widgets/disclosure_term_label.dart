import 'package:flutter/material.dart';
import 'package:shad/shad.dart';

import '../../../design/tokens.dart';

String? disclosureTermHelp(String label) {
  const meanings = {
    '통화선도': '미래에 외화를 정해 둔 환율로 사고파는 계약입니다.',
    '금리스왑': '고정금리와 변동금리의 이자 지급 조건을 맞바꾸는 계약입니다.',
    '미결제 약정': '아직 끝나지 않은 계약의 기준 금액입니다. 손실액이나 실제 지급액과 다릅니다.',
    '평가손익': '현재 시장 가격으로 계산한 이익·손실입니다. 확정된 현금 수익과 다릅니다.',
    '공정가치': '현재 시점에 계약을 평가한 값입니다. 자산은 받을 가치, 부채는 부담할 가치를 뜻합니다.',
    'KRW': '원화 표시입니다. 천원은 1,000원 단위입니다.',
    'EUR': '유로 표시입니다. 천EUR는 1,000유로 단위입니다. 원화 평가손익과 구분해서 보세요.',
  };
  final matches = [
    for (final entry in meanings.entries)
      if (label.contains(entry.key)) '${entry.key}: ${entry.value}',
  ];
  return matches.isEmpty ? null : matches.join('\n\n');
}

/// Help stays next to the actual term. Hover, keyboard focus and tap all work.
class DisclosureTermLabel extends StatefulWidget {
  const DisclosureTermLabel(this.label, {super.key, this.style});
  final String label;
  final TextStyle? style;
  @override
  State<DisclosureTermLabel> createState() => _DisclosureTermLabelState();
}

class _DisclosureTermLabelState extends State<DisclosureTermLabel> {
  final _controller = ShadTooltipController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final help = disclosureTermHelp(widget.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.label,
            style:
                widget.style ??
                context.typo.body(12.5, color: context.colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (help != null)
          ShadTooltip(
            controller: _controller,
            builder: (_) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width < 400 ? 280 : 320,
              ),
              child: Text(help),
            ),
            child: Semantics(
              label: '${widget.label} 설명',
              button: true,
              child: ShadIconButton.ghost(
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                onPressed: _controller.show,
                icon: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
