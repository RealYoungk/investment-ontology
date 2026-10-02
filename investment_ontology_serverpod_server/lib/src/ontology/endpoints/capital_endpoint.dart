import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../dart/public_capital_document.dart';
import '../disclosure/capital_structure_store.dart';

class CapitalEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;
  static final _busy = <String>{};
  Future<Company?> _company(Session session, String corpCode) => Company.db
      .findFirstRow(session, where: (t) => t.corpCode.equals(corpCode));
  Future<DartFiling?> _latest(Session session, int id) async {
    final filings = await DartFiling.db.find(
      session,
      where: (t) => t.companyId.equals(id) & t.reportCode.notEquals(null),
    );
    final valid =
        filings.where((f) => CapitalStructureStore.period(f) != null).toList()
          ..sort((a, b) {
            final period = CapitalStructureStore.period(b)!
                .compareTo(CapitalStructureStore.period(a)!);
            return period != 0 ? period : b.rceptNo.compareTo(a.rceptNo);
          });
    return valid.firstOrNull;
  }

  /// Public, stored-only read. Current report supersedes older snapshots.
  Future<String> summary(Session session, String corpCode) async {
    final company = await _company(session, corpCode);
    if (company == null) return jsonEncode({'state': 'notCollected'});
    final filing = await _latest(session, company.id!);
    if (filing == null) return jsonEncode({'state': 'noFiling'});
    final snapshots = await ResearchSnapshot.db.find(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.kind.equals(CapitalStructureStore.kind),
      orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
    );
    for (final s in snapshots) {
      final data = jsonDecode(s.payload) as Map<String, dynamic>;
      if (data['receipt'] != filing.rceptNo) continue;
      return jsonEncode({
        ...data,
        'state': 'ready',
        'collectedAt': s.createdAt.toIso8601String(),
      });
    }
    return jsonEncode({
      'state': 'notCollected',
      'reportName': filing.reportName,
      'receipt': filing.rceptNo,
      'periodEnd': CapitalStructureStore.period(filing),
    });
  }

  /// Explicit administrator collection: one latest report, public source only.
  Future<int> collect(Session session, String corpCode) async {
    OntologyAccess.requireAdmin(session);
    final c = await _company(session, corpCode);
    if (c == null) throw IngestException(message: '기업을 찾을 수 없습니다.');
    final f = await _latest(session, c.id!);
    if (f == null) throw IngestException(message: '정기보고서 목록을 먼저 수집하세요.');
    if (!_busy.add(corpCode)) {
      throw IngestException(message: '이 기업의 자본 자료 수집 중입니다.');
    }
    final reader = PublicCapitalDocument();
    try {
      final mode = await session.db.unsafeQuery('SHOW transaction_read_only');
      if (mode.first.first == 'on') {
        throw IngestException(message: '읽기 전용 DB입니다. 운영 관리자 화면에서 실행하세요.');
      }
      final body = await reader.fetch(f.rceptNo, c.corpCode);
      return await CapitalStructureStore.save(
        session,
        c,
        f,
        body.document,
        urls: body.urls,
      );
    } on FormatException {
      throw IngestException(
        message: '공시 원문이나 보고서의 기업·수량 기준을 확인하지 못했습니다. 기존 자료를 유지합니다.',
      );
    } finally {
      reader.close();
      _busy.remove(corpCode);
    }
  }
}
