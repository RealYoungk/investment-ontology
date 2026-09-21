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

/// 다른 회사 보고서에서 역으로 찾은 관계 (이 기업에 출자한 기업, 이 기업이 주주인 기업).
abstract class GovernanceLink
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GovernanceLink._({
    required this.predicate,
    this.companyId,
    this.corpCode,
    required this.name,
    this.weight,
    required this.bsnsYear,
    required this.relationId,
  });

  factory GovernanceLink({
    required _iqv2n0qs.RelationPredicate predicate,
    int? companyId,
    String? corpCode,
    required String name,
    double? weight,
    required int bsnsYear,
    required int relationId,
  }) = _GovernanceLinkImpl;

  factory GovernanceLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return GovernanceLink(
      predicate: _iqv2n0qs.RelationPredicate.fromJson(
        (jsonSerialization['predicate'] as String),
      ),
      companyId: jsonSerialization['companyId'] as int?,
      corpCode: jsonSerialization['corpCode'] as String?,
      name: jsonSerialization['name'] as String,
      weight: (jsonSerialization['weight'] as num?)?.toDouble(),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      relationId: jsonSerialization['relationId'] as int,
    );
  }

  _iqv2n0qs.RelationPredicate predicate;

  int? companyId;

  String? corpCode;

  /// 상대 기업 이름
  String name;

  /// 지분율 (%)
  double? weight;

  int bsnsYear;

  int relationId;

  /// Returns a shallow copy of this [GovernanceLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GovernanceLink copyWith({
    _iqv2n0qs.RelationPredicate? predicate,
    int? companyId,
    String? corpCode,
    String? name,
    double? weight,
    int? bsnsYear,
    int? relationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GovernanceLink',
      'predicate': predicate.toJson(),
      if (companyId != null) 'companyId': companyId,
      if (corpCode != null) 'corpCode': corpCode,
      'name': name,
      if (weight != null) 'weight': weight,
      'bsnsYear': bsnsYear,
      'relationId': relationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GovernanceLink',
      'predicate': predicate.toJson(),
      if (companyId != null) 'companyId': companyId,
      if (corpCode != null) 'corpCode': corpCode,
      'name': name,
      if (weight != null) 'weight': weight,
      'bsnsYear': bsnsYear,
      'relationId': relationId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GovernanceLinkImpl extends GovernanceLink {
  _GovernanceLinkImpl({
    required _iqv2n0qs.RelationPredicate predicate,
    int? companyId,
    String? corpCode,
    required String name,
    double? weight,
    required int bsnsYear,
    required int relationId,
  }) : super._(
         predicate: predicate,
         companyId: companyId,
         corpCode: corpCode,
         name: name,
         weight: weight,
         bsnsYear: bsnsYear,
         relationId: relationId,
       );

  /// Returns a shallow copy of this [GovernanceLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GovernanceLink copyWith({
    _iqv2n0qs.RelationPredicate? predicate,
    Object? companyId = _Undefined,
    Object? corpCode = _Undefined,
    String? name,
    Object? weight = _Undefined,
    int? bsnsYear,
    int? relationId,
  }) {
    return GovernanceLink(
      predicate: predicate ?? this.predicate,
      companyId: companyId is int? ? companyId : this.companyId,
      corpCode: corpCode is String? ? corpCode : this.corpCode,
      name: name ?? this.name,
      weight: weight is double? ? weight : this.weight,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      relationId: relationId ?? this.relationId,
    );
  }
}
