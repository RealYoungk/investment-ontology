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

import '../../ontology/models/price_point.dart' as _i4m22bwn;

/// 한 종목의 종가 추이. 화면에서 그리기 좋게 골라 보낸 점들이다 (원천은 공공데이터포털 일별 시세).
abstract class PriceHistory
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PriceHistory._({
    required this.securityName,
    required this.shortCode,
    required this.stride,
    required this.points,
    this.high52w,
    this.low52w,
    this.bandPosition,
  });

  factory PriceHistory({
    required String securityName,
    required String shortCode,
    required int stride,
    required List<_i4m22bwn.PricePoint> points,
    int? high52w,
    int? low52w,
    double? bandPosition,
  }) = _PriceHistoryImpl;

  factory PriceHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return PriceHistory(
      securityName: jsonSerialization['securityName'] as String,
      shortCode: jsonSerialization['shortCode'] as String,
      stride: jsonSerialization['stride'] as int,
      points: _i4yshtjp.Protocol().deserialize<List<_i4m22bwn.PricePoint>>(
        jsonSerialization['points'],
      ),
      high52w: jsonSerialization['high52w'] as int?,
      low52w: jsonSerialization['low52w'] as int?,
      bandPosition: (jsonSerialization['bandPosition'] as num?)?.toDouble(),
    );
  }

  /// 대표 종목 (기업에 여러 종목이 있으면 시가총액이 가장 큰 것)
  String securityName;

  String shortCode;

  /// 점 사이 간격 (1이면 매 거래일, 5면 다섯 거래일에 하나)
  int stride;

  List<_i4m22bwn.PricePoint> points;

  /// 최근 1년 종가의 최고·최저와 지금 종가의 자리 (0 = 최저, 100 = 최고).
  /// 그사이 상장주식수가 크게 바뀌었으면(액면분할·병합) 비운다 — 종가를 이어 붙일 수 없다.
  int? high52w;

  int? low52w;

  double? bandPosition;

  /// Returns a shallow copy of this [PriceHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PriceHistory copyWith({
    String? securityName,
    String? shortCode,
    int? stride,
    List<_i4m22bwn.PricePoint>? points,
    int? high52w,
    int? low52w,
    double? bandPosition,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PriceHistory',
      'securityName': securityName,
      'shortCode': shortCode,
      'stride': stride,
      'points': points.toJson(valueToJson: (v) => v.toJson()),
      if (high52w != null) 'high52w': high52w,
      if (low52w != null) 'low52w': low52w,
      if (bandPosition != null) 'bandPosition': bandPosition,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PriceHistory',
      'securityName': securityName,
      'shortCode': shortCode,
      'stride': stride,
      'points': points.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (high52w != null) 'high52w': high52w,
      if (low52w != null) 'low52w': low52w,
      if (bandPosition != null) 'bandPosition': bandPosition,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PriceHistoryImpl extends PriceHistory {
  _PriceHistoryImpl({
    required String securityName,
    required String shortCode,
    required int stride,
    required List<_i4m22bwn.PricePoint> points,
    int? high52w,
    int? low52w,
    double? bandPosition,
  }) : super._(
         securityName: securityName,
         shortCode: shortCode,
         stride: stride,
         points: points,
         high52w: high52w,
         low52w: low52w,
         bandPosition: bandPosition,
       );

  /// Returns a shallow copy of this [PriceHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PriceHistory copyWith({
    String? securityName,
    String? shortCode,
    int? stride,
    List<_i4m22bwn.PricePoint>? points,
    Object? high52w = _Undefined,
    Object? low52w = _Undefined,
    Object? bandPosition = _Undefined,
  }) {
    return PriceHistory(
      securityName: securityName ?? this.securityName,
      shortCode: shortCode ?? this.shortCode,
      stride: stride ?? this.stride,
      points: points ?? this.points.map((e0) => e0.copyWith()).toList(),
      high52w: high52w is int? ? high52w : this.high52w,
      low52w: low52w is int? ? low52w : this.low52w,
      bandPosition: bandPosition is double? ? bandPosition : this.bandPosition,
    );
  }
}
