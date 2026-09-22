import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// 지분 묶음에서 "얼마나 큰 일인가"를 셈하는 곳. 지분 가치 = 가진 기업 시가총액 × 지분율.
///
/// 같은 쌍이 최대주주 명단과 타법인출자에 둘 다 있으면 지분율이 큰 쪽 하나만 센다.
class GroupMath {
  GroupMath(this.group)
    : capById = {
        for (final m in group.members)
          if (m.marketCap case final cap? when cap > BigInt.zero)
            m.company.id: cap.toDouble(),
      } {
    for (final e in group.edges) {
      final key = (e.fromCompanyId, e.toCompanyId);
      final prev = bestByPair[key];
      if (prev == null || (e.ratio ?? 0) > (prev.ratio ?? 0)) {
        bestByPair[key] = e;
      }
    }
  }

  final CompanyGroup group;
  final Map<int, double> capById;
  final bestByPair = <(int, int), GroupEdge>{};

  /// 한 연결의 지분 가치 (원). 가진 기업 시가총액이나 지분율이 없으면 null.
  double? stakeValue(GroupEdge e) {
    final cap = capById[e.toCompanyId];
    if (cap == null || e.ratio == null) return null;
    return cap * e.ratio! / 100;
  }

  /// 한 연결의 지분 가치가 가진 쪽 시가총액의 몇 %인지.
  double? holderShare(GroupEdge e) {
    final value = stakeValue(e);
    final own = capById[e.fromCompanyId];
    if (value == null || own == null) return null;
    return value / own * 100;
  }

  /// [companyId]가 묶음 안 상장사에 가진 지분의 시가 합 (원). 하나도 없으면 null.
  double? heldValueOf(int companyId) {
    double? sum;
    for (final e in bestByPair.values) {
      if (e.fromCompanyId != companyId) continue;
      final v = stakeValue(e);
      if (v != null) sum = (sum ?? 0) + v;
    }
    return sum;
  }

  /// 묶음 안 기업들이 [companyId]에 가진 지분율의 합 (%). 하나도 없으면 null.
  double? heldRatioOf(int companyId) {
    double? sum;
    for (final e in bestByPair.values) {
      if (e.toCompanyId != companyId || e.ratio == null) continue;
      sum = (sum ?? 0) + e.ratio!;
    }
    return sum;
  }
}
