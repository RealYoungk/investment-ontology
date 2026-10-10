import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'business_activity_rules.dart';
import 'filing_offering_rules.dart';
import 'reviewed_filing_offerings.dart';
import 'registered_offerings.dart';
import 'registered_business_evidence.dart';
import 'discovery_taxonomy.dart';
import 'semiconductor_activity_rules.dart';

/// Offline builder only. Public endpoints never invoke these filing rules.
/// No source downloads or AI calls; its output is persisted by the server.
abstract final class IndustryDiscoveryCatalog {
  // Discovery includes holding-company activities, unlike peer comparison.
  static const latestSql =
      '''SELECT DISTINCT ON (d."companyId") d.id, d."companyId"
    FROM business_document d JOIN disclosure_report r ON r.id=d."reportId"
    WHERE r."supersededById" IS NULL AND r."reportCode"='annual'
    ORDER BY d."companyId", d."bsnsYear" DESC, d."rceptNo" DESC, d.id DESC''';
  static Future<DatabaseResult> sourceRows(Session session) =>
      session.db.unsafeQuery('''
        SELECT c.id, c."corpCode", c.name, c.market, c."industryCode", latest.id,
          md5(d.text), d."bsnsYear", d."rceptNo", c."stockCode"
        FROM company c LEFT JOIN ($latestSql) latest
          ON latest."companyId"=c.id
        LEFT JOIN business_document d ON d.id=latest.id
        WHERE c.market IN ('kospi','kosdaq','konex')
        ORDER BY c.id
      ''');

  static Future<({IndustryDiscovery pilot, List<IndustryActivity> business})>
  build(Session session) async {
    final rows = await sourceRows(session);
    final companies = {for (final r in rows) r[0] as int: r};
    final ids = [
      for (final r in rows)
        if (r[5] != null) r[5] as int,
    ];
    final activities = <IndustryActivity>[];
    final business = <IndustryActivity>[];
    for (var start = 0; start < ids.length; start += 50) {
      final batch = ids.skip(start).take(50).toSet();
      final docs = await BusinessDocument.db.find(
        session,
        where: (t) => t.id.inSet(batch),
      );
      for (final doc in docs) {
        // Old filings remain discoverable through official industry views,
        // but cannot establish a current product activity in this pilot.
        if (doc.bsnsYear < DateTime.now().year - 2) continue;
        final c = companies[doc.companyId]!;
        if (c[4] != '64992') {
          for (final match in BusinessActivityRules.parse(
            doc.text,
            companyName: c[2] as String,
          )) {
            final rule = match.$1;
            business.add(
              IndustryActivity(
                corpCode: c[1] as String,
                companyName: c[2] as String,
                market: c[3] as String,
                industryCode: c[4] as String?,
                industryKey: rule.industry,
                industryName: DiscoveryTaxonomy.categories[rule.industry]!.$1,
                groupName: rule.group,
                role: 'business:${rule.group}',
                productKey: rule.key,
                productName: rule.label,
                process: '',
                evidence: match.$2,
                classificationBasis: 'filing',
                bsnsYear: doc.bsnsYear,
                rceptNo: doc.rceptNo,
              ),
            );
          }
        }

        for (final (rule, evidence) in [
          ...ReviewedFilingOfferings.match(
            corpCode: c[1] as String,
            receipt: doc.rceptNo,
            year: doc.bsnsYear,
            text: doc.text,
          ),
          ...FilingOfferingRules.parse(
            doc.text,
            sector: DiscoveryTaxonomy.category(c[4] as String?).$1,
            companyName: c[2] as String,
            year: doc.bsnsYear,
          ),
        ]) {
          business.add(
            IndustryActivity(
              corpCode: c[1] as String,
              companyName: c[2] as String,
              market: c[3] as String,
              industryCode: c[4] as String?,
              industryKey: rule.$1,
              industryName: DiscoveryTaxonomy.categories[rule.$1]!.$1,
              groupName: rule.$2,
              role: RegisteredOfferings.role(rule.$1, rule.$2),
              productKey: rule.$3,
              productName: rule.$4,
              process: '',
              evidence: evidence,
              classificationBasis: 'filing',
              bsnsYear: doc.bsnsYear,
              rceptNo: doc.rceptNo,
            ),
          );
        }
        final code = c[4] as String?;
        if (code != null && code != '64992') {
          final sector = DiscoveryTaxonomy.category(code);
          final registered = RegisteredOfferings.definition(sector.$1, code);
          final evidence = RegisteredBusinessEvidence.find(
            doc.text,
            industry: sector.$1,
            code: code,
            companyName: c[2] as String,
          );
          if (registered != null &&
              evidence != null &&
              !business.any(
                (a) => a.corpCode == c[1] && a.industryKey == sector.$1,
              )) {
            final label = registered['label'] as String;
            business.add(
              IndustryActivity(
                corpCode: c[1] as String,
                companyName: c[2] as String,
                market: c[3] as String,
                industryCode: code,
                industryKey: sector.$1,
                industryName: sector.$2,
                groupName: label,
                role: RegisteredOfferings.role(sector.$1, label),
                productKey: 'activity:$code',
                productName: label,
                process: '',
                evidence: evidence,
                classificationBasis: 'filing_activity',
                bsnsYear: doc.bsnsYear,
                rceptNo: doc.rceptNo,
              ),
            );
          }
        }

        if (c[4] != '64992') {
          for (final a in SemiconductorActivityRules.parse(
            doc.text,
            companyName: c[2] as String,
          )) {
            activities.add(
              IndustryActivity(
                corpCode: c[1] as String,
                companyName: c[2] as String,
                market: c[3] as String,
                industryCode: c[4] as String?,
                productKey: a.product.id,
                productName: a.product.label,
                role: a.product.role,
                process: a.product.process,
                target: a.product.target,
                method: a.product.method,
                evidence: a.evidence,
                bsnsYear: doc.bsnsYear,
                rceptNo: doc.rceptNo,
              ),
            );
          }
        }
      }
    }
    activities.sort((a, b) => a.companyName.compareTo(b.companyName));
    return (
      business: business,
      pilot: IndustryDiscovery(
        activities: activities,
        listedCompanyCount: rows.length,
        documentCompanyCount: ids.length,
        classifiedCompanyCount: activities
            .map((a) => a.corpCode)
            .toSet()
            .length,
        ruleVersion: SemiconductorActivityRules.version,
        computedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
