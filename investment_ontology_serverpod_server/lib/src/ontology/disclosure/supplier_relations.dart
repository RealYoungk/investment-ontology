import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disclosure_links.dart';
import 'disclosure_values.dart';
import 'production_facts.dart';
import 'supplier_rows.dart';

/// "주요 원재료" 표의 매입처를 공급 관계로 넣는다 (AI 없이, [SupplierRows] 규칙).
///
/// 표를 그대로 옮긴 것이라 사람 검수 없이 확정하되, 누가 넣었는지를 `reviewedBy`에
/// 남겨 화면에서 구분할 수 있게 한다. 이미 있는 관계(사람이 결정했거나 AI가 뽑아 둔
/// 것)는 건드리지 않는다.
abstract final class SupplierRelations {
  static const model = '표 규칙 (원재료 매입처·주요 매출처)';

  /// 이름을 상장사에 잇는다. 정확히 하나와 맞을 때만 (이름만 남기는 것은 그대로 둔다).
  static Future<int> store(
    Session session,
    BusinessDocument doc, {

    /// 상장사 목록. 여러 문서를 돌릴 때는 한 번만 읽어 넘긴다.
    List<Company>? listed,
  }) async {
    final company = await Company.db.findById(session, doc.companyId);
    // 지주회사(KSIC 64992) 본문은 대부분 자회사 이야기다 — 매입처를 지주사 것으로
    // 넣게 되므로 통째로 건너뛴다 (ProductionFacts와 같은 규칙).
    if (company?.industryCode == ProductionFacts.holdingCompanyCode) return 0;
    final rows = SupplierRows.parse(doc.text);
    final buyers = [
      for (final b in SupplierRows.customers(doc.text))
        (name: b.name, share: null as double?, evidence: b.evidence),
      ...SupplierRows.customerRows(doc.text),
    ];
    if (rows.isEmpty && buyers.isEmpty) return 0;
    final report = await DisclosureReport.db.findById(session, doc.reportId);
    if (company == null || report == null) return 0;

    final companies =
        listed ??
        await Company.db.find(
          session,
          where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
        );
    final byName = DisclosureLinks.companiesByName(companies);
    // 종목명은 "KEC"·"DB"처럼 짧아 다른 회사(인도 KEC International)를 잘못 잇는다.
    // 짧은 이름은 정식 이름으로 맞을 때만 상장사에 잇는다.
    final byFullName = _byFullName(companies);
    int? link(String key) {
      final id = byName[key];
      if (id == null) return null;
      return key.length >= 5 || byFullName.containsKey(key) ? id : null;
    }

    final names = {for (final c in companies) c.id!: c.name};

    final existing = {
      for (final r in await OntologyRelation.db.find(
        session,
        where: (t) =>
            t.factKind.equals(RelationFactKind.businessDocument) &
            t.factId.equals(doc.id!),
      ))
        '${r.predicate.name}|${r.subjectName}|${r.objectName}',
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

    // 자회사 표에는 모회사가 매출처로 나온다 ("LS Electric Co., Ltd") — 영문 이름으로도 자기 자신을 거른다.
    String slug(String? n) =>
        DisclosureValues.companyName(n).replaceAll(RegExp(r'[.,]'), '');
    final selfEng = slug(company.nameEng);
    bool isSelf(String name) => selfEng.isNotEmpty && slug(name) == selfEng;

    final now = DateTime.now().toUtc();
    final add = <OntologyRelation>[];
    for (final row in rows) {
      final otherId = link(DisclosureValues.companyName(row.name));
      if (otherId == company.id) continue;
      final key = DisclosureValues.companyName(row.name);
      final subjectName = otherId != null
          ? names[otherId]!
          : (spelling[key] ?? row.name);
      spelling.putIfAbsent(key, () => subjectName);
      if (!existing.add('suppliesTo|$subjectName|${company.name}')) continue;
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
    // 매출처는 방향이 반대다 (이 기업 → 매출처).
    for (final row in buyers) {
      final otherId = link(DisclosureValues.companyName(row.name));
      if (otherId == company.id || isSelf(row.name)) continue;
      final key = DisclosureValues.companyName(row.name);
      final objectName = otherId != null
          ? names[otherId]!
          : (spelling[key] ?? row.name);
      spelling.putIfAbsent(key, () => objectName);
      if (!existing.add('suppliesTo|${company.name}|$objectName')) continue;
      add.add(
        OntologyRelation(
          predicate: RelationPredicate.suppliesTo,
          subjectCompanyId: company.id,
          subjectName: company.name,
          objectCompanyId: otherId,
          objectName: objectName,
          bsnsYear: doc.bsnsYear,
          // 매출처 표의 비중(%). 문장에서 읽은 것은 없다.
          weight: row.share,
          sourceId: report.sourceId,
          factKind: RelationFactKind.businessDocument,
          factId: doc.id!,
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

  /// 정식 이름(종목명 제외)으로만 만든 이름 → 상장사 id (하나와 맞을 때만).
  static Map<String, int> _byFullName(Iterable<Company> companies) {
    final ids = <String, Set<int>>{};
    for (final c in companies) {
      final key = DisclosureValues.companyName(c.name);
      if (key.isNotEmpty) (ids[key] ??= {}).add(c.id!);
    }
    return {
      for (final e in ids.entries)
        if (e.value.length == 1) e.key: e.value.single,
    };
  }
}
