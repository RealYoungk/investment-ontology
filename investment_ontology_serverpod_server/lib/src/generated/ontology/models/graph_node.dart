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

/// 관계망 노드: 기업 · 인물 · 이름뿐인 대상.
abstract class GraphNode
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GraphNode._({
    required this.key,
    required this.kind,
    required this.label,
    this.corpCode,
    this.personId,
    required this.depth,
    this.marketCap,
  });

  factory GraphNode({
    required String key,
    required String kind,
    required String label,
    String? corpCode,
    int? personId,
    required int depth,
    BigInt? marketCap,
  }) = _GraphNodeImpl;

  factory GraphNode.fromJson(Map<String, dynamic> jsonSerialization) {
    return GraphNode(
      key: jsonSerialization['key'] as String,
      kind: jsonSerialization['kind'] as String,
      label: jsonSerialization['label'] as String,
      corpCode: jsonSerialization['corpCode'] as String?,
      personId: jsonSerialization['personId'] as int?,
      depth: jsonSerialization['depth'] as int,
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
    );
  }

  /// c<기업 id> · p<인물 id> · n<이름>
  String key;

  /// company · person · name
  String kind;

  String label;

  String? corpCode;

  int? personId;

  /// 중심에서 몇 단계
  int depth;

  BigInt? marketCap;

  /// Returns a shallow copy of this [GraphNode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GraphNode copyWith({
    String? key,
    String? kind,
    String? label,
    String? corpCode,
    int? personId,
    int? depth,
    BigInt? marketCap,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GraphNode',
      'key': key,
      'kind': kind,
      'label': label,
      if (corpCode != null) 'corpCode': corpCode,
      if (personId != null) 'personId': personId,
      'depth': depth,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GraphNode',
      'key': key,
      'kind': kind,
      'label': label,
      if (corpCode != null) 'corpCode': corpCode,
      if (personId != null) 'personId': personId,
      'depth': depth,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GraphNodeImpl extends GraphNode {
  _GraphNodeImpl({
    required String key,
    required String kind,
    required String label,
    String? corpCode,
    int? personId,
    required int depth,
    BigInt? marketCap,
  }) : super._(
         key: key,
         kind: kind,
         label: label,
         corpCode: corpCode,
         personId: personId,
         depth: depth,
         marketCap: marketCap,
       );

  /// Returns a shallow copy of this [GraphNode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GraphNode copyWith({
    String? key,
    String? kind,
    String? label,
    Object? corpCode = _Undefined,
    Object? personId = _Undefined,
    int? depth,
    Object? marketCap = _Undefined,
  }) {
    return GraphNode(
      key: key ?? this.key,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      corpCode: corpCode is String? ? corpCode : this.corpCode,
      personId: personId is int? ? personId : this.personId,
      depth: depth ?? this.depth,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
    );
  }
}
