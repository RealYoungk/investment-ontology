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

/// 시장 전체 시가총액의 하루 값 (그 기준일에 시세가 있는 종목의 합).
abstract class MarketCapPoint
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MarketCapPoint._({
    required this.date,
    required this.marketCap,
    required this.securityCount,
  });

  factory MarketCapPoint({
    required DateTime date,
    required BigInt marketCap,
    required int securityCount,
  }) = _MarketCapPointImpl;

  factory MarketCapPoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketCapPoint(
      date: _is.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      marketCap: _is.BigIntJsonExtension.fromJson(
        jsonSerialization['marketCap'],
      ),
      securityCount: jsonSerialization['securityCount'] as int,
    );
  }

  DateTime date;

  BigInt marketCap;

  /// 합에 들어간 종목 수
  int securityCount;

  /// Returns a shallow copy of this [MarketCapPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketCapPoint copyWith({
    DateTime? date,
    BigInt? marketCap,
    int? securityCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketCapPoint',
      'date': date.toJson(),
      'marketCap': marketCap.toJson(),
      'securityCount': securityCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketCapPoint',
      'date': date.toJson(),
      'marketCap': marketCap.toJson(),
      'securityCount': securityCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _MarketCapPointImpl extends MarketCapPoint {
  _MarketCapPointImpl({
    required DateTime date,
    required BigInt marketCap,
    required int securityCount,
  }) : super._(
         date: date,
         marketCap: marketCap,
         securityCount: securityCount,
       );

  /// Returns a shallow copy of this [MarketCapPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketCapPoint copyWith({
    DateTime? date,
    BigInt? marketCap,
    int? securityCount,
  }) {
    return MarketCapPoint(
      date: date ?? this.date,
      marketCap: marketCap ?? this.marketCap,
      securityCount: securityCount ?? this.securityCount,
    );
  }
}
