import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../dart/public_capital_document.dart';
import '../disclosure/bond_collection_scope.dart';
import '../disclosure/bond_trends.dart';
import '../disclosure/capital_structure_store.dart';

class BondEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;
  static final _busy = <String>{};
  static const _parserVersion = 3;

  Future<Company?> _company(Session session, String code) =>
      Company.db.findFirstRow(session, where: (t) => t.corpCode.equals(code));
  Future<List<DartFiling>> _scope(Session session, int id) async =>
      BondCollectionScope.select(
        await DartFiling.db.find(session, where: (t) => t.companyId.equals(id)),
      );
  Future<List<ResearchSnapshot>> _snapshots(Session session, int id) =>
      ResearchSnapshot.db.find(
        session,
        where: (t) =>
            t.companyId.equals(id) & t.kind.equals(CapitalStructureStore.kind),
        orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      );

  /// Public, stored-only read. Missing final corrections remain visible gaps.
  Future<String> trends(Session session, String corpCode) async {
    final company = await _company(session, corpCode);
    if (company == null) {
      return jsonEncode({'state': 'noCompany', 'points': [], 'changes': []});
    }
    final scope = await _scope(session, company.id!);
    final snapshots = await _snapshots(session, company.id!);
    final byReceipt = <String, Map<String, dynamic>>{};
    for (final snapshot in snapshots) {
      final data = jsonDecode(snapshot.payload) as Map<String, dynamic>;
      if ((data['corpCode'] == null
              ? data['companyName'] != company.name
              : data['corpCode'] != company.corpCode) ||
          (data['version'] as num? ?? 0) < _parserVersion) {
        continue;
      }
      byReceipt.putIfAbsent(
        '${data['receipt']}',
        () => {
          ...data,
          'state': 'ready',
          'collectedAt': snapshot.createdAt.toIso8601String(),
        },
      );
    }
    final periods = [
      for (final f in scope)
        {
          ...?byReceipt[f.rceptNo],
          'receipt': f.rceptNo,
          'reportName': f.reportName,
          'periodEnd': CapitalStructureStore.period(f),
          'state':
              byReceipt[f.rceptNo]?['periodEnd'] ==
                  CapitalStructureStore.period(f)
              ? 'ready'
              : 'notCollected',
        },
    ];
    return jsonEncode({
      ...BondTrends.build(periods),
      'corpCode': corpCode,
      if (scope.isEmpty) 'state': 'noFiling',
    });
  }

  /// Resume at most six reports per call; shared writes always require admin.
  /// Does not widen the financial collection scope or start a global backfill.
  Future<String> collect(Session session, String corpCode) async {
    OntologyAccess.requireAdmin(session);
    final company = await _company(session, corpCode);
    if (company == null) throw IngestException(message: '기업을 찾을 수 없습니다.');
    final mode = await session.db.unsafeQuery('SHOW transaction_read_only');
    if (mode.first.first == 'on') {
      throw IngestException(message: '읽기 전용 DB입니다. 운영 관리자 화면에서 실행하세요.');
    }
    if (!_busy.add(corpCode)) {
      throw IngestException(message: '이 기업의 사채 추이 자료 수집 중입니다.');
    }
    final reader = PublicCapitalDocument();
    try {
      final scope = await _scope(session, company.id!);
      if (scope.isEmpty) throw IngestException(message: '정기보고서 목록을 먼저 수집하세요.');
      final snapshots = await _snapshots(session, company.id!);
      final stored = {
        for (final s in snapshots)
          if ((jsonDecode(s.payload)['version'] as num? ?? 0) >= _parserVersion)
            jsonDecode(s.payload)['receipt'] as String,
      };
      final pending = scope.reversed
          .where((f) => !stored.contains(f.rceptNo))
          .toList();
      final errors = <Map<String, String>>[];
      var collected = 0;
      for (final f in pending.take(6)) {
        try {
          final body = await reader.fetch(f.rceptNo, company.corpCode);
          await CapitalStructureStore.save(
            session,
            company,
            f,
            body.document,
            urls: body.urls,
          );
          collected++;
        } catch (e) {
          session.log(
            'CB history collection failed: ${f.rceptNo} (${e.runtimeType})',
            level: LogLevel.warning,
          );
          errors.add({
            'receipt': f.rceptNo,
            'message': '원문 또는 기업·보고기간·표 기준 확인 실패',
          });
        }
      }
      return jsonEncode({
        'collected': collected,
        'remaining': pending.length - collected,
        'errors': errors,
      });
    } finally {
      reader.close();
      _busy.remove(corpCode);
    }
  }
}
