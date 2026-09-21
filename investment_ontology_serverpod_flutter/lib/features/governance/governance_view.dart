import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// 그래프 노드 하나: 주주 또는 출자 대상.
class GovernanceNode {
  const GovernanceNode({
    required this.name,
    required this.weight,
    this.corpCode,
    this.personId,
    this.detail,
    this.estimated = false,
  });

  final String name;

  /// 지분율 (%). 없으면 null.
  final double? weight;

  /// 상장사면 그 기업으로 건너간다.
  final String? corpCode;

  /// 확인된(또는 추정한) 인물이면 인물 페이지로 건너간다.
  final int? personId;

  /// 관계 문구(주주) 또는 출자 목적(출자).
  final String? detail;

  /// 추정 연결 (점선).
  final bool estimated;

  bool get linked => corpCode != null || personId != null;
}

/// [CompanyGovernance]를 화면용으로 묶는다.
class GovernanceView {
  GovernanceView(this.data)
    : _corpCodes = {for (final c in data.companies) c.id: c.corpCode};

  final CompanyGovernance data;
  final Map<int, String> _corpCodes;

  String? corpCodeOf(int? companyId) =>
      companyId == null ? null : _corpCodes[companyId];

  Person? personOf(int? id) =>
      id == null ? null : data.persons.where((p) => p.id == id).firstOrNull;

  /// 보통주로 볼 표기. 표기가 없으면 보통주로 본다 (서버 규칙과 같다).
  static bool isCommon(String? kind) {
    if (kind == null) return true;
    final k = kind.replaceAll(' ', '');
    return k.contains('보통') || (k.contains('의결권') && !k.contains('없'));
  }

  /// 주주를 한 사람·한 기업 단위로 묶고 보통주 지분율을 더한다. 큰 순서.
  List<GovernanceNode> holders() {
    final groups = <String, List<ShareholderEntry>>{};
    for (final s in data.shareholders) {
      if (s.isTotal) continue;
      final key = s.holderCompanyId != null
          ? 'c${s.holderCompanyId}'
          : s.holderPersonId != null
          ? 'p${s.holderPersonId}'
          : 'n${s.holderName.replaceAll(' ', '')}';
      (groups[key] ??= []).add(s);
    }
    final nodes = [
      for (final g in groups.values)
        () {
          final first = g.first;
          final common = [
            for (final s in g)
              if (isCommon(s.stockKind) && s.ratioEnd != null) s.ratioEnd!,
          ];
          return GovernanceNode(
            name: first.holderName,
            weight: common.isEmpty ? null : common.reduce((a, b) => a + b),
            corpCode: corpCodeOf(first.holderCompanyId),
            personId: first.holderPersonId,
            detail: first.relationText,
            estimated:
                first.holderLinkBasis == DisclosureLinkBasis.ownershipCluster,
          );
        }(),
    ];
    nodes.sort((a, b) => (b.weight ?? -1).compareTo(a.weight ?? -1));
    return nodes;
  }

  /// 출자 대상. 상장사를 먼저(그래프에서 건너갈 수 있는 노드), 그다음 경영참여, 지분율 큰 순서.
  /// 지분 100%인 해외 자회사가 많아 지분율만으로 정렬하면 상장 계열사가 밀려난다.
  List<GovernanceNode> investments() {
    final nodes = [
      for (final i in data.investments)
        if (!i.isTotal)
          GovernanceNode(
            name: i.investeeName,
            weight: i.ratioEnd,
            corpCode: corpCodeOf(i.investeeCompanyId),
            detail: i.purpose,
          ),
    ];
    int rank(GovernanceNode n) =>
        (n.corpCode != null ? 0 : 2) +
        ((n.detail?.contains('경영') ?? false) ? 0 : 1);
    nodes.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : (b.weight ?? -1).compareTo(a.weight ?? -1);
    });
    return nodes;
  }

  /// 최대주주 및 특수관계인 보통주 지분율 합 (합계 행이 있으면 그 값).
  double? holderTotal() {
    final totals = [
      for (final s in data.shareholders)
        if (s.isTotal && isCommon(s.stockKind) && s.ratioEnd != null)
          s.ratioEnd!,
    ];
    if (totals.isNotEmpty) return totals.first;
    final sum = [
      for (final n in holders())
        if (n.weight != null) n.weight!,
    ];
    return sum.isEmpty ? null : sum.reduce((a, b) => a + b);
  }
}

String formatRatio(double? v) => v == null
    ? '—'
    : '${v.toStringAsFixed(v >= 10 || v == v.roundToDouble() ? 1 : 2)}%';
