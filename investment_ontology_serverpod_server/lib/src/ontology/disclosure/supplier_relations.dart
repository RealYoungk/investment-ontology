import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disclosure_links.dart';
import 'disclosure_values.dart';
import 'supplier_rows.dart';

/// "주요 원재료" 표의 매입처를 공급 관계로 넣는다 (AI 없이, [SupplierRows] 규칙).
///
/// 표를 그대로 옮긴 것이라 사람 검수 없이 확정하되, 누가 넣었는지를 `reviewedBy`에
/// 남겨 화면에서 구분할 수 있게 한다. 이미 있는 관계(사람이 결정했거나 AI가 뽑아 둔
/// 것)는 건드리지 않는다.
abstract final class SupplierRelations {
  static const model = '표 규칙 (원재료 매입처 열)';

  /// 이름을 상장사에 잇는다. 정확히 하나와 맞을 때만 (이름만 남기는 것은 그대로 둔다).
  static Future<int> store(Session session, BusinessDocument doc) async {
    final rows = SupplierRows.parse(doc.text);
    if (rows.isEmpty) return 0;
    final company = await Company.db.findById(session, doc.companyId);
    final report = await DisclosureReport.db.findById(session, doc.reportId);
    if (company == null || report == null) return 0;

    final listed = await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
    );
    final byName = DisclosureLinks.companiesByName(listed);
    final names = {for (final c in listed) c.id!: c.name};

    final existing = {
      for (final r in await OntologyRelation.db.find(
        session,
        where: (t) =>
            t.factKind.equals(RelationFactKind.businessDocument) &
            t.factId.equals(doc.id!),
      ))
        '${r.predicate.name}|${r.subjectName}',
    };
    // 해마다 표기가 달라진다 ("영풍전자㈜" · "영풍전자", "Intel" · "INTEL").
    // 이 기업에 이미 쓰인 표기가 있으면 그것으로 맞춘다.
    final spelling = <String, String>{
      for (final r in await OntologyRelation.db.find(
        session,
        where: (t) =>
            t.objectCompanyId.equals(company.id!) &
            t.factKind.equals(RelationFactKind.businessDocument),
        orderBy: (t) => t.bsnsYear.desc(),
      ))
        DisclosureValues.companyName(r.subjectName): r.subjectName,
    };

    final now = DateTime.now().toUtc();
    final add = <OntologyRelation>[];
    for (final row in rows) {
      final otherId = byName[DisclosureValues.companyName(row.name)];
      if (otherId == company.id) continue;
      final key = DisclosureValues.companyName(row.name);
      final subjectName = otherId != null
          ? names[otherId]!
          : (spelling[key] ?? row.name);
      spelling.putIfAbsent(key, () => subjectName);
      if (!existing.add('suppliesTo|$subjectName')) continue;
      add.add(
        OntologyRelation(
          predicate: RelationPredicate.suppliesTo,
          subjectCompanyId: otherId,
          subjectName: subjectName,
          objectCompanyId: company.id,
          objectName: company.name,
          bsnsYear: doc.bsnsYear,
          sourceId: report.sourceId,
          factKind: RelationFactKind.businessDocument,
          factId: doc.id!,
          // 표를 그대로 옮긴 것이라 DART API로 받은 관계와 같은 급으로 본다.
          extractedBy: RelationOrigin.ai,
          status: RelationStatus.verified,
          evidence: row.evidence,
          extractorModel: model,
          reviewedAt: now,
          reviewedBy: model,
        ),
      );
    }
    if (add.isEmpty) return 0;
    await OntologyRelation.db.insert(session, add);
    return add.length;
  }
}
