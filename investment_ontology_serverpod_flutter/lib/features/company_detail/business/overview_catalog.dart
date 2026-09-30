import 'dart:convert';

import 'package:flutter/services.dart';

/// Versioned, offline explanations. Market/financial numbers still come from API.
/// General business-model lessons are deliberately distinct from issuer theses.
class OverviewModel {
  OverviewModel.fromJson(Map<String, dynamic> json)
    : label = json['label'] as String,
      title = json['title'] as String,
      description = json['description'] as String,
      driver = json['driver'] as String,
      thesis = json['thesis'] as String,
      terms = json['terms'] as String,
      flow = (json['flow'] as List)
          .map(
            (e) => (
              title: e['title'] as String,
              body: e['body'] as String,
            ),
          )
          .toList(growable: false);
  final String label, title, description, driver, thesis, terms;
  final List<({String title, String body})> flow;
}

class CompanyOverviewLesson {
  const CompanyOverviewLesson({
    required this.summary,
    required this.products,
    required this.models,
    required this.hasDocument,
    required this.year,
  });
  final String summary;
  final List<String> products;
  final List<OverviewModel> models;
  final bool hasDocument;
  final int? year;
}

class OverviewCatalog {
  OverviewCatalog.fromJson(Map<String, dynamic> json)
    : _companies = json['companies'] as Map<String, dynamic>,
      _models = (json['models'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          OverviewModel.fromJson(value as Map<String, dynamic>),
        ),
      );
  final Map<String, dynamic> _companies;
  final Map<String, OverviewModel> _models;
  static Future<OverviewCatalog>? _loading;
  static Future<OverviewCatalog> load() => _loading ??= _load();
  static Future<OverviewCatalog> _load() async {
    try {
      return OverviewCatalog.fromJson(
        jsonDecode(
          await rootBundle.loadString('assets/overview/companies.json'),
        ) as Map<String, dynamic>,
      );
    } catch (_) {
      _loading = null; // A temporary asset failure must remain retryable.
      rethrow;
    }
  }

  CompanyOverviewLesson? forCompany(String corpCode) {
    final json = _companies[corpCode] as Map<String, dynamic>?;
    if (json == null) return null;
    final models = (json['models'] as List)
        .map((key) => _models[key])
        .whereType<OverviewModel>()
        .toList(growable: false);
    if (models.isEmpty) return null;
    return CompanyOverviewLesson(
      summary: json['summary'] as String,
      products: (json['products'] as List)
          .map((p) => p['name'] as String)
          .toList(growable: false),
      models: models,
      hasDocument: json['hasDocument'] as bool,
      year: json['year'] as int?,
    );
  }
}
