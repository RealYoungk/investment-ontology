/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// 수집 현황: 층마다 얼마나 받았는지와 오늘 DART 호출 수.
abstract class IngestCoverage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  IngestCoverage._({
    required this.listedCompanies,
    required this.companiesWithFinancials,
    required this.filingsTotal,
    required this.filingsPending,
    required this.prioritySections,
    required this.prioritySectionsDone,
    required this.sections,
    required this.sectionsDone,
    required this.sectionsFailed,
    required this.companiesWithDisclosures,
    required this.relations,
    required this.persons,
    required this.companiesWithBusinessText,
    this.companiesWithLatestBusinessText,
    required this.companiesWithDigest,
    required this.dartCallsToday,
    required this.dartDailyLimit,
    required this.dartFinancialBudget,
    required this.dartDisclosurePriorityBudget,
  });

  factory IngestCoverage({
    required int listedCompanies,
    required int companiesWithFinancials,
    required int filingsTotal,
    required int filingsPending,
    required int prioritySections,
    required int prioritySectionsDone,
    required int sections,
    required int sectionsDone,
    required int sectionsFailed,
    required int companiesWithDisclosures,
    required int relations,
    required int persons,
    required int companiesWithBusinessText,
    int? companiesWithLatestBusinessText,
    required int companiesWithDigest,
    required int dartCallsToday,
    required int dartDailyLimit,
    required int dartFinancialBudget,
    required int dartDisclosurePriorityBudget,
  }) = _IngestCoverageImpl;

  factory IngestCoverage.fromJson(Map<String, dynamic> jsonSerialization) {
    return IngestCoverage(
      listedCompanies: jsonSerialization['listedCompanies'] as int,
      companiesWithFinancials:
          jsonSerialization['companiesWithFinancials'] as int,
      filingsTotal: jsonSerialization['filingsTotal'] as int,
      filingsPending: jsonSerialization['filingsPending'] as int,
      prioritySections: jsonSerialization['prioritySections'] as int,
      prioritySectionsDone: jsonSerialization['prioritySectionsDone'] as int,
      sections: jsonSerialization['sections'] as int,
      sectionsDone: jsonSerialization['sectionsDone'] as int,
      sectionsFailed: jsonSerialization['sectionsFailed'] as int,
      companiesWithDisclosures:
          jsonSerialization['companiesWithDisclosures'] as int,
      relations: jsonSerialization['relations'] as int,
      persons: jsonSerialization['persons'] as int,
      companiesWithBusinessText:
          jsonSerialization['companiesWithBusinessText'] as int,
      companiesWithLatestBusinessText:
          jsonSerialization['companiesWithLatestBusinessText'] as int?,
      companiesWithDigest: jsonSerialization['companiesWithDigest'] as int,
      dartCallsToday: jsonSerialization['dartCallsToday'] as int,
      dartDailyLimit: jsonSerialization['dartDailyLimit'] as int,
      dartFinancialBudget: jsonSerialization['dartFinancialBudget'] as int,
      dartDisclosurePriorityBudget:
          jsonSerialization['dartDisclosurePriorityBudget'] as int,
    );
  }

  /// 상장사 수
  int listedCompanies;

  /// 재무제표가 하나라도 있는 상장사 수
  int companiesWithFinancials;

  /// 찾은 정기보고서 수와 그중 아직 받지 않은 수 (연결·별도 중 하나라도 대기)
  int filingsTotal;

  int filingsPending;

  /// 우선 범위(기업별 최신 사업보고서의 핵심 항목) 주요정보 섹션 수와 끝난 수
  int prioritySections;

  int prioritySectionsDone;

  /// 전체 주요정보 섹션 수, 끝난 수, 실패 수
  int sections;

  int sectionsDone;

  int sectionsFailed;

  /// 주요정보 원문이 하나라도 있는 상장사 수
  int companiesWithDisclosures;

  /// 온톨로지 관계 수와 사람 수 (추정 연결 포함)
  int relations;

  int persons;

  /// "사업의 내용" 본문이 있는 상장사 수와, 그중 절별 요약(BusinessDigestSection)까지 있는 수
  int companiesWithBusinessText;

  /// 최신 정기보고서 본문 확보 기업 수 (첨부정정 원본 포함)
  int? companiesWithLatestBusinessText;

  int companiesWithDigest;

  /// 오늘(KST) DART 호출 수와 일일 한도
  int dartCallsToday;

  int dartDailyLimit;

  int dartFinancialBudget;

  int dartDisclosurePriorityBudget;

  /// Returns a shallow copy of this [IngestCoverage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IngestCoverage copyWith({
    int? listedCompanies,
    int? companiesWithFinancials,
    int? filingsTotal,
    int? filingsPending,
    int? prioritySections,
    int? prioritySectionsDone,
    int? sections,
    int? sectionsDone,
    int? sectionsFailed,
    int? companiesWithDisclosures,
    int? relations,
    int? persons,
    int? companiesWithBusinessText,
    int? companiesWithLatestBusinessText,
    int? companiesWithDigest,
    int? dartCallsToday,
    int? dartDailyLimit,
    int? dartFinancialBudget,
    int? dartDisclosurePriorityBudget,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IngestCoverage',
      'listedCompanies': listedCompanies,
      'companiesWithFinancials': companiesWithFinancials,
      'filingsTotal': filingsTotal,
      'filingsPending': filingsPending,
      'prioritySections': prioritySections,
      'prioritySectionsDone': prioritySectionsDone,
      'sections': sections,
      'sectionsDone': sectionsDone,
      'sectionsFailed': sectionsFailed,
      'companiesWithDisclosures': companiesWithDisclosures,
      'relations': relations,
      'persons': persons,
      'companiesWithBusinessText': companiesWithBusinessText,
      if (companiesWithLatestBusinessText != null)
        'companiesWithLatestBusinessText': companiesWithLatestBusinessText,
      'companiesWithDigest': companiesWithDigest,
      'dartCallsToday': dartCallsToday,
      'dartDailyLimit': dartDailyLimit,
      'dartFinancialBudget': dartFinancialBudget,
      'dartDisclosurePriorityBudget': dartDisclosurePriorityBudget,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IngestCoverage',
      'listedCompanies': listedCompanies,
      'companiesWithFinancials': companiesWithFinancials,
      'filingsTotal': filingsTotal,
      'filingsPending': filingsPending,
      'prioritySections': prioritySections,
      'prioritySectionsDone': prioritySectionsDone,
      'sections': sections,
      'sectionsDone': sectionsDone,
      'sectionsFailed': sectionsFailed,
      'companiesWithDisclosures': companiesWithDisclosures,
      'relations': relations,
      'persons': persons,
      'companiesWithBusinessText': companiesWithBusinessText,
      if (companiesWithLatestBusinessText != null)
        'companiesWithLatestBusinessText': companiesWithLatestBusinessText,
      'companiesWithDigest': companiesWithDigest,
      'dartCallsToday': dartCallsToday,
      'dartDailyLimit': dartDailyLimit,
      'dartFinancialBudget': dartFinancialBudget,
      'dartDisclosurePriorityBudget': dartDisclosurePriorityBudget,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IngestCoverageImpl extends IngestCoverage {
  _IngestCoverageImpl({
    required int listedCompanies,
    required int companiesWithFinancials,
    required int filingsTotal,
    required int filingsPending,
    required int prioritySections,
    required int prioritySectionsDone,
    required int sections,
    required int sectionsDone,
    required int sectionsFailed,
    required int companiesWithDisclosures,
    required int relations,
    required int persons,
    required int companiesWithBusinessText,
    int? companiesWithLatestBusinessText,
    required int companiesWithDigest,
    required int dartCallsToday,
    required int dartDailyLimit,
    required int dartFinancialBudget,
    required int dartDisclosurePriorityBudget,
  }) : super._(
         listedCompanies: listedCompanies,
         companiesWithFinancials: companiesWithFinancials,
         filingsTotal: filingsTotal,
         filingsPending: filingsPending,
         prioritySections: prioritySections,
         prioritySectionsDone: prioritySectionsDone,
         sections: sections,
         sectionsDone: sectionsDone,
         sectionsFailed: sectionsFailed,
         companiesWithDisclosures: companiesWithDisclosures,
         relations: relations,
         persons: persons,
         companiesWithBusinessText: companiesWithBusinessText,
         companiesWithLatestBusinessText: companiesWithLatestBusinessText,
         companiesWithDigest: companiesWithDigest,
         dartCallsToday: dartCallsToday,
         dartDailyLimit: dartDailyLimit,
         dartFinancialBudget: dartFinancialBudget,
         dartDisclosurePriorityBudget: dartDisclosurePriorityBudget,
       );

  /// Returns a shallow copy of this [IngestCoverage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IngestCoverage copyWith({
    int? listedCompanies,
    int? companiesWithFinancials,
    int? filingsTotal,
    int? filingsPending,
    int? prioritySections,
    int? prioritySectionsDone,
    int? sections,
    int? sectionsDone,
    int? sectionsFailed,
    int? companiesWithDisclosures,
    int? relations,
    int? persons,
    int? companiesWithBusinessText,
    Object? companiesWithLatestBusinessText = _Undefined,
    int? companiesWithDigest,
    int? dartCallsToday,
    int? dartDailyLimit,
    int? dartFinancialBudget,
    int? dartDisclosurePriorityBudget,
  }) {
    return IngestCoverage(
      listedCompanies: listedCompanies ?? this.listedCompanies,
      companiesWithFinancials:
          companiesWithFinancials ?? this.companiesWithFinancials,
      filingsTotal: filingsTotal ?? this.filingsTotal,
      filingsPending: filingsPending ?? this.filingsPending,
      prioritySections: prioritySections ?? this.prioritySections,
      prioritySectionsDone: prioritySectionsDone ?? this.prioritySectionsDone,
      sections: sections ?? this.sections,
      sectionsDone: sectionsDone ?? this.sectionsDone,
      sectionsFailed: sectionsFailed ?? this.sectionsFailed,
      companiesWithDisclosures:
          companiesWithDisclosures ?? this.companiesWithDisclosures,
      relations: relations ?? this.relations,
      persons: persons ?? this.persons,
      companiesWithBusinessText:
          companiesWithBusinessText ?? this.companiesWithBusinessText,
      companiesWithLatestBusinessText: companiesWithLatestBusinessText is int?
          ? companiesWithLatestBusinessText
          : this.companiesWithLatestBusinessText,
      companiesWithDigest: companiesWithDigest ?? this.companiesWithDigest,
      dartCallsToday: dartCallsToday ?? this.dartCallsToday,
      dartDailyLimit: dartDailyLimit ?? this.dartDailyLimit,
      dartFinancialBudget: dartFinancialBudget ?? this.dartFinancialBudget,
      dartDisclosurePriorityBudget:
          dartDisclosurePriorityBudget ?? this.dartDisclosurePriorityBudget,
    );
  }
}
