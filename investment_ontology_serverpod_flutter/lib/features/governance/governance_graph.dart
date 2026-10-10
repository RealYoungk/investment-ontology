import 'package:flutter/widgets.dart';

import '../../design/components/charts/relationship_diagram.dart';
import 'governance_view.dart';

/// Service mapping keeps inferred identity, finance formatting and navigation
/// outside the independently testable design diagram.
class GovernanceGraph extends StatelessWidget {
  const GovernanceGraph({
    super.key,
    required this.center,
    required this.left,
    required this.right,
    required this.onTap,
    this.leftTitle = '주주',
    this.rightTitle = '출자',
    this.maxPerSide,
  });
  final String center, leftTitle, rightTitle;
  final List<GovernanceNode> left, right;
  final ValueChanged<GovernanceNode> onTap;
  final int? maxPerSide;
  RelationshipDiagramNode<GovernanceNode> _node(GovernanceNode n) =>
      RelationshipDiagramNode(
        value: n,
        name: n.name,
        kind: n.corpCode != null
            ? 'company'
            : n.personId != null
            ? 'person'
            : 'name',
        weight: n.weight,
        weightLabel: formatRatio(n.weight),
        linked: n.linked,
        estimated: n.estimated,
        tooltip: [
          n.name,
          ?n.detail,
          if (n.estimated) '추정 연결: 지분으로 이어진 기업들의 주주 명단에 같은 이름',
          if (n.corpCode != null) '눌러서 이 기업의 지배구조 보기',
          if (n.corpCode == null && n.personId != null) '눌러서 인물 보기',
          if (!n.linked) '상장사·인물로 확인되지 않은 이름',
        ].join('\n'),
      );
  @override
  Widget build(BuildContext context) => RelationshipDiagram<GovernanceNode>(
    center: center,
    left: left.map(_node).toList(),
    right: right.map(_node).toList(),
    onTap: (node) => onTap(node.value),
    leftTitle: leftTitle,
    rightTitle: rightTitle,
    maxPerSide: maxPerSide,
  );
}
