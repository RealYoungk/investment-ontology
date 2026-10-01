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
    this.financialStoredFilings,
    this.financialNoDataFilings,
    this.financialFailedFilings,
    this.financialPendingFilings,
    this.bodyScopeTotal,
    this.bodyScopeStored,
    this.bodyScopePending,
    this.bodyScopeFailed,
    this.marketLatestPriceDate,
    this.marketLatestPriceSecurities,
    this.marketLatestIndexDate,
    this.marketLatestIndexCount,
    this.marketScopeStart,
    this.marketScopeThrough,
    this.marketExpectedWeekdays,
    this.marketPriceDaysStored,
    this.marketIndexDaysStored,
    this.marketHistoricalPendingDates,
    this.marketRecentUnconfirmedDates,
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
    int? financialStoredFilings,
    int? financialNoDataFilings,
    int? financialFailedFilings,
    int? financialPendingFilings,
    int? bodyScopeTotal,
    int? bodyScopeStored,
    int? bodyScopePending,
    int? bodyScopeFailed,
    DateTime? marketLatestPriceDate,
    int? marketLatestPriceSecurities,
    DateTime? marketLatestIndexDate,
    int? marketLatestIndexCount,
    DateTime? marketScopeStart,
    DateTime? marketScopeThrough,
    int? marketExpectedWeekdays,
    int? marketPriceDaysStored,
    int? marketIndexDaysStored,
    int? marketHistoricalPendingDates,
    int? marketRecentUnconfirmedDates,
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
      financialStoredFilings:
          jsonSerialization['financialStoredFilings'] as int?,
      financialNoDataFilings:
          jsonSerialization['financialNoDataFilings'] as int?,
      financialFailedFilings:
          jsonSerialization['financialFailedFilings'] as int?,
      financialPendingFilings:
          jsonSerialization['financialPendingFilings'] as int?,
      bodyScopeTotal: jsonSerialization['bodyScopeTotal'] as int?,
      bodyScopeStored: jsonSerialization['bodyScopeStored'] as int?,
      bodyScopePending: jsonSerialization['bodyScopePending'] as int?,
      bodyScopeFailed: jsonSerialization['bodyScopeFailed'] as int?,
      marketLatestPriceDate: jsonSerialization['marketLatestPriceDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['marketLatestPriceDate'],
            ),
      marketLatestPriceSecurities:
          jsonSerialization['marketLatestPriceSecurities'] as int?,
      marketLatestIndexDate: jsonSerialization['marketLatestIndexDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['marketLatestIndexDate'],
            ),
      marketLatestIndexCount:
          jsonSerialization['marketLatestIndexCount'] as int?,
      marketScopeStart: jsonSerialization['marketScopeStart'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['marketScopeStart'],
            ),
      marketScopeThrough: jsonSerialization['marketScopeThrough'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['marketScopeThrough'],
            ),
      marketExpectedWeekdays:
          jsonSerialization['marketExpectedWeekdays'] as int?,
      marketPriceDaysStored: jsonSerialization['marketPriceDaysStored'] as int?,
      marketIndexDaysStored: jsonSerialization['marketIndexDaysStored'] as int?,
      marketHistoricalPendingDates:
          jsonSerialization['marketHistoricalPendingDates'] as int?,
      marketRecentUnconfirmedDates:
          jsonSerialization['marketRecentUnconfirmedDates'] as int?,
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

  /// 최신 정기보고서와 접수번호가 일치하는 본문 확보 기업 수
  int? companiesWithLatestBusinessText;

  int companiesWithDigest;

  /// 오늘(KST) DART 호출 수와 일일 한도
  int dartCallsToday;

  int dartDailyLimit;

  int dartFinancialBudget;

  int dartDisclosurePriorityBudget;

  /// 현재 수집 범위의 저장, 자료 없음, 실패 및 시세 장부 상태. 구버전 서버는 null.
  int? financialStoredFilings;

  int? financialNoDataFilings;

  int? financialFailedFilings;

  int? financialPendingFilings;

  int? bodyScopeTotal;

  int? bodyScopeStored;

  int? bodyScopePending;

  int? bodyScopeFailed;

  DateTime? marketLatestPriceDate;

  int? marketLatestPriceSecurities;

  DateTime? marketLatestIndexDate;

  int? marketLatestIndexCount;

  DateTime? marketScopeStart;

  DateTime? marketScopeThrough;

  int? marketExpectedWeekdays;

  int? marketPriceDaysStored;

  int? marketIndexDaysStored;

  int? marketHistoricalPendingDates;

  int? marketRecentUnconfirmedDates;

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
    int? financialStoredFilings,
    int? financialNoDataFilings,
    int? financialFailedFilings,
    int? financialPendingFilings,
    int? bodyScopeTotal,
    int? bodyScopeStored,
    int? bodyScopePending,
    int? bodyScopeFailed,
    DateTime? marketLatestPriceDate,
    int? marketLatestPriceSecurities,
    DateTime? marketLatestIndexDate,
    int? marketLatestIndexCount,
    DateTime? marketScopeStart,
    DateTime? marketScopeThrough,
    int? marketExpectedWeekdays,
    int? marketPriceDaysStored,
    int? marketIndexDaysStored,
    int? marketHistoricalPendingDates,
    int? marketRecentUnconfirmedDates,
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
      if (financialStoredFilings != null)
        'financialStoredFilings': financialStoredFilings,
      if (financialNoDataFilings != null)
        'financialNoDataFilings': financialNoDataFilings,
      if (financialFailedFilings != null)
        'financialFailedFilings': financialFailedFilings,
      if (financialPendingFilings != null)
        'financialPendingFilings': financialPendingFilings,
      if (bodyScopeTotal != null) 'bodyScopeTotal': bodyScopeTotal,
      if (bodyScopeStored != null) 'bodyScopeStored': bodyScopeStored,
      if (bodyScopePending != null) 'bodyScopePending': bodyScopePending,
      if (bodyScopeFailed != null) 'bodyScopeFailed': bodyScopeFailed,
      if (marketLatestPriceDate != null)
        'marketLatestPriceDate': marketLatestPriceDate?.toJson(),
      if (marketLatestPriceSecurities != null)
        'marketLatestPriceSecurities': marketLatestPriceSecurities,
      if (marketLatestIndexDate != null)
        'marketLatestIndexDate': marketLatestIndexDate?.toJson(),
      if (marketLatestIndexCount != null)
        'marketLatestIndexCount': marketLatestIndexCount,
      if (marketScopeStart != null)
        'marketScopeStart': marketScopeStart?.toJson(),
      if (marketScopeThrough != null)
        'marketScopeThrough': marketScopeThrough?.toJson(),
      if (marketExpectedWeekdays != null)
        'marketExpectedWeekdays': marketExpectedWeekdays,
      if (marketPriceDaysStored != null)
        'marketPriceDaysStored': marketPriceDaysStored,
      if (marketIndexDaysStored != null)
        'marketIndexDaysStored': marketIndexDaysStored,
      if (marketHistoricalPendingDates != null)
        'marketHistoricalPendingDates': marketHistoricalPendingDates,
      if (marketRecentUnconfirmedDates != null)
        'marketRecentUnconfirmedDates': marketRecentUnconfirmedDates,
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
      if (financialStoredFilings != null)
        'financialStoredFilings': financialStoredFilings,
      if (financialNoDataFilings != null)
        'financialNoDataFilings': financialNoDataFilings,
      if (financialFailedFilings != null)
        'financialFailedFilings': financialFailedFilings,
      if (financialPendingFilings != null)
        'financialPendingFilings': financialPendingFilings,
      if (bodyScopeTotal != null) 'bodyScopeTotal': bodyScopeTotal,
      if (bodyScopeStored != null) 'bodyScopeStored': bodyScopeStored,
      if (bodyScopePending != null) 'bodyScopePending': bodyScopePending,
      if (bodyScopeFailed != null) 'bodyScopeFailed': bodyScopeFailed,
      if (marketLatestPriceDate != null)
        'marketLatestPriceDate': marketLatestPriceDate?.toJson(),
      if (marketLatestPriceSecurities != null)
        'marketLatestPriceSecurities': marketLatestPriceSecurities,
      if (marketLatestIndexDate != null)
        'marketLatestIndexDate': marketLatestIndexDate?.toJson(),
      if (marketLatestIndexCount != null)
        'marketLatestIndexCount': marketLatestIndexCount,
      if (marketScopeStart != null)
        'marketScopeStart': marketScopeStart?.toJson(),
      if (marketScopeThrough != null)
        'marketScopeThrough': marketScopeThrough?.toJson(),
      if (marketExpectedWeekdays != null)
        'marketExpectedWeekdays': marketExpectedWeekdays,
      if (marketPriceDaysStored != null)
        'marketPriceDaysStored': marketPriceDaysStored,
      if (marketIndexDaysStored != null)
        'marketIndexDaysStored': marketIndexDaysStored,
      if (marketHistoricalPendingDates != null)
        'marketHistoricalPendingDates': marketHistoricalPendingDates,
      if (marketRecentUnconfirmedDates != null)
        'marketRecentUnconfirmedDates': marketRecentUnconfirmedDates,
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
    int? financialStoredFilings,
    int? financialNoDataFilings,
    int? financialFailedFilings,
    int? financialPendingFilings,
    int? bodyScopeTotal,
    int? bodyScopeStored,
    int? bodyScopePending,
    int? bodyScopeFailed,
    DateTime? marketLatestPriceDate,
    int? marketLatestPriceSecurities,
    DateTime? marketLatestIndexDate,
    int? marketLatestIndexCount,
    DateTime? marketScopeStart,
    DateTime? marketScopeThrough,
    int? marketExpectedWeekdays,
    int? marketPriceDaysStored,
    int? marketIndexDaysStored,
    int? marketHistoricalPendingDates,
    int? marketRecentUnconfirmedDates,
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
         financialStoredFilings: financialStoredFilings,
         financialNoDataFilings: financialNoDataFilings,
         financialFailedFilings: financialFailedFilings,
         financialPendingFilings: financialPendingFilings,
         bodyScopeTotal: bodyScopeTotal,
         bodyScopeStored: bodyScopeStored,
         bodyScopePending: bodyScopePending,
         bodyScopeFailed: bodyScopeFailed,
         marketLatestPriceDate: marketLatestPriceDate,
         marketLatestPriceSecurities: marketLatestPriceSecurities,
         marketLatestIndexDate: marketLatestIndexDate,
         marketLatestIndexCount: marketLatestIndexCount,
         marketScopeStart: marketScopeStart,
         marketScopeThrough: marketScopeThrough,
         marketExpectedWeekdays: marketExpectedWeekdays,
         marketPriceDaysStored: marketPriceDaysStored,
         marketIndexDaysStored: marketIndexDaysStored,
         marketHistoricalPendingDates: marketHistoricalPendingDates,
         marketRecentUnconfirmedDates: marketRecentUnconfirmedDates,
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
    Object? financialStoredFilings = _Undefined,
    Object? financialNoDataFilings = _Undefined,
    Object? financialFailedFilings = _Undefined,
    Object? financialPendingFilings = _Undefined,
    Object? bodyScopeTotal = _Undefined,
    Object? bodyScopeStored = _Undefined,
    Object? bodyScopePending = _Undefined,
    Object? bodyScopeFailed = _Undefined,
    Object? marketLatestPriceDate = _Undefined,
    Object? marketLatestPriceSecurities = _Undefined,
    Object? marketLatestIndexDate = _Undefined,
    Object? marketLatestIndexCount = _Undefined,
    Object? marketScopeStart = _Undefined,
    Object? marketScopeThrough = _Undefined,
    Object? marketExpectedWeekdays = _Undefined,
    Object? marketPriceDaysStored = _Undefined,
    Object? marketIndexDaysStored = _Undefined,
    Object? marketHistoricalPendingDates = _Undefined,
    Object? marketRecentUnconfirmedDates = _Undefined,
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
      financialStoredFilings: financialStoredFilings is int?
          ? financialStoredFilings
          : this.financialStoredFilings,
      financialNoDataFilings: financialNoDataFilings is int?
          ? financialNoDataFilings
          : this.financialNoDataFilings,
      financialFailedFilings: financialFailedFilings is int?
          ? financialFailedFilings
          : this.financialFailedFilings,
      financialPendingFilings: financialPendingFilings is int?
          ? financialPendingFilings
          : this.financialPendingFilings,
      bodyScopeTotal: bodyScopeTotal is int?
          ? bodyScopeTotal
          : this.bodyScopeTotal,
      bodyScopeStored: bodyScopeStored is int?
          ? bodyScopeStored
          : this.bodyScopeStored,
      bodyScopePending: bodyScopePending is int?
          ? bodyScopePending
          : this.bodyScopePending,
      bodyScopeFailed: bodyScopeFailed is int?
          ? bodyScopeFailed
          : this.bodyScopeFailed,
      marketLatestPriceDate: marketLatestPriceDate is DateTime?
          ? marketLatestPriceDate
          : this.marketLatestPriceDate,
      marketLatestPriceSecurities: marketLatestPriceSecurities is int?
          ? marketLatestPriceSecurities
          : this.marketLatestPriceSecurities,
      marketLatestIndexDate: marketLatestIndexDate is DateTime?
          ? marketLatestIndexDate
          : this.marketLatestIndexDate,
      marketLatestIndexCount: marketLatestIndexCount is int?
          ? marketLatestIndexCount
          : this.marketLatestIndexCount,
      marketScopeStart: marketScopeStart is DateTime?
          ? marketScopeStart
          : this.marketScopeStart,
      marketScopeThrough: marketScopeThrough is DateTime?
          ? marketScopeThrough
          : this.marketScopeThrough,
      marketExpectedWeekdays: marketExpectedWeekdays is int?
          ? marketExpectedWeekdays
          : this.marketExpectedWeekdays,
      marketPriceDaysStored: marketPriceDaysStored is int?
          ? marketPriceDaysStored
          : this.marketPriceDaysStored,
      marketIndexDaysStored: marketIndexDaysStored is int?
          ? marketIndexDaysStored
          : this.marketIndexDaysStored,
      marketHistoricalPendingDates: marketHistoricalPendingDates is int?
          ? marketHistoricalPendingDates
          : this.marketHistoricalPendingDates,
      marketRecentUnconfirmedDates: marketRecentUnconfirmedDates is int?
          ? marketRecentUnconfirmedDates
          : this.marketRecentUnconfirmedDates,
    );
  }
}
