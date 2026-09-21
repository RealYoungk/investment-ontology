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

import '../../ontology/models/graph_edge.dart' as _iknezajl;
import '../../ontology/models/graph_node.dart' as _i1tb8zsr;

/// 기업 중심 관계망 (각 기업의 최근 사업보고서 기준 관계 색인 + 승인된 AI 관계).
abstract class CompanyGraph
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyGraph._({
    required this.centerKey,
    required this.nodes,
    required this.edges,
    required this.truncated,
  });

  factory CompanyGraph({
    required String centerKey,
    required List<_i1tb8zsr.GraphNode> nodes,
    required List<_iknezajl.GraphEdge> edges,
    required bool truncated,
  }) = _CompanyGraphImpl;

  factory CompanyGraph.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyGraph(
      centerKey: jsonSerialization['centerKey'] as String,
      nodes: _i4yshtjp.Protocol().deserialize<List<_i1tb8zsr.GraphNode>>(
        jsonSerialization['nodes'],
      ),
      edges: _i4yshtjp.Protocol().deserialize<List<_iknezajl.GraphEdge>>(
        jsonSerialization['edges'],
      ),
      truncated: _is.BoolJsonExtension.fromJson(jsonSerialization['truncated']),
    );
  }

  String centerKey;

  List<_i1tb8zsr.GraphNode> nodes;

  List<_iknezajl.GraphEdge> edges;

  /// 노드 수 제한으로 잘렸는지
  bool truncated;

  /// Returns a shallow copy of this [CompanyGraph]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyGraph copyWith({
    String? centerKey,
    List<_i1tb8zsr.GraphNode>? nodes,
    List<_iknezajl.GraphEdge>? edges,
    bool? truncated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyGraph',
      'centerKey': centerKey,
      'nodes': nodes.toJson(valueToJson: (v) => v.toJson()),
      'edges': edges.toJson(valueToJson: (v) => v.toJson()),
      'truncated': truncated,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyGraph',
      'centerKey': centerKey,
      'nodes': nodes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'edges': edges.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'truncated': truncated,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _CompanyGraphImpl extends CompanyGraph {
  _CompanyGraphImpl({
    required String centerKey,
    required List<_i1tb8zsr.GraphNode> nodes,
    required List<_iknezajl.GraphEdge> edges,
    required bool truncated,
  }) : super._(
         centerKey: centerKey,
         nodes: nodes,
         edges: edges,
         truncated: truncated,
       );

  /// Returns a shallow copy of this [CompanyGraph]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyGraph copyWith({
    String? centerKey,
    List<_i1tb8zsr.GraphNode>? nodes,
    List<_iknezajl.GraphEdge>? edges,
    bool? truncated,
  }) {
    return CompanyGraph(
      centerKey: centerKey ?? this.centerKey,
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      truncated: truncated ?? this.truncated,
    );
  }
}
