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
import '../../ontology/models/disclosure_link_basis.dart' as _i0btqt1b;
import '../../ontology/models/executive_registration.dart' as _i5x1kqvd;
import '../../ontology/models/relation_predicate.dart' as _iqv2n0qs;

/// 인물이 기업과 맺은 관계 하나.
abstract class PersonRole
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PersonRole._({
    required this.predicate,
    required this.companyId,
    required this.corpCode,
    required this.companyName,
    required this.bsnsYear,
    this.weight,
    this.position,
    this.registration,
    this.detail,
    this.basis,
    required this.estimated,
  });

  factory PersonRole({
    required _iqv2n0qs.RelationPredicate predicate,
    required int companyId,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    double? weight,
    String? position,
    _i5x1kqvd.ExecutiveRegistration? registration,
    String? detail,
    _i0btqt1b.DisclosureLinkBasis? basis,
    required bool estimated,
  }) = _PersonRoleImpl;

  factory PersonRole.fromJson(Map<String, dynamic> jsonSerialization) {
    return PersonRole(
      predicate: _iqv2n0qs.RelationPredicate.fromJson(
        (jsonSerialization['predicate'] as String),
      ),
      companyId: jsonSerialization['companyId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      weight: (jsonSerialization['weight'] as num?)?.toDouble(),
      position: jsonSerialization['position'] as String?,
      registration: jsonSerialization['registration'] == null
          ? null
          : _i5x1kqvd.ExecutiveRegistration.fromJson(
              (jsonSerialization['registration'] as String),
            ),
      detail: jsonSerialization['detail'] as String?,
      basis: jsonSerialization['basis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['basis'] as String),
            ),
      estimated: _is.BoolJsonExtension.fromJson(jsonSerialization['estimated']),
    );
  }

  _iqv2n0qs.RelationPredicate predicate;

  int companyId;

  String corpCode;

  String companyName;

  int bsnsYear;

  /// 주주면 지분율 (%, 보통주)
  double? weight;

  /// 임원이면 직위 · 등기 구분
  String? position;

  _i5x1kqvd.ExecutiveRegistration? registration;

  /// 원문의 관계 표기 (주주) 또는 담당업무 (임원)
  String? detail;

  _i0btqt1b.DisclosureLinkBasis? basis;

  bool estimated;

  /// Returns a shallow copy of this [PersonRole]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PersonRole copyWith({
    _iqv2n0qs.RelationPredicate? predicate,
    int? companyId,
    String? corpCode,
    String? companyName,
    int? bsnsYear,
    double? weight,
    String? position,
    _i5x1kqvd.ExecutiveRegistration? registration,
    String? detail,
    _i0btqt1b.DisclosureLinkBasis? basis,
    bool? estimated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PersonRole',
      'predicate': predicate.toJson(),
      'companyId': companyId,
      'corpCode': corpCode,
      'companyName': companyName,
      'bsnsYear': bsnsYear,
      if (weight != null) 'weight': weight,
      if (position != null) 'position': position,
      if (registration != null) 'registration': registration?.toJson(),
      if (detail != null) 'detail': detail,
      if (basis != null) 'basis': basis?.toJson(),
      'estimated': estimated,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PersonRole',
      'predicate': predicate.toJson(),
      'companyId': companyId,
      'corpCode': corpCode,
      'companyName': companyName,
      'bsnsYear': bsnsYear,
      if (weight != null) 'weight': weight,
      if (position != null) 'position': position,
      if (registration != null) 'registration': registration?.toJson(),
      if (detail != null) 'detail': detail,
      if (basis != null) 'basis': basis?.toJson(),
      'estimated': estimated,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonRoleImpl extends PersonRole {
  _PersonRoleImpl({
    required _iqv2n0qs.RelationPredicate predicate,
    required int companyId,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    double? weight,
    String? position,
    _i5x1kqvd.ExecutiveRegistration? registration,
    String? detail,
    _i0btqt1b.DisclosureLinkBasis? basis,
    required bool estimated,
  }) : super._(
         predicate: predicate,
         companyId: companyId,
         corpCode: corpCode,
         companyName: companyName,
         bsnsYear: bsnsYear,
         weight: weight,
         position: position,
         registration: registration,
         detail: detail,
         basis: basis,
         estimated: estimated,
       );

  /// Returns a shallow copy of this [PersonRole]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PersonRole copyWith({
    _iqv2n0qs.RelationPredicate? predicate,
    int? companyId,
    String? corpCode,
    String? companyName,
    int? bsnsYear,
    Object? weight = _Undefined,
    Object? position = _Undefined,
    Object? registration = _Undefined,
    Object? detail = _Undefined,
    Object? basis = _Undefined,
    bool? estimated,
  }) {
    return PersonRole(
      predicate: predicate ?? this.predicate,
      companyId: companyId ?? this.companyId,
      corpCode: corpCode ?? this.corpCode,
      companyName: companyName ?? this.companyName,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      weight: weight is double? ? weight : this.weight,
      position: position is String? ? position : this.position,
      registration: registration is _i5x1kqvd.ExecutiveRegistration?
          ? registration
          : this.registration,
      detail: detail is String? ? detail : this.detail,
      basis: basis is _i0btqt1b.DisclosureLinkBasis? ? basis : this.basis,
      estimated: estimated ?? this.estimated,
    );
  }
}
