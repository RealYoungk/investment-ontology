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
import '../../ontology/models/index_point.dart' as _ipppabto;

/// 지수 하나의 추이. 화면에서 그리기 좋게 골라 보낸 점들이다 (원천은 공공데이터포털 일별 지수시세).
abstract class IndexHistory
    implements _is.SerializableModel, _is.ProtocolSerialization {
  IndexHistory._({
    required this.series,
    required this.name,
    required this.stride,
    required this.points,
    this.lastChangeRate,
    this.dayBase,
    this.weekBase,
    this.monthBase,
    this.yearBase,
  });

  factory IndexHistory({
    required String series,
    required String name,
    required int stride,
    required List<_ipppabto.IndexPoint> points,
    double? lastChangeRate,
    _ipppabto.IndexPoint? dayBase,
    _ipppabto.IndexPoint? weekBase,
    _ipppabto.IndexPoint? monthBase,
    _ipppabto.IndexPoint? yearBase,
  }) = _IndexHistoryImpl;

  factory IndexHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexHistory(
      series: jsonSerialization['series'] as String,
      name: jsonSerialization['name'] as String,
      stride: jsonSerialization['stride'] as int,
      points: _i4yshtjp.Protocol().deserialize<List<_ipppabto.IndexPoint>>(
        jsonSerialization['points'],
      ),
      lastChangeRate: (jsonSerialization['lastChangeRate'] as num?)?.toDouble(),
      dayBase: jsonSerialization['dayBase'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_ipppabto.IndexPoint>(
              jsonSerialization['dayBase'],
            ),
      weekBase: jsonSerialization['weekBase'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_ipppabto.IndexPoint>(
              jsonSerialization['weekBase'],
            ),
      monthBase: jsonSerialization['monthBase'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_ipppabto.IndexPoint>(
              jsonSerialization['monthBase'],
            ),
      yearBase: jsonSerialization['yearBase'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_ipppabto.IndexPoint>(
              jsonSerialization['yearBase'],
            ),
    );
  }

  String series;

  String name;

  /// 점 사이 간격 (1이면 매 거래일, 5면 다섯 거래일에 하나)
  int stride;

  List<_ipppabto.IndexPoint> points;

  /// 마지막 거래일의 전일 대비 등락률 % (원문 fltRt)
  double? lastChangeRate;

  /// 차트 간격과 무관한 실제 비교 종가. 기준일 이전 10일 이내 자료만 허용.
  _ipppabto.IndexPoint? dayBase;

  _ipppabto.IndexPoint? weekBase;

  _ipppabto.IndexPoint? monthBase;

  _ipppabto.IndexPoint? yearBase;

  /// Returns a shallow copy of this [IndexHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  IndexHistory copyWith({
    String? series,
    String? name,
    int? stride,
    List<_ipppabto.IndexPoint>? points,
    double? lastChangeRate,
    _ipppabto.IndexPoint? dayBase,
    _ipppabto.IndexPoint? weekBase,
    _ipppabto.IndexPoint? monthBase,
    _ipppabto.IndexPoint? yearBase,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexHistory',
      'series': series,
      'name': name,
      'stride': stride,
      'points': points.toJson(valueToJson: (v) => v.toJson()),
      if (lastChangeRate != null) 'lastChangeRate': lastChangeRate,
      if (dayBase != null) 'dayBase': dayBase?.toJson(),
      if (weekBase != null) 'weekBase': weekBase?.toJson(),
      if (monthBase != null) 'monthBase': monthBase?.toJson(),
      if (yearBase != null) 'yearBase': yearBase?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexHistory',
      'series': series,
      'name': name,
      'stride': stride,
      'points': points.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (lastChangeRate != null) 'lastChangeRate': lastChangeRate,
      if (dayBase != null) 'dayBase': dayBase?.toJsonForProtocol(),
      if (weekBase != null) 'weekBase': weekBase?.toJsonForProtocol(),
      if (monthBase != null) 'monthBase': monthBase?.toJsonForProtocol(),
      if (yearBase != null) 'yearBase': yearBase?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexHistoryImpl extends IndexHistory {
  _IndexHistoryImpl({
    required String series,
    required String name,
    required int stride,
    required List<_ipppabto.IndexPoint> points,
    double? lastChangeRate,
    _ipppabto.IndexPoint? dayBase,
    _ipppabto.IndexPoint? weekBase,
    _ipppabto.IndexPoint? monthBase,
    _ipppabto.IndexPoint? yearBase,
  }) : super._(
         series: series,
         name: name,
         stride: stride,
         points: points,
         lastChangeRate: lastChangeRate,
         dayBase: dayBase,
         weekBase: weekBase,
         monthBase: monthBase,
         yearBase: yearBase,
       );

  /// Returns a shallow copy of this [IndexHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  IndexHistory copyWith({
    String? series,
    String? name,
    int? stride,
    List<_ipppabto.IndexPoint>? points,
    Object? lastChangeRate = _Undefined,
    Object? dayBase = _Undefined,
    Object? weekBase = _Undefined,
    Object? monthBase = _Undefined,
    Object? yearBase = _Undefined,
  }) {
    return IndexHistory(
      series: series ?? this.series,
      name: name ?? this.name,
      stride: stride ?? this.stride,
      points: points ?? this.points.map((e0) => e0.copyWith()).toList(),
      lastChangeRate: lastChangeRate is double?
          ? lastChangeRate
          : this.lastChangeRate,
      dayBase: dayBase is _ipppabto.IndexPoint?
          ? dayBase
          : this.dayBase?.copyWith(),
      weekBase: weekBase is _ipppabto.IndexPoint?
          ? weekBase
          : this.weekBase?.copyWith(),
      monthBase: monthBase is _ipppabto.IndexPoint?
          ? monthBase
          : this.monthBase?.copyWith(),
      yearBase: yearBase is _ipppabto.IndexPoint?
          ? yearBase
          : this.yearBase?.copyWith(),
    );
  }
}
