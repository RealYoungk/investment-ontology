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
import '../../ontology/models/dart_section.dart' as _iy0bhrwp;
import '../../ontology/models/filing_fetch_status.dart' as _iy9345ub;

/// 수집 장부: 정기보고서(DartFiling) 한 건 × 주요정보 항목 하나의 수집 상태.
/// 항목이 늘어도 스키마를 바꾸지 않도록 항목마다 행으로 둔다.
abstract class DartFilingSection
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DartFilingSection._({
    this.id,
    required this.filingId,
    required this.companyId,
    required this.bsnsYear,
    int? yearRank,
    required this.section,
    required this.tier,
    required this.status,
    int? attempts,
    this.lastError,
    this.fetchedAt,
  }) : yearRank = yearRank ?? 0,
       attempts = attempts ?? 0;

  factory DartFilingSection({
    int? id,
    required int filingId,
    required int companyId,
    required int bsnsYear,
    int? yearRank,
    required _iy0bhrwp.DartSection section,
    required int tier,
    required _iy9345ub.FilingFetchStatus status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  }) = _DartFilingSectionImpl;

  factory DartFilingSection.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFilingSection(
      id: jsonSerialization['id'] as int?,
      filingId: jsonSerialization['filingId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      yearRank: jsonSerialization['yearRank'] as int?,
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      tier: jsonSerialization['tier'] as int,
      status: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      attempts: jsonSerialization['attempts'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      fetchedAt: jsonSerialization['fetchedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['fetchedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int filingId;

  int companyId;

  int bsnsYear;

  /// 이 기업의 사업보고서 가운데 몇 번째로 최근인지 (0 = 가장 최근). 결산월이 달라 전체 최신 연도는 기업마다 다르다
  int yearRank;

  _iy0bhrwp.DartSection section;

  /// 받는 순서. 0 = 핵심 (지배구조·주주환원), 1 = 나머지
  int tier;

  _iy9345ub.FilingFetchStatus status;

  /// 실패한 실행 수
  int attempts;

  String? lastError;

  DateTime? fetchedAt;

  /// Returns a shallow copy of this [DartFilingSection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DartFilingSection copyWith({
    int? id,
    int? filingId,
    int? companyId,
    int? bsnsYear,
    int? yearRank,
    _iy0bhrwp.DartSection? section,
    int? tier,
    _iy9345ub.FilingFetchStatus? status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFilingSection',
      if (id != null) 'id': id,
      'filingId': filingId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'yearRank': yearRank,
      'section': section.toJson(),
      'tier': tier,
      'status': status.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      if (fetchedAt != null) 'fetchedAt': fetchedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFilingSection',
      if (id != null) 'id': id,
      'filingId': filingId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'yearRank': yearRank,
      'section': section.toJson(),
      'tier': tier,
      'status': status.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      if (fetchedAt != null) 'fetchedAt': fetchedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingSectionImpl extends DartFilingSection {
  _DartFilingSectionImpl({
    int? id,
    required int filingId,
    required int companyId,
    required int bsnsYear,
    int? yearRank,
    required _iy0bhrwp.DartSection section,
    required int tier,
    required _iy9345ub.FilingFetchStatus status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  }) : super._(
         id: id,
         filingId: filingId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         yearRank: yearRank,
         section: section,
         tier: tier,
         status: status,
         attempts: attempts,
         lastError: lastError,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [DartFilingSection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DartFilingSection copyWith({
    Object? id = _Undefined,
    int? filingId,
    int? companyId,
    int? bsnsYear,
    int? yearRank,
    _iy0bhrwp.DartSection? section,
    int? tier,
    _iy9345ub.FilingFetchStatus? status,
    int? attempts,
    Object? lastError = _Undefined,
    Object? fetchedAt = _Undefined,
  }) {
    return DartFilingSection(
      id: id is int? ? id : this.id,
      filingId: filingId ?? this.filingId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      yearRank: yearRank ?? this.yearRank,
      section: section ?? this.section,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError is String? ? lastError : this.lastError,
      fetchedAt: fetchedAt is DateTime? ? fetchedAt : this.fetchedAt,
    );
  }
}
