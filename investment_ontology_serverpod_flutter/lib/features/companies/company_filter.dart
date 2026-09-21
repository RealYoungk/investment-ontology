import 'package:flutter/foundation.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// 기업 목록의 검색·필터·정렬·페이지. 주소의 검색어(`?market=kospi&section=C`)와 오간다.
@immutable
class CompanyFilter {
  const CompanyFilter({
    this.market,
    this.section,
    this.division,
    this.query = '',
    this.sort = CompanySort.marketCap,
    this.page = 1,
  });

  final Market? market;

  /// KSIC 대분류 코드 (예: C 제조업).
  final String? section;

  /// KSIC 중분류 코드 (예: 26). [section] 안에서만 쓴다.
  final String? division;
  final String query;
  final CompanySort sort;

  /// 1부터.
  final int page;

  bool get hasFilter =>
      market != null || section != null || division != null || query.isNotEmpty;

  factory CompanyFilter.fromQuery(Map<String, String> q) {
    final section = _text(q['section']);
    return CompanyFilter(
      market: Market.values.asNameMap()[q['market']],
      section: section,
      division: section == null ? null : _text(q['division']),
      query: q['q']?.trim() ?? '',
      sort: CompanySort.values.asNameMap()[q['sort']] ?? CompanySort.marketCap,
      page: (int.tryParse(q['page'] ?? '') ?? 1).clamp(1, 1 << 20),
    );
  }

  Map<String, String> toQuery() => {
    if (market != null) 'market': market!.name,
    'section': ?section,
    'division': ?division,
    if (query.isNotEmpty) 'q': query,
    if (sort != CompanySort.marketCap) 'sort': sort.name,
    if (page > 1) 'page': '$page',
  };

  String get location {
    final q = toQuery();
    return Uri(
      path: '/companies',
      queryParameters: q.isEmpty ? null : q,
    ).toString();
  }

  /// 필터를 바꾸면 첫 페이지부터 본다. 대분류가 바뀌면 중분류는 풀린다.
  CompanyFilter copyWith({
    ValueGetter<Market?>? market,
    ValueGetter<String?>? section,
    ValueGetter<String?>? division,
    String? query,
    CompanySort? sort,
    int? page,
  }) {
    final nextSection = section == null ? this.section : section();
    return CompanyFilter(
      market: market == null ? this.market : market(),
      section: nextSection,
      division: division != null
          ? division()
          : (nextSection == this.section ? this.division : null),
      query: query ?? this.query,
      sort: sort ?? this.sort,
      page: page ?? 1,
    );
  }

  static String? _text(String? v) =>
      v == null || v.trim().isEmpty ? null : v.trim();

  @override
  bool operator ==(Object other) =>
      other is CompanyFilter &&
      other.market == market &&
      other.section == section &&
      other.division == division &&
      other.query == query &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(market, section, division, query, sort, page);
}
