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
import '../../ontology/models/relation_predicate.dart' as _iqv2n0qs;

/// 관계망 간선 (방향: from → to).
abstract class GraphEdge
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  GraphEdge._({
    required this.from,
    required this.to,
    required this.predicate,
    this.weight,
    required this.estimated,
    required this.ai,
  });

  factory GraphEdge({
    required String from,
    required String to,
    required _iqv2n0qs.RelationPredicate predicate,
    double? weight,
    required bool estimated,
    required bool ai,
  }) = _GraphEdgeImpl;

  factory GraphEdge.fromJson(Map<String, dynamic> jsonSerialization) {
    return GraphEdge(
      from: jsonSerialization['from'] as String,
      to: jsonSerialization['to'] as String,
      predicate: _iqv2n0qs.RelationPredicate.fromJson(
        (jsonSerialization['predicate'] as String),
      ),
      weight: (jsonSerialization['weight'] as num?)?.toDouble(),
      estimated: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['estimated'],
      ),
      ai: _isc.BoolJsonExtension.fromJson(jsonSerialization['ai']),
    );
  }

  String from;

  String to;

  _iqv2n0qs.RelationPredicate predicate;

  double? weight;

  /// 추정 연결(draft)
  bool estimated;

  /// AI가 뽑고 사람이 승인한 관계
  bool ai;

  /// Returns a shallow copy of this [GraphEdge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  GraphEdge copyWith({
    String? from,
    String? to,
    _iqv2n0qs.RelationPredicate? predicate,
    double? weight,
    bool? estimated,
    bool? ai,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GraphEdge',
      'from': from,
      'to': to,
      'predicate': predicate.toJson(),
      if (weight != null) 'weight': weight,
      'estimated': estimated,
      'ai': ai,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GraphEdge',
      'from': from,
      'to': to,
      'predicate': predicate.toJson(),
      if (weight != null) 'weight': weight,
      'estimated': estimated,
      'ai': ai,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GraphEdgeImpl extends GraphEdge {
  _GraphEdgeImpl({
    required String from,
    required String to,
    required _iqv2n0qs.RelationPredicate predicate,
    double? weight,
    required bool estimated,
    required bool ai,
  }) : super._(
         from: from,
         to: to,
         predicate: predicate,
         weight: weight,
         estimated: estimated,
         ai: ai,
       );

  /// Returns a shallow copy of this [GraphEdge]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  GraphEdge copyWith({
    String? from,
    String? to,
    _iqv2n0qs.RelationPredicate? predicate,
    Object? weight = _Undefined,
    bool? estimated,
    bool? ai,
  }) {
    return GraphEdge(
      from: from ?? this.from,
      to: to ?? this.to,
      predicate: predicate ?? this.predicate,
      weight: weight is double? ? weight : this.weight,
      estimated: estimated ?? this.estimated,
      ai: ai ?? this.ai,
    );
  }
}
