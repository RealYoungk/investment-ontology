import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'latest_business_report.dart';
import 'business_product_rules.dart';

abstract final class BusinessProfiles {
  static Future<void> store(Session session, BusinessDocument doc) async {
    final products = BusinessProductRules.parse(doc.text);
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT id FROM business_document WHERE id=@id FOR UPDATE',
        parameters: QueryParameters.named({'id': doc.id!}),
        transaction: tx,
      );
      final old = await BusinessProfile.db.findFirstRow(
        session,
        where: (t) => t.documentId.equals(doc.id!),
        transaction: tx,
      );
      final profile = BusinessProfile(
        id: old?.id,
        documentId: doc.id!,
        ruleVersion: BusinessProductRules.version,
        products: products,
        computedAt: DateTime.now().toUtc(),
      );
      if (old == null) {
        await BusinessProfile.db.insertRow(session, profile, transaction: tx);
      } else {
        await BusinessProfile.db.updateRow(session, profile, transaction: tx);
      }
    });
  }

  static Future<int> backfill(Session session) async {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT latest."documentId" FROM (${LatestBusinessReport.sql}) latest
      JOIN company c ON c.id=latest."companyId"
      LEFT JOIN business_profile p ON p."documentId"=latest."documentId"
      WHERE latest."documentId" IS NOT NULL
        AND (c."industryCode" IS NULL OR c."industryCode" <> '64992')
        AND (p.id IS NULL OR p."ruleVersion" <> @version)
    ''',
      parameters: QueryParameters.named({
        'version': BusinessProductRules.version,
      }),
    );
    for (final row in rows) {
      final doc = await BusinessDocument.db.findById(session, row[0] as int);
      if (doc != null) await store(session, doc);
    }
    return rows.length;
  }

  /// Read stored results only. No extraction, external calls or writes here.
  static Future<BusinessUnderstanding> read(
    Session session,
    String corpCode,
  ) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw ArgumentError('기업 코드 형식 오류');
    }
    final rows = await session.db.unsafeQuery('''
      SELECT latest."bsnsYear", coalesce(latest."sourceReceipt", latest."rceptNo"), p.products, p."ruleVersion", p."computedAt", latest."reportCode", latest."reportName"
      FROM (${LatestBusinessReport.sql}) latest
      JOIN company c ON c.id=latest."companyId"
      LEFT JOIN business_profile p ON p."documentId"=latest."documentId"
      WHERE c."corpCode"=@code
        AND (c."industryCode" IS NULL OR c."industryCode" <> '64992')
    ''', parameters: QueryParameters.named({'code': corpCode}));
    final row = rows.firstOrNull;
    final stale = row != null && (row[0] as int) < DateTime.now().year - 2;
    final ready =
        row != null && row[3] == BusinessProductRules.version && !stale;
    final products = ready
        ? (row[2] as List)
              .map(
                (p) => BusinessProduct.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ),
              )
              .toList()
        : <BusinessProduct>[];
    return BusinessUnderstanding(
      status: row == null
          ? 'no_document'
          : stale
          ? 'stale'
          : !ready
          ? 'pending'
          : products.isEmpty
          ? 'unsupported'
          : 'ready',
      products: products,
      bsnsYear: row?[0] as int?,
      rceptNo: row?[1] as String?,
      computedAt: row?[4] as DateTime?,
      ruleVersion: BusinessProductRules.version,
      reportCode: row == null
          ? null
          : FinancialReportCode.values.byName(row[5] as String),
      reportName: row?[6] as String?,
    );
  }
}
