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

/// 종가 추이의 한 점.
abstract class PricePoint
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PricePoint._({
    required this.date,
    required this.close,
  });

  factory PricePoint({
    required DateTime date,
    required int close,
  }) = _PricePointImpl;

  factory PricePoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return PricePoint(
      date: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      close: jsonSerialization['close'] as int,
    );
  }

  DateTime date;

  /// 종가 (원)
  int close;

  /// Returns a shallow copy of this [PricePoint]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PricePoint copyWith({
    DateTime? date,
    int? close,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PricePoint',
      'date': date.toJson(),
      'close': close,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PricePoint',
      'date': date.toJson(),
      'close': close,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PricePointImpl extends PricePoint {
  _PricePointImpl({
    required DateTime date,
    required int close,
  }) : super._(
         date: date,
         close: close,
       );

  /// Returns a shallow copy of this [PricePoint]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PricePoint copyWith({
    DateTime? date,
    int? close,
  }) {
    return PricePoint(
      date: date ?? this.date,
      close: close ?? this.close,
    );
  }
}
