import 'dart:convert';
import 'dart:io';

import '../../generated/protocol.dart';
import 'discovery_taxonomy.dart';
import 'registered_offerings.dart';

/// Official issuer/fund-manager descriptions for investment vehicles that do
/// not have a normal industrial-company business document. These are separate
/// primary sources, never relabeled as DART or inferred from a corporate name.
abstract final class IssuerOfferingCatalog {
  static final rows = (jsonDecode(
    File('assets/discovery/issuer_offerings.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  static List<IndustryActivity> forCompany(Company c) => [
    for (final row in rows)
      if (row['corpCode'] == c.corpCode)
        IndustryActivity(
          corpCode: c.corpCode,
          companyName: c.name,
          market: c.market!.name,
          industryCode: c.industryCode,
          industryKey: row['industry'],
          industryName: DiscoveryTaxonomy.categories[row['industry']]!.$1,
          groupName: row['group'],
          role: RegisteredOfferings.role(row['industry'], row['group']),
          productKey: 'issuer:${c.corpCode}',
          productName: row['product'],
          process: '',
          evidence:
              '${row['sourceTitle']}\n${row['evidence']}\n원문: ${row['sourceUrl']}\n확인일: ${row['checkedAt']}',
          classificationBasis: 'issuer_source',
          bsnsYear: 0,
          rceptNo: '',
        ),
  ];
}
