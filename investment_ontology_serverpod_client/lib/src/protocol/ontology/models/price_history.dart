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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/price_point.dart' as _i4m22bwn;

/// 한 종목의 종가 추이. 화면에서 그리기 좋게 골라 보낸 점들이다 (원천은 공공데이터포털 일별 시세).
abstract class PriceHistory
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PriceHistory._({
    required this.securityName,
    required this.shortCode,
    required this.stride,
    required this.points,
  });

  factory PriceHistory({
    required String securityName,
    required String shortCode,
    required int stride,
    required List<_i4m22bwn.PricePoint> points,
  }) = _PriceHistoryImpl;

  factory PriceHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return PriceHistory(
      securityName: jsonSerialization['securityName'] as String,
      shortCode: jsonSerialization['shortCode'] as String,
      stride: jsonSerialization['stride'] as int,
      points: _ilkzeueu.Protocol().deserialize<List<_i4m22bwn.PricePoint>>(
        jsonSerialization['points'],
      ),
    );
  }

  /// 대표 종목 (기업에 여러 종목이 있으면 시가총액이 가장 큰 것)
  String securityName;

  String shortCode;

  /// 점 사이 간격 (1이면 매 거래일, 5면 다섯 거래일에 하나)
  int stride;

  List<_i4m22bwn.PricePoint> points;

  /// Returns a shallow copy of this [PriceHistory]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PriceHistory copyWith({
    String? securityName,
    String? shortCode,
    int? stride,
    List<_i4m22bwn.PricePoint>? points,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PriceHistory',
      'securityName': securityName,
      'shortCode': shortCode,
      'stride': stride,
      'points': points.toJson(valueToJson: (v) => v.toJson()),
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
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PriceHistoryImpl extends PriceHistory {
  _PriceHistoryImpl({
    required String securityName,
    required String shortCode,
    required int stride,
    required List<_i4m22bwn.PricePoint> points,
  }) : super._(
         securityName: securityName,
         shortCode: shortCode,
         stride: stride,
         points: points,
       );

  /// Returns a shallow copy of this [PriceHistory]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PriceHistory copyWith({
    String? securityName,
    String? shortCode,
    int? stride,
    List<_i4m22bwn.PricePoint>? points,
  }) {
    return PriceHistory(
      securityName: securityName ?? this.securityName,
      shortCode: shortCode ?? this.shortCode,
      stride: stride ?? this.stride,
      points: points ?? this.points.map((e0) => e0.copyWith()).toList(),
    );
  }
}
