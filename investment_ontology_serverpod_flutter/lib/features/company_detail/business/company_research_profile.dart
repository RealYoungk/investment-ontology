import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import 'company_development.dart';

/// Issuer-specific explanations, prepared from an annual report plus an interim
/// update. Keep evidence and coverage with the text; never derive a thesis from
/// an industry template or run AI when opening a page.
class CompanyResearchProfile {
  CompanyResearchProfile.fromJson(Map<String, dynamic> json)
    : operatingFocus = (json['operatingFocus'] as List? ?? const [])
          .cast<String>(),
      summary = json['summary'] as String,
      diagram = json['diagram'] as String?,
      products = (json['products'] as List)
          .map(
            (p) => (
              name: p['name'] as String,
              body: p['body'] as String,
              use: p['use'] as String,
            ),
          )
          .toList(),
      segments = (json['segments'] as List)
          .map(
            (p) => (
              name: p['name'] as String,
              body: p['body'] as String,
            ),
          )
          .toList(),
      sources = (json['sources'] as List).cast<Map<String, dynamic>>(),
      coveredYear = json['coveredYear'] as int,
      coveredPeriod = json['coveredPeriod'] as String,
      coveredReceipt = json['coveredReceipt'] as String,
      checkedAt = DateTime.parse(json['checkedAt'] as String),
      development = CompanyDevelopment(
        headline: json['focus']['headline'] as String,
        change: json['focus']['change'] as String,
        contextTitle: json['focus']['contextTitle'] as String,
        roleTitle: json['focus']['roleTitle'] as String,
        role: json['focus']['role'] as String,
        contextSteps: (json['focus']['steps'] as List)
            .map(
              (s) => (
                title: s['title'] as String,
                body: s['body'] as String,
              ),
            )
            .toList(),
        sourceLabel: json['coveredPeriod'] as String,
        sourceUrl:
            (json['sources'] as List).firstWhere(
                  (s) => s['kind'] == 'interim',
                )['url']
                as String,
      );

  final List<String> operatingFocus;
  final String summary;
  final String? diagram;
  final List<({String name, String body, String use})> products;
  final List<({String name, String body})> segments;
  final List<Map<String, dynamic>> sources;
  final int coveredYear;
  final String coveredPeriod, coveredReceipt;
  final DateTime checkedAt;
  final CompanyDevelopment development;

  /// A later filing or correction must not inherit the old 'current' thesis.
  bool covers(FinancialPeriod? latest) {
    if (latest == null) return false;
    const rank = {'q1': 1, 'halfYear': 2, 'q3': 3, 'annual': 4};
    if (latest.bsnsYear != coveredYear) return latest.bsnsYear < coveredYear;
    final actualRank = rank[latest.reportCode.name]!;
    final coveredRank = rank[coveredPeriod]!;
    if (actualRank != coveredRank) return actualRank < coveredRank;
    return latest.rceptNo == coveredReceipt;
  }
}
