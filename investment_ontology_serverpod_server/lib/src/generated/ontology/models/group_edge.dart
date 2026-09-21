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
import 'package:serverpod/serverpod.dart' as _is;

import '../../ontology/models/relation_predicate.dart' as _iqv2n0qs;

/// 기업 묶음 안의 지분 연결: from이 to의 주식을 가진다.
abstract class GroupEdge
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GroupEdge._({
    required this.fromCompanyId,
    required this.toCompanyId,
    required this.predicate,
    this.ratio,
    required this.bsnsYear,
  });

  factory GroupEdge({
    required int fromCompanyId,
    required int toCompanyId,
    required _iqv2n0qs.RelationPredicate predicate,
    double? ratio,
    required int bsnsYear,
  }) = _GroupEdgeImpl;

  factory GroupEdge.fromJson(Map<String, dynamic> jsonSerialization) {
    return GroupEdge(
      fromCompanyId: jsonSerialization['fromCompanyId'] as int,
      toCompanyId: jsonSerialization['toCompanyId'] as int,
      predicate: _iqv2n0qs.RelationPredicate.fromJson(
        (jsonSerialization['predicate'] as String),
      ),
      ratio: (jsonSerialization['ratio'] as num?)?.toDouble(),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
    );
  }

  int fromCompanyId;

  int toCompanyId;

  /// shareholderOf (to의 최대주주 명단에 from) 또는 investsIn (from의 경영참여 출자)
  _iqv2n0qs.RelationPredicate predicate;

  /// 기말 지분율 (%)
  double? ratio;

  int bsnsYear;

  /// Returns a shallow copy of this [GroupEdge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GroupEdge copyWith({
    int? fromCompanyId,
    int? toCompanyId,
    _iqv2n0qs.RelationPredicate? predicate,
    double? ratio,
    int? bsnsYear,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupEdge',
      'fromCompanyId': fromCompanyId,
      'toCompanyId': toCompanyId,
      'predicate': predicate.toJson(),
      if (ratio != null) 'ratio': ratio,
      'bsnsYear': bsnsYear,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GroupEdge',
      'fromCompanyId': fromCompanyId,
      'toCompanyId': toCompanyId,
      'predicate': predicate.toJson(),
      if (ratio != null) 'ratio': ratio,
      'bsnsYear': bsnsYear,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupEdgeImpl extends GroupEdge {
  _GroupEdgeImpl({
    required int fromCompanyId,
    required int toCompanyId,
    required _iqv2n0qs.RelationPredicate predicate,
    double? ratio,
    required int bsnsYear,
  }) : super._(
         fromCompanyId: fromCompanyId,
         toCompanyId: toCompanyId,
         predicate: predicate,
         ratio: ratio,
         bsnsYear: bsnsYear,
       );

  /// Returns a shallow copy of this [GroupEdge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GroupEdge copyWith({
    int? fromCompanyId,
    int? toCompanyId,
    _iqv2n0qs.RelationPredicate? predicate,
    Object? ratio = _Undefined,
    int? bsnsYear,
  }) {
    return GroupEdge(
      fromCompanyId: fromCompanyId ?? this.fromCompanyId,
      toCompanyId: toCompanyId ?? this.toCompanyId,
      predicate: predicate ?? this.predicate,
      ratio: ratio is double? ? ratio : this.ratio,
      bsnsYear: bsnsYear ?? this.bsnsYear,
    );
  }
}
