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
import '../../ontology/models/fs_div.dart' as _igqrlzji;
import '../../ontology/models/peer_metric.dart' as _i4dx7lca;

/// 같은 업종 기업들과의 비교. 업종은 세분류 → 중분류 → 대분류 순으로 넓혀 잡는다.
abstract class PeerComparison
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PeerComparison._({
    required this.code,
    required this.label,
    required this.peerCount,
    required this.metrics,
    this.fsDiv,
  });

  factory PeerComparison({
    required String code,
    required String label,
    required int peerCount,
    required List<_i4dx7lca.PeerMetric> metrics,
    _igqrlzji.FsDiv? fsDiv,
  }) = _PeerComparisonImpl;

  factory PeerComparison.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerComparison(
      code: jsonSerialization['code'] as String,
      label: jsonSerialization['label'] as String,
      peerCount: jsonSerialization['peerCount'] as int,
      metrics: _i4yshtjp.Protocol().deserialize<List<_i4dx7lca.PeerMetric>>(
        jsonSerialization['metrics'],
      ),
      fsDiv: jsonSerialization['fsDiv'] == null
          ? null
          : _igqrlzji.FsDiv.fromJson((jsonSerialization['fsDiv'] as String)),
    );
  }

  /// 비교에 쓴 업종 코드
  String code;

  /// 업종 이름
  String label;

  /// 비교에 쓴 기업 수 (자기 자신 포함)
  int peerCount;

  List<_i4dx7lca.PeerMetric> metrics;

  /// 대상 기업과 비교 집단에 공통으로 적용한 재무 기준
  _igqrlzji.FsDiv? fsDiv;

  /// Returns a shallow copy of this [PeerComparison]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PeerComparison copyWith({
    String? code,
    String? label,
    int? peerCount,
    List<_i4dx7lca.PeerMetric>? metrics,
    _igqrlzji.FsDiv? fsDiv,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerComparison',
      'code': code,
      'label': label,
      'peerCount': peerCount,
      'metrics': metrics.toJson(valueToJson: (v) => v.toJson()),
      if (fsDiv != null) 'fsDiv': fsDiv?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerComparison',
      'code': code,
      'label': label,
      'peerCount': peerCount,
      'metrics': metrics.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (fsDiv != null) 'fsDiv': fsDiv?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PeerComparisonImpl extends PeerComparison {
  _PeerComparisonImpl({
    required String code,
    required String label,
    required int peerCount,
    required List<_i4dx7lca.PeerMetric> metrics,
    _igqrlzji.FsDiv? fsDiv,
  }) : super._(
         code: code,
         label: label,
         peerCount: peerCount,
         metrics: metrics,
         fsDiv: fsDiv,
       );

  /// Returns a shallow copy of this [PeerComparison]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PeerComparison copyWith({
    String? code,
    String? label,
    int? peerCount,
    List<_i4dx7lca.PeerMetric>? metrics,
    Object? fsDiv = _Undefined,
  }) {
    return PeerComparison(
      code: code ?? this.code,
      label: label ?? this.label,
      peerCount: peerCount ?? this.peerCount,
      metrics: metrics ?? this.metrics.map((e0) => e0.copyWith()).toList(),
      fsDiv: fsDiv is _igqrlzji.FsDiv? ? fsDiv : this.fsDiv,
    );
  }
}
