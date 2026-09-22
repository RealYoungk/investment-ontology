import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../disclosure/ownership_groups.dart';

/// 지분으로 이어진 상장사 묶음 조회.
class GroupEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// 두 곳 이상으로 이루어진 묶음. 시가총액 합이 큰 순서.
  ///
  /// 목록 화면은 지분 연결을 쓰지 않아 빼고 보낸다 (응답이 절반 아래로 줄어든다).
  Future<List<CompanyGroup>> list(Session session) async => [
    for (final g in await OwnershipGroups(session).all())
      g.copyWith(edges: const []),
  ];

  /// [corpCode] 기업이 속한 묶음. 어느 묶음에도 없으면 null.
  Future<CompanyGroup?> of(Session session, String corpCode) async {
    for (final g in await OwnershipGroups(session).all()) {
      if (g.members.any((m) => m.company.corpCode == corpCode)) return g;
    }
    return null;
  }
}
