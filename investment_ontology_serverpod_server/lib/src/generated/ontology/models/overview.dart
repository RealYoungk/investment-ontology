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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/facet_count.dart' as _icav4sge;
import '../../ontology/models/ingest_job.dart' as _iwr40u3f;

abstract class Overview
    implements _is.SerializableModel, _is.ProtocolSerialization {
  Overview._({
    required this.totalListed,
    required this.byMarket,
    required this.bySection,
    this.lastJob,
  });

  factory Overview({
    required int totalListed,
    required List<_icav4sge.FacetCount> byMarket,
    required List<_icav4sge.FacetCount> bySection,
    _iwr40u3f.IngestJob? lastJob,
  }) = _OverviewImpl;

  factory Overview.fromJson(Map<String, dynamic> jsonSerialization) {
    return Overview(
      totalListed: jsonSerialization['totalListed'] as int,
      byMarket: _i4yshtjp.Protocol().deserialize<List<_icav4sge.FacetCount>>(
        jsonSerialization['byMarket'],
      ),
      bySection: _i4yshtjp.Protocol().deserialize<List<_icav4sge.FacetCount>>(
        jsonSerialization['bySection'],
      ),
      lastJob: jsonSerialization['lastJob'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_iwr40u3f.IngestJob>(
              jsonSerialization['lastJob'],
            ),
    );
  }

  int totalListed;

  List<_icav4sge.FacetCount> byMarket;

  List<_icav4sge.FacetCount> bySection;

  _iwr40u3f.IngestJob? lastJob;

  /// Returns a shallow copy of this [Overview]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Overview copyWith({
    int? totalListed,
    List<_icav4sge.FacetCount>? byMarket,
    List<_icav4sge.FacetCount>? bySection,
    _iwr40u3f.IngestJob? lastJob,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Overview',
      'totalListed': totalListed,
      'byMarket': byMarket.toJson(valueToJson: (v) => v.toJson()),
      'bySection': bySection.toJson(valueToJson: (v) => v.toJson()),
      if (lastJob != null) 'lastJob': lastJob?.toJson(),
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
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OverviewImpl extends Overview {
  _OverviewImpl({
    required int totalListed,
    required List<_icav4sge.FacetCount> byMarket,
    required List<_icav4sge.FacetCount> bySection,
    _iwr40u3f.IngestJob? lastJob,
  }) : super._(
         totalListed: totalListed,
         byMarket: byMarket,
         bySection: bySection,
         lastJob: lastJob,
       );

  /// Returns a shallow copy of this [Overview]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Overview copyWith({
    int? totalListed,
    List<_icav4sge.FacetCount>? byMarket,
    List<_icav4sge.FacetCount>? bySection,
    Object? lastJob = _Undefined,
  }) {
    return Overview(
      totalListed: totalListed ?? this.totalListed,
      byMarket: byMarket ?? this.byMarket.map((e0) => e0.copyWith()).toList(),
      bySection:
          bySection ?? this.bySection.map((e0) => e0.copyWith()).toList(),
      lastJob: lastJob is _iwr40u3f.IngestJob?
          ? lastJob
          : this.lastJob?.copyWith(),
    );
  }
}
