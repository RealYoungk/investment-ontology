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

/// 회사 제품과 설명을 연결하는 근거. 설명 사전과 회사 귀속 근거를 구분한다.
abstract class BusinessProduct
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessProduct._({
    required this.key,
    required this.name,
    required this.role,
    required this.process,
    required this.benefit,
    required this.evidence,
    this.referenceUrl,
    required this.explanationKind,
  });

  factory BusinessProduct({
    required String key,
    required String name,
    required String role,
    required String process,
    required String benefit,
    required String evidence,
    String? referenceUrl,
    required String explanationKind,
  }) = _BusinessProductImpl;

  factory BusinessProduct.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessProduct(
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] as String,
      process: jsonSerialization['process'] as String,
      benefit: jsonSerialization['benefit'] as String,
      evidence: jsonSerialization['evidence'] as String,
      referenceUrl: jsonSerialization['referenceUrl'] as String?,
      explanationKind: jsonSerialization['explanationKind'] as String,
    );
  }

  String key;

  String name;

  String role;

  String process;

  String benefit;

  String evidence;

  String? referenceUrl;

  /// 설명 사전은 일반적인 제품 원리이며 회사별 성능 보증이 아니다.
  String explanationKind;

  /// Returns a shallow copy of this [BusinessProduct]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessProduct copyWith({
    String? key,
    String? name,
    String? role,
    String? process,
    String? benefit,
    String? evidence,
    String? referenceUrl,
    String? explanationKind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessProduct',
      'key': key,
      'name': name,
      'role': role,
      'process': process,
      'benefit': benefit,
      'evidence': evidence,
      if (referenceUrl != null) 'referenceUrl': referenceUrl,
      'explanationKind': explanationKind,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessProduct',
      'key': key,
      'name': name,
      'role': role,
      'process': process,
      'benefit': benefit,
      'evidence': evidence,
      if (referenceUrl != null) 'referenceUrl': referenceUrl,
      'explanationKind': explanationKind,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessProductImpl extends BusinessProduct {
  _BusinessProductImpl({
    required String key,
    required String name,
    required String role,
    required String process,
    required String benefit,
    required String evidence,
    String? referenceUrl,
    required String explanationKind,
  }) : super._(
         key: key,
         name: name,
         role: role,
         process: process,
         benefit: benefit,
         evidence: evidence,
         referenceUrl: referenceUrl,
         explanationKind: explanationKind,
       );

  /// Returns a shallow copy of this [BusinessProduct]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessProduct copyWith({
    String? key,
    String? name,
    String? role,
    String? process,
    String? benefit,
    String? evidence,
    Object? referenceUrl = _Undefined,
    String? explanationKind,
  }) {
    return BusinessProduct(
      key: key ?? this.key,
      name: name ?? this.name,
      role: role ?? this.role,
      process: process ?? this.process,
      benefit: benefit ?? this.benefit,
      evidence: evidence ?? this.evidence,
      referenceUrl: referenceUrl is String? ? referenceUrl : this.referenceUrl,
      explanationKind: explanationKind ?? this.explanationKind,
    );
  }
}
