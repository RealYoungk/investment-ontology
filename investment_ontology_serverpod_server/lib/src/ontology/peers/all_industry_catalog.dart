import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ingest/ksic_revision.dart';
import 'discovery_taxonomy.dart';
import 'discovery_coverage.dart';
import 'discovery_offerings.dart';
import 'industry_discovery_catalog.dart';
import 'kind_product_catalog.dart';
import 'issuer_offering_catalog.dart';
import 'discovery_resolution.dart';

/// Every listed company remains discoverable, even without a business filing.
/// Registered activities and filing-backed products remain distinct evidence.
abstract final class AllIndustryCatalog {
  static Future<IndustryDiscovery> read(Session session) async {
    final semiconductor = await IndustryDiscoveryCatalog.read(session);
    final revision = await KsicRevision.current(session);
    final industries = await Industry.db.find(
      session,
      where: (t) => t.revision.equals(revision.revision),
    );
    final byCode = {for (final i in industries) i.code: i};
    // Some shortened labels coincide across parent/child codes. Show one button.
    final canonicalGroups = <(String, String), String>{};
    final ordered = [...industries]
      ..sort((a, b) => a.code.length.compareTo(b.code.length));
    for (final item in ordered) {
      canonicalGroups.putIfAbsent(
        (
          DiscoveryTaxonomy.category(item.code).$1,
          DiscoveryTaxonomy.label(item.code, item.name),
        ),
        () => item.code,
      );
    }
    final companies = await Company.db.find(
      session,
      where: (t) => t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
    );
    final activities = <IndustryActivity>[
      for (final c in companies) ...KindProductCatalog.forCompany(c),
      for (final c in companies) ...IssuerOfferingCatalog.forCompany(c),
      ...await IndustryDiscoveryCatalog.businessActivities(session),
      for (final a in semiconductor.activities)
        a.copyWith(
          industryKey: 'semiconductor',
          industryName: '반도체',
          classificationBasis: 'filing',
          groupName: const {
            'chip': '칩 설계·제조',
            'design': '설계 IP·디자인하우스',
            'equipment': '장비',
            'material': '소재',
            'component': '부품·소모품',
            'service': '위탁생산·패키징·테스트',
          }[a.role],
        ),
    ];
    // Prefer the filing-derived offering over a broad registration-only join.
    final filingSectors = activities
        .where(
          (a) =>
              a.classificationBasis == 'filing' ||
              a.classificationBasis == 'filing_activity',
        )
        .map((a) => (a.corpCode, a.industryKey))
        .toSet();
    activities.removeWhere(
      (a) =>
          a.classificationBasis == 'kind_registered' &&
          filingSectors.contains((a.corpCode, a.industryKey)),
    );
    for (var i = 0; i < activities.length; i++) {
      activities[i] = DiscoveryOfferings.normalize(activities[i]);
    }
    for (final c in companies) {
      final official = byCode[c.industryCode];
      final category = DiscoveryTaxonomy.category(official?.code);
      var group = official;
      while (group != null &&
          group.level > 4 &&
          group.code != '29271' &&
          group.code != '64992') {
        final parent = byCode[group.parentCode];
        if (parent == null ||
            DiscoveryTaxonomy.category(parent.code).$1 != category.$1) {
          break;
        }
        group = parent;
      }
      final groupName = group == null
          ? '업종 정보 미확보'
          : DiscoveryTaxonomy.label(group.code, group.name);
      final label = official == null
          ? '업종 정보 미확보'
          : DiscoveryTaxonomy.label(official.code, official.name);
      activities.add(
        IndustryActivity(
          corpCode: c.corpCode,
          companyName: c.name,
          market: c.market!.name,
          industryCode: c.industryCode,
          industryKey: category.$1,
          industryName: category.$2,
          role:
              'ksic:${canonicalGroups[(category.$1, groupName)] ?? group?.code ?? 'unknown'}',
          groupName: groupName,
          productKey: 'ksic:${official?.code ?? 'unknown'}',
          productName: label,
          process: '',
          classificationBasis: official == null ? 'unclassified' : 'ksic',
          evidence: official == null
              ? '등록 업종을 현재 분류표와 연결하지 못했습니다. 기업명으로 사업을 추정하지 않았습니다.'
              : 'DART 기업개황 등록 업종 · ${revision.revision} ${official.code} ${official.name}. 제품·사업 매출 및 직접 경쟁 관계를 확인한 분류는 아닙니다.',
          bsnsYear: 0,
          rceptNo: '',
        ),
      );
    }
    activities.sort((a, b) => a.companyName.compareTo(b.companyName));
    return semiconductor.copyWith(
      activities: DiscoveryCoverage.complete(
        DiscoveryResolution.resolve(activities),
      ),
      listedCompanyCount: companies.length,
      classifiedCompanyCount: activities
          .where((a) => a.classificationBasis != 'unclassified')
          .map((a) => a.corpCode)
          .toSet()
          .length,
      ruleVersion: 12,
    );
  }
}
