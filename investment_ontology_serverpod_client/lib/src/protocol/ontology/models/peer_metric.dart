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

/// 업종 비교의 지표 하나. 값은 저장하지 않고 조회할 때 계산한다.
abstract class PeerMetric
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PeerMetric._({
    required this.key,
    required this.label,
    this.value,
    this.median,
    this.rank,
    this.ranked,
    required this.lowerIsBetter,
  });

  factory PeerMetric({
    required String key,
    required String label,
    double? value,
    double? median,
    int? rank,
    int? ranked,
    required bool lowerIsBetter,
  }) = _PeerMetricImpl;

  factory PeerMetric.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerMetric(
      key: jsonSerialization['key'] as String,
      label: jsonSerialization['label'] as String,
      value: (jsonSerialization['value'] as num?)?.toDouble(),
      median: (jsonSerialization['median'] as num?)?.toDouble(),
      rank: jsonSerialization['rank'] as int?,
      ranked: jsonSerialization['ranked'] as int?,
      lowerIsBetter: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['lowerIsBetter'],
      ),
    );
  }

  String key;

  String label;

  /// 이 기업의 값
  double? value;

  /// 같은 업종 기업들의 중앙값
  double? median;

  /// 같은 업종에서 몇 번째인지 (1 = 가장 좋음). 값이 없으면 null
  int? rank;

  /// 값이 있는 같은 업종 기업 수
  int? ranked;

  /// 낮을수록 좋은 지표인지 (PER·PBR·부채비율)
  bool lowerIsBetter;

  /// Returns a shallow copy of this [PeerMetric]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PeerMetric copyWith({
    String? key,
    String? label,
    double? value,
    double? median,
    int? rank,
    int? ranked,
    bool? lowerIsBetter,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerMetric',
      'key': key,
      'label': label,
      if (value != null) 'value': value,
      if (median != null) 'median': median,
      if (rank != null) 'rank': rank,
      if (ranked != null) 'ranked': ranked,
      'lowerIsBetter': lowerIsBetter,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerMetric',
      'key': key,
      'label': label,
      if (value != null) 'value': value,
      if (median != null) 'median': median,
      if (rank != null) 'rank': rank,
      if (ranked != null) 'ranked': ranked,
      'lowerIsBetter': lowerIsBetter,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PeerMetricImpl extends PeerMetric {
  _PeerMetricImpl({
    required String key,
    required String label,
    double? value,
    double? median,
    int? rank,
    int? ranked,
    required bool lowerIsBetter,
  }) : super._(
         key: key,
         label: label,
         value: value,
         median: median,
         rank: rank,
         ranked: ranked,
         lowerIsBetter: lowerIsBetter,
       );

  /// Returns a shallow copy of this [PeerMetric]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PeerMetric copyWith({
    String? key,
    String? label,
    Object? value = _Undefined,
    Object? median = _Undefined,
    Object? rank = _Undefined,
    Object? ranked = _Undefined,
    bool? lowerIsBetter,
  }) {
    return PeerMetric(
      key: key ?? this.key,
      label: label ?? this.label,
      value: value is double? ? value : this.value,
      median: median is double? ? median : this.median,
      rank: rank is int? ? rank : this.rank,
      ranked: ranked is int? ? ranked : this.ranked,
      lowerIsBetter: lowerIsBetter ?? this.lowerIsBetter,
    );
  }
}
