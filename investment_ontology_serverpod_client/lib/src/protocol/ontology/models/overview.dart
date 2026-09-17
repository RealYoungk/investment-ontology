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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/facet_count.dart' as _icav4sge;
import '../../ontology/models/industry_revision_check.dart' as _ixu13ifg;
import '../../ontology/models/ingest_job.dart' as _iwr40u3f;

abstract class Overview
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Overview._({
    required this.totalListed,
    required this.byMarket,
    required this.bySection,
    this.lastJob,
    this.lastFullRefreshAt,
    this.nextFullRefreshAt,
    this.industryRevision,
  });

  factory Overview({
    required int totalListed,
    required List<_icav4sge.FacetCount> byMarket,
    required List<_icav4sge.FacetCount> bySection,
    _iwr40u3f.IngestJob? lastJob,
    DateTime? lastFullRefreshAt,
    DateTime? nextFullRefreshAt,
    _ixu13ifg.IndustryRevisionCheck? industryRevision,
  }) = _OverviewImpl;

  factory Overview.fromJson(Map<String, dynamic> jsonSerialization) {
    return Overview(
      totalListed: jsonSerialization['totalListed'] as int,
      byMarket: _ilkzeueu.Protocol().deserialize<List<_icav4sge.FacetCount>>(
        jsonSerialization['byMarket'],
      ),
      bySection: _ilkzeueu.Protocol().deserialize<List<_icav4sge.FacetCount>>(
        jsonSerialization['bySection'],
      ),
      lastJob: jsonSerialization['lastJob'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_iwr40u3f.IngestJob>(
              jsonSerialization['lastJob'],
            ),
      lastFullRefreshAt: jsonSerialization['lastFullRefreshAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastFullRefreshAt'],
            ),
      nextFullRefreshAt: jsonSerialization['nextFullRefreshAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextFullRefreshAt'],
            ),
      industryRevision: jsonSerialization['industryRevision'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_ixu13ifg.IndustryRevisionCheck>(
              jsonSerialization['industryRevision'],
            ),
    );
  }

  int totalListed;

  List<_icav4sge.FacetCount> byMarket;

  List<_icav4sge.FacetCount> bySection;

  _iwr40u3f.IngestJob? lastJob;

  /// 마지막으로 성공한 전체 갱신 시각
  DateTime? lastFullRefreshAt;

  /// 이 시각 이후 첫 수집은 자동으로 전체 갱신
  DateTime? nextFullRefreshAt;

  /// 업종명 표시에 쓰는 KSIC 차수 판정
  _ixu13ifg.IndustryRevisionCheck? industryRevision;

  /// Returns a shallow copy of this [Overview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Overview copyWith({
    int? totalListed,
    List<_icav4sge.FacetCount>? byMarket,
    List<_icav4sge.FacetCount>? bySection,
    _iwr40u3f.IngestJob? lastJob,
    DateTime? lastFullRefreshAt,
    DateTime? nextFullRefreshAt,
    _ixu13ifg.IndustryRevisionCheck? industryRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Overview',
      'totalListed': totalListed,
      'byMarket': byMarket.toJson(valueToJson: (v) => v.toJson()),
      'bySection': bySection.toJson(valueToJson: (v) => v.toJson()),
      if (lastJob != null) 'lastJob': lastJob?.toJson(),
      if (lastFullRefreshAt != null)
        'lastFullRefreshAt': lastFullRefreshAt?.toJson(),
      if (nextFullRefreshAt != null)
        'nextFullRefreshAt': nextFullRefreshAt?.toJson(),
      if (industryRevision != null)
        'industryRevision': industryRevision?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Overview',
      'totalListed': totalListed,
      'byMarket': byMarket.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'bySection': bySection.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (lastJob != null) 'lastJob': lastJob?.toJsonForProtocol(),
      if (lastFullRefreshAt != null)
        'lastFullRefreshAt': lastFullRefreshAt?.toJson(),
      if (nextFullRefreshAt != null)
        'nextFullRefreshAt': nextFullRefreshAt?.toJson(),
      if (industryRevision != null)
        'industryRevision': industryRevision?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OverviewImpl extends Overview {
  _OverviewImpl({
    required int totalListed,
    required List<_icav4sge.FacetCount> byMarket,
    required List<_icav4sge.FacetCount> bySection,
    _iwr40u3f.IngestJob? lastJob,
    DateTime? lastFullRefreshAt,
    DateTime? nextFullRefreshAt,
    _ixu13ifg.IndustryRevisionCheck? industryRevision,
  }) : super._(
         totalListed: totalListed,
         byMarket: byMarket,
         bySection: bySection,
         lastJob: lastJob,
         lastFullRefreshAt: lastFullRefreshAt,
         nextFullRefreshAt: nextFullRefreshAt,
         industryRevision: industryRevision,
       );

  /// Returns a shallow copy of this [Overview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Overview copyWith({
    int? totalListed,
    List<_icav4sge.FacetCount>? byMarket,
    List<_icav4sge.FacetCount>? bySection,
    Object? lastJob = _Undefined,
    Object? lastFullRefreshAt = _Undefined,
    Object? nextFullRefreshAt = _Undefined,
    Object? industryRevision = _Undefined,
  }) {
    return Overview(
      totalListed: totalListed ?? this.totalListed,
      byMarket: byMarket ?? this.byMarket.map((e0) => e0.copyWith()).toList(),
      bySection:
          bySection ?? this.bySection.map((e0) => e0.copyWith()).toList(),
      lastJob: lastJob is _iwr40u3f.IngestJob?
          ? lastJob
          : this.lastJob?.copyWith(),
      lastFullRefreshAt: lastFullRefreshAt is DateTime?
          ? lastFullRefreshAt
          : this.lastFullRefreshAt,
      nextFullRefreshAt: nextFullRefreshAt is DateTime?
          ? nextFullRefreshAt
          : this.nextFullRefreshAt,
      industryRevision: industryRevision is _ixu13ifg.IndustryRevisionCheck?
          ? industryRevision
          : this.industryRevision?.copyWith(),
    );
  }
}
